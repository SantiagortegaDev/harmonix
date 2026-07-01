import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/album.dart';
import 'package:harmonix/data/models/artist.dart';
import 'package:harmonix/data/models/playlist.dart';
import 'package:harmonix/data/models/song.dart';

/// Resultado de búsqueda con filtros Piped.
class PipedSearchResult {
  PipedSearchResult({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.nextPage = '',
  });

  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final String nextPage;
}

/// Filtros disponibles en Piped /search.
enum PipedSearchFilter { all, musicSongs, musicVideos, musicAlbums, musicPlaylists, musicArtists }

extension PipedSearchFilterX on PipedSearchFilter {
  String get value {
    switch (this) {
      case PipedSearchFilter.all:
        return 'all';
      case PipedSearchFilter.musicSongs:
        return 'music_songs';
      case PipedSearchFilter.musicVideos:
        return 'music_videos';
      case PipedSearchFilter.musicAlbums:
        return 'music_albums';
      case PipedSearchFilter.musicPlaylists:
        return 'music_playlists';
      case PipedSearchFilter.musicArtists:
        return 'music_artists';
    }
  }
}

/// Cliente para la API pública de Piped.
///
/// Documentación: https://docs.piped.video/
/// Endpoints usados:
///   - GET /search?q=<query>&filter=<filter>
///   - GET /streams/{videoId}
///   - GET /playlists/{playlistId}
///   - GET /channel/{channelId}
///   - GET /trending
///   - GET /suggestions
class PipedApiService {
  PipedApiService({String? instanceUrl})
      : _instanceUrl = (instanceUrl ?? AppConstants.defaultPipedInstance)
            .replaceAll(RegExp(r'/+$'), ''),
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Accept': 'application/json'},
          ),
        );

  final String _instanceUrl;
  final Dio _dio;

  String get instanceUrl => _instanceUrl;

  /// Permite cambiar de instancia en caliente desde Ajustes.
  PipedApiService copyWithInstance(String newInstance) {
    return PipedApiService(instanceUrl: newInstance);
  }

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    final url = '$_instanceUrl$path';
    HarmonixLogger.instance.debug('GET $url q=$query', tag: 'PipedAPI');
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: query,
      );
      HarmonixLogger.instance.debug('← ${res.statusCode} ${res.data?.length ?? 0}b',
          tag: 'PipedAPI');
      return res.data ?? {};
    } on DioException catch (e, s) {
      HarmonixLogger.instance.error('Piped GET $path failed: ${e.message}',
          tag: 'PipedAPI', error: e, stack: s);
      throw PipedApiException(e.message ?? 'Error de red', e);
    }
  }

  /// Búsqueda combinada (música).
  Future<PipedSearchResult> search(
    String query, {
    PipedSearchFilter filter = PipedSearchFilter.musicSongs,
  }) async {
    if (query.trim().isEmpty) return PipedSearchResult();
    final data = await _get(AppConstants.pathSearch, query: {
      'q': query,
      'filter': filter.value,
    });
    return _parseSearchResults(data, filter);
  }

  /// Resuelve los streams de audio + metadata de un videoId.
  Future<Song> fetchStreams(String videoId) async {
    final data = await _get('${AppConstants.pathStreams}/$videoId');
    return Song.fromPipedStreams(videoId, data);
  }

  /// Tendencias (home "quick picks" fallback).
  Future<List<Song>> trending() async {
    final data = await _get(AppConstants.pathTrending);
    final items = (data['items'] as List?) ?? [];
    return items
        .map((e) => Song.fromPipedSearchItem(e as Map<String, dynamic>))
        .toList();
  }

  /// Detalle de una playlist pública de YouTube Music.
  Future<Playlist> fetchPlaylist(String playlistId) async {
    final data = await _get('${AppConstants.pathPlaylists}/$playlistId');
    final related = (data['relatedStreams'] as List?) ?? [];
    final songs = related
        .map((e) => Song.fromPipedSearchItem(e as Map<String, dynamic>))
        .toList();
    return Playlist(
      id: playlistId,
      name: data['name'] ?? 'Playlist',
      thumbnailUrl: data['thumbnailUrl'],
      uploader: data['uploader'] ?? '',
      videoCount: songs.length,
      songs: songs,
    );
  }

  /// Continuación de búsqueda (paginación).
  Future<PipedSearchResult> searchNextPage(String query, String nextPage,
      {PipedSearchFilter filter = PipedSearchFilter.musicSongs}) async {
    if (nextPage.isEmpty) return PipedSearchResult();
    final data = await _get(AppConstants.pathNext, query: {
      'nextpage': nextPage,
      'q': query,
      'filter': filter.value,
    });
    return _parseSearchResults(data, filter);
  }

  /// Sugerencias para autocompletar.
  Future<List<String>> suggestions(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _get(AppConstants.pathSuggestions, query: {'q': query});
    final list = (data as List?) ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Detalle de canal/artista.
  Future<Artist> fetchChannel(String channelId) async {
    final data = await _get('${AppConstants.pathChannel}/$channelId');
    return Artist(
      id: channelId,
      name: data['name'] ?? '',
      thumbnailUrl: data['avatarUrl'],
      description: data['description'],
      subscribers: data['subscriberCount'] != null
          ? int.tryParse(data['subscriberCount'].toString())
          : null,
      verified: data['verified'] == true,
    );
  }

  PipedSearchResult _parseSearchResults(
      Map<String, dynamic> data, PipedSearchFilter filter) {
    final items = (data['items'] as List?) ?? [];
    final next = data['nextpage']?.toString() ?? '';
    final songs = <Song>[];
    final artists = <Artist>[];
    final albums = <Album>[];
    final playlists = <Playlist>[];

    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      // Piped incluye el campo "type" para distinguir.
      final type = item['type']?.toString() ?? '';
      switch (filter) {
        case PipedSearchFilter.musicSongs:
        case PipedSearchFilter.musicVideos:
          songs.add(Song.fromPipedSearchItem(item));
          break;
        case PipedSearchFilter.musicArtists:
          artists.add(Artist.fromPipedSearchItem(item));
          break;
        case PipedSearchFilter.musicAlbums:
          albums.add(Album.fromPipedSearchItem(item));
          break;
        case PipedSearchFilter.musicPlaylists:
          playlists.add(Playlist.fromPipedSearchItem(item));
          break;
        case PipedSearchFilter.all:
          if (type.contains('stream')) {
            songs.add(Song.fromPipedSearchItem(item));
          } else if (type.contains('channel')) {
            artists.add(Artist.fromPipedSearchItem(item));
          } else if (type.contains('playlist')) {
            playlists.add(Playlist.fromPipedSearchItem(item));
          }
          break;
      }
    }
    return PipedSearchResult(
      songs: songs,
      artists: artists,
      albums: albums,
      playlists: playlists,
      nextPage: next,
    );
  }
}

class PipedApiException implements Exception {
  PipedApiException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => 'PipedApiException: $message';
}
