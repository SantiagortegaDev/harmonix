import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/services/ytdlp_service.dart';
import 'package:hive/hive.dart';
import 'package:harmonix/core/constants/app_constants.dart';

/// Repositorio central de música.
///
/// Combina el servicio YtDlp (extracción directa de YouTube, equivalente a
/// yt-dlp) con persistencia local (recientes, favoritos, playlists del
/// usuario) para que la UI trabaje contra una sola API.
class MusicRepository {
  MusicRepository._();
  static final MusicRepository instance = MusicRepository._();

  YtDlpService _api = YtDlpService.instance;
  late Box<Song> _songsBox;
  late Box<Song> _favoritesBox;
  late Box<Song> _recentsBox;
  late Box<dynamic> _playlistsBox;

  YtDlpService get api => _api;

  Future<void> init() async {
    _songsBox = await Hive.openBox<Song>(AppConstants.boxSongs);
    _favoritesBox = await Hive.openBox<Song>(AppConstants.boxFavorites);
    _recentsBox = await Hive.openBox<Song>(AppConstants.boxRecents);
    _playlistsBox = await Hive.openBox(AppConstants.boxPlaylists);
    HarmonixLogger.instance.info('MusicRepository init', tag: 'Repository');
  }

  /// Ya no hay instancia externa que configurar: el motor yt-dlp funciona
  /// sin configuración. Se mantiene por compatibilidad con SettingsProvider.
  void setAudioEngine(String _) {
    HarmonixLogger.instance.info('Audio engine: ${AppConstants.audioEngineName}',
        tag: 'Repository');
  }

  // --- Búsqueda ---
  Future<YtDlpSearchResult> search(String q,
          {YtDlpSearchFilter filter = YtDlpSearchFilter.songs}) =>
      _api.search(q, filter: filter);

  Future<List<String>> suggestions(String q) => _api.suggestions(q);

  Future<List<Song>> trending() => _api.trending();

  /// Resuelve metadatos (título/duración/thumbnail) sin URL directa.
  /// La URL directa se resuelve on-demand desde el audio handler para
  /// no bloquear el inicio del playback.
  Future<Song> fetchMetadata(String videoId) async {
    final song = await _api.fetchMetadata(videoId);
    await _songsBox.put(song.id, song);
    return song;
  }

  /// Resuelve la URL directa de audio para [videoId]. Cacheada en memoria.
  Future<String> resolveDirectUrl(String videoId) =>
      _api.getDirectAudioUrl(videoId);

  /// Precarga la URL de la siguiente pista (background).
  void prefetchNext(String videoId) => _api.prefetchNext(videoId);

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
