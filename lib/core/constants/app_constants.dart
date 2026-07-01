/// Constantes globales de Harmonix.
class AppConstants {
  AppConstants._();

  static const String appName = 'Harmonix';

  /// Motor de extracción de audio (yt-dlp vía youtube_explode_dart).
  /// Sin instancia externa: las URLs directas se resuelven en el dispositivo.
  static const String audioEngineName = 'yt-dlp (youtube_explode_dart)';

  /// TTL de la caché en memoria de URLs directas resueltas (5 min).
  /// Las URLs de googlevideo expiran rápido; refrescarlas es barato.
  static const Duration directUrlTtl = Duration(minutes: 5);

  /// Caché de audio.
  static const int defaultCacheLimitMB = 500;
  static const int minCacheLimitMB = 50;
  static const int maxCacheLimitMB = 5000;

  /// Hive boxes.
  static const String boxSettings = 'harmonix_settings';
  static const String boxSongs = 'harmonix_songs';
  static const String boxCache = 'harmonix_cache_index';
  static const String boxDownloads = 'harmonix_downloads';
  static const String boxRecents = 'harmonix_recents';
  static const String boxFavorites = 'harmonix_favorites';
  static const String boxPlaylists = 'harmonix_playlists_user';

  /// UI.
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animHero = Duration(milliseconds: 420);

  /// Discord RPC (opcional).
  static const String discordAppId = '1265480000000000000'; // placeholder
}
