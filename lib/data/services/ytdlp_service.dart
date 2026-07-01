import 'dart:async';
import 'dart:collection';

import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/album.dart';
import 'package:harmonix/data/models/artist.dart';
import 'package:harmonix/data/models/playlist.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

/// Resultado de búsqueda unificado (reemplaza al antiguo PipedSearchResult).
class YtDlpSearchResult {
  YtDlpSearchResult({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
  });

  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
}

/// Filtros de búsqueda (compatibles con la API pública de YouTube).
enum YtDlpSearchFilter { all, songs, videos, albums, playlists, artists }

/// Servicio de extracción de audio estilo yt-dlp.
///
/// Internamente usa `youtube_explode_dart`, que es un port en Dart puro de la
/// lógica de extracción de YouTube que usa yt-dlp. Esto significa:
///
///   * Sin dependencias nativas → funciona en Android sin bundlear Python.
///   * Sin instancia de terceros → las URLs directas se resuelven en el
///     dispositivo, igual que haría `yt-dlp -f bestaudio --get-url`.
///   * Mucho más estable que Piped (que depende de instancias públicas que
///     caen con frecuencia).
///
/// Para máxima velocidad de arranque de playback:
///   1. `getDirectAudioUrl` devuelve una URL directa de googlevideo.
///   2. Se cachea en memoria por [AppConstants.directUrlTtl] (5 min) →
///      reproducir la misma canción dos veces seguidas es instantáneo.
///   3. `prefetchNext` resuelve la siguiente pista en background mientras
///      suena la actual, para que el skip sea cuasi-inmediato.
class YtDlpService {
  YtDlpService._() : _yt = YoutubeExplode();
  static final YtDlpService instance = YtDlpService._();

  final YoutubeExplode _yt;

  /// Caché LRU en memoria: videoId → (url, expira).
  final LinkedHashMap<String, _CachedUrl> _urlCache =
      LinkedHashMap<String, _CachedUrl>();
  static const int _maxCacheEntries = 64;

  /// Resoluciones en curso (evita disparar 2x la misma petición).
  final Map<String, Future<String>> _inflight = <String, Future<String>>{};

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  /// Búsqueda combinada (música).
  Future<YtDlpSearchResult> search(
    String query, {
    YtDlpSearchFilter filter = YtDlpSearchFilter.songs,
  }) async {
    if (query.trim().isEmpty) return YtDlpSearchResult();
    HarmonixLogger.instance.debug('search "$query" filter=$filter',
        tag: 'YtDlp');
    try {
      final filterArg = _mapFilter(filter);
      final results = await _yt.search.search(
        query,
        filter: filterArg,
      );
      final songs = <Song>[];
      final artists = <Artist>[];
      final albums = <Album>[];
      final playlists = <Playlist>[];
      // `results` es una List<Video> (SearchList). Tomamos hasta 25.
      for (final v in results.take(25)) {
        songs.add(_songFromVideo(v));
      }
      // youtube_explode no separa artistas/álbumes/playlists en la búsqueda
      // estándar; agrupamos artistas a partir de los uploaderName únicos.
      final seenArtists = <String>{};
      for (final s in songs) {
        if (seenArtists.add(s.artist)) {
          artists.add(Artist(
            id: 'yt-channel-${s.artist.hashCode}',
            name: s.artist,
            thumbnailUrl: s.thumbnailUrl,
          ));
        }
      }
      return YtDlpSearchResult(
        songs: songs,
        artists: artists.take(10).toList(),
        albums: albums,
        playlists: playlists,
      );
    } catch (e, s) {
      HarmonixLogger.instance.error('search failed: $e',
          tag: 'YtDlp', error: e, stack: s);
      throw YtDlpException('Error de red: $e', e);
    }
  }

  /// Resuelve la URL directa del mejor stream de audio para [videoId].
  ///
  /// Estrategia:
  ///   1. Caché en memoria → 0ms.
  ///   2. Inflight dedup → si ya hay una petición en curso, espera.
  ///   3. `getManifest()` → selecciona el audio de mayor bitrate que sea
  ///      compatible con ExoPlayer (mp4/m4a).
  ///   4. Cachea por 5 min.
  Future<String> getDirectAudioUrl(String videoId) async {
    if (videoId.isEmpty) {
      throw YtDlpException('videoId vacío', null);
    }

    // 1) Caché
    final cached = _urlCache[videoId];
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      HarmonixLogger.instance.debug('URL cache HIT $videoId', tag: 'YtDlp');
      _urlCache.remove(videoId);
      _urlCache[videoId] = cached; // LRU: re-insert al final
      return cached.url;
    } else if (cached != null) {
      _urlCache.remove(videoId);
    }

    // 2) Inflight dedup
    final inflight = _inflight[videoId];
    if (inflight != null) {
      HarmonixLogger.instance.debug('URL inflight WAIT $videoId',
          tag: 'YtDlp');
      return inflight;
    }

    // 3) Resolver
    final future = _resolveAndCache(videoId);
    _inflight[videoId] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(videoId);
    }
  }

  /// Devuelve la duración y el título desde YouTube, sin resolver streams.
  /// Útil para poblar metadatos antes de reproducir.
  Future<Song> fetchMetadata(String videoId) async {
    final v = await _yt.videos.get(videoId);
    return _songFromVideo(v);
  }

  /// Tendencias (home "quick picks" fallback).
  /// youtube_explode no expone trending oficial; usamos una búsqueda de
  /// "top music 2025" como fallback estable.
  Future<List<Song>> trending() async {
    try {
      final res = await search('top music this week',
          filter: YtDlpSearchFilter.songs);
      return res.songs;
    } catch (_) {
      return const [];
    }
  }

  /// Detalle de una playlist pública de YouTube.
  Future<Playlist> fetchPlaylist(String playlistId) async {
    final pl = await _yt.playlists.get(playlistId);
    final videos = _yt.playlists.getVideos(playlistId);
    final songs = <Song>[];
    await for (final v in videos) {
      songs.add(_songFromVideo(v));
    }
    return Playlist(
      id: pl.id.value,
      name: pl.title,
      thumbnailUrl: pl.thumbnails.highResUrl,
      uploader: pl.author ?? '',
      videoCount: songs.length,
      songs: songs,
    );
  }

  /// Sugerencias para autocompletar.
  Future<List<String>> suggestions(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final sugg = await _yt.search.getQuerySuggestions(query);
      return sugg.take(8).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Detalle de canal/artista.
  Future<Artist> fetchChannel(String channelId) async {
    final ch = await _yt.channels.get(ChannelId(channelId));
    return Artist(
      id: ch.id.value,
      name: ch.title,
      thumbnailUrl: ch.logoUrl,
      description: '',
      subscribers: ch.subscribersCount,
      verified: false,
    );
  }

  /// Precarga la URL directa de la siguiente pista en background.
  /// No lanza excepciones: si falla, simplemente no cachea y la resolución
  /// se hará on-demand cuando el usuario skipee.
  void prefetchNext(String videoId) {
    if (videoId.isEmpty) return;
    final cached = _urlCache[videoId];
    if (cached != null && cached.expires.isAfter(DateTime.now())) return;
    if (_inflight.containsKey(videoId)) return;
    HarmonixLogger.instance.debug('prefetch $videoId', tag: 'YtDlp');
    // Fire and forget.
    _inflight[videoId] = _resolveAndCache(videoId).whenComplete(() {
      _inflight.remove(videoId);
    }).catchError((_) {
      _inflight.remove(videoId);
      return '';
    });
  }

  /// Invalida la caché para una pista (e.g., si la URL expira en playback).
  void invalidate(String videoId) {
    _urlCache.remove(videoId);
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  Future<String> _resolveAndCache(String videoId) async {
    final sw = Stopwatch()..start();
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audio = manifest.audioOnly;
      if (audio.isEmpty) {
        throw YtDlpException('No hay streams de audio para $videoId', null);
      }
      // Preferir m4a/mp4 (compatible ExoPlayer); si no, el de mayor bitrate.
      AudioStreamInfo best;
      final mp4 = audio.where((s) =>
          s.codec.mimeType.toLowerCase().contains('mp4') ||
          s.codec.mimeType.toLowerCase().contains('m4a'));
      final pool = mp4.isNotEmpty ? mp4 : audio;
      best = pool.reduce((a, b) =>
          a.bitrate.compareTo(b.bitrate) >= 0 ? a : b);
      final url = best.url.toString();
      _putCache(videoId, url);
      sw.stop();
      HarmonixLogger.instance.debug(
          'URL resolved $videoId in ${sw.elapsedMilliseconds}ms '
          '(${best.bitrate.kiloBitsPerSecond} kbps ${best.codec.mimeType})',
          tag: 'YtDlp');
      return url;
    } on YtDlpException {
      rethrow;
    } catch (e, s) {
      HarmonixLogger.instance.error('resolve $videoId failed: $e',
          tag: 'YtDlp', error: e, stack: s);
      throw YtDlpException('No se pudo resolver el audio: $e', e);
    }
  }

  void _putCache(String videoId, String url) {
    _urlCache[videoId] = _CachedUrl(
      url: url,
      expires: DateTime.now().add(AppConstants.directUrlTtl),
    );
    while (_urlCache.length > _maxCacheEntries) {
      _urlCache.remove(_urlCache.keys.first);
    }
  }

  SearchFilter? _mapFilter(YtDlpSearchFilter f) {
    switch (f) {
      case YtDlpSearchFilter.songs:
      case YtDlpSearchFilter.videos:
        return SearchFilter.video;
      case YtDlpSearchFilter.albums:
        return SearchFilter.video;
      case YtDlpSearchFilter.playlists:
        return SearchFilter.playlist;
      case YtDlpSearchFilter.artists:
        return SearchFilter.channel;
      case YtDlpSearchFilter.all:
        return null;
    }
  }

  Song _songFromVideo(Video v) {
    final id = v.id.value;
    final author = v.author ?? 'Artista desconocido';
    final artistName = author.replaceAll(' - Topic', '').trim();
    return Song(
      id: id,
      title: v.title,
      artist: artistName.isEmpty ? 'Artista desconocido' : artistName,
      durationMs: v.duration != null ? v.duration!.inMilliseconds : null,
      thumbnailUrl: v.thumbnails.highResUrl,
      videoUrl: 'https://youtu.be/$id',
    );
  }
}

class _CachedUrl {
  _CachedUrl({required this.url, required this.expires});
  final String url;
  final DateTime expires;
}

class YtDlpException implements Exception {
  YtDlpException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => 'YtDlpException: $message';
}
