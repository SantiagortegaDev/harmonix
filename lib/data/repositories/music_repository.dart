import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/services/piped_api_service.dart';
import 'package:hive/hive.dart';
import 'package:harmonix/core/constants/app_constants.dart';

/// Repositorio central de música.
///
/// Combina el servicio Piped con persistencia local (recientes, favoritos,
/// playlists del usuario) para que la UI trabaje contra una sola API.
class MusicRepository {
  MusicRepository._();
  static final MusicRepository instance = MusicRepository._();

  PipedApiService _api = PipedApiService();
  late Box<Song> _songsBox;
  late Box<Song> _favoritesBox;
  late Box<Song> _recentsBox;
  late Box<dynamic> _playlistsBox;

  PipedApiService get api => _api;

  Future<void> init() async {
    _songsBox = await Hive.openBox<Song>(AppConstants.boxSongs);
    _favoritesBox = await Hive.openBox<Song>(AppConstants.boxFavorites);
    _recentsBox = await Hive.openBox<Song>(AppConstants.boxRecents);
    _playlistsBox = await Hive.openBox(AppConstants.boxPlaylists);
    HarmonixLogger.instance.info('MusicRepository init', tag: 'Repository');
  }

  void setPipedInstance(String instanceUrl) {
    _api = PipedApiService(instanceUrl: instanceUrl);
    HarmonixLogger.instance.info('Piped instance: $instanceUrl', tag: 'Repository');
  }

  // --- Búsqueda ---
  Future<PipedSearchResult> search(String q,
          {PipedSearchFilter filter = PipedSearchFilter.musicSongs}) =>
      _api.search(q, filter: filter);

  Future<List<String>> suggestions(String q) => _api.suggestions(q);

  Future<List<Song>> trending() => _api.trending();

  Future<Song> fetchStreams(String videoId) async {
    final song = await _api.fetchStreams(videoId);
    await _songsBox.put(song.id, song);
    return song;
  }

  // --- Recientes ---
  List<Song> get recents => _recentsBox.values.toList()
    ..sort((a, b) =>
        (b.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0)));

  Future<void> markPlayed(Song song) async {
    final updated = song.copyWith(
      lastPlayed: DateTime.now(),
      playCount: song.playCount + 1,
    );
    await _recentsBox.put(updated.id, updated);
    await _songsBox.put(updated.id, updated);
  }

  // --- Favoritos ---
  List<Song> get favorites => _favoritesBox.values.toList();

  Future<void> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);
    if (updated.isFavorite) {
      await _favoritesBox.put(updated.id, updated);
    } else {
      await _favoritesBox.delete(updated.id);
    }
    await _songsBox.put(updated.id, updated);
  }

  bool isFavorite(String id) => _favoritesBox.containsKey(id);

  // --- Playlists del usuario ---
  List<String> get playlistNames =>
      _playlistsBox.keys.map((e) => e.toString()).toList();

  List<Song> getPlaylist(String name) {
    final raw = _playlistsBox.get(name);
    if (raw == null) return [];
    return (raw as List).map((e) => e as Song).toList();
  }

  Future<void> createPlaylist(String name, {List<Song> initial = const []}) async {
    await _playlistsBox.put(name, initial);
  }

  Future<void> addToPlaylist(String name, Song song) async {
    final list = getPlaylist(name);
    list.add(song);
    await _playlistsBox.put(name, list);
  }

  Future<void> removeFromPlaylist(String name, int index) async {
    final list = getPlaylist(name);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _playlistsBox.put(name, list);
  }

  Future<void> deletePlaylist(String name) async {
    await _playlistsBox.delete(name);
  }
}
