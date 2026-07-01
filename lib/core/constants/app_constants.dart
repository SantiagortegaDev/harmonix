/// Constantes globales de Harmonix.
class AppConstants {
  AppConstants._();

  static const String appName = 'Harmonix';

  /// Instancia Piped por defecto.
  static const String defaultPipedInstance = 'https://piped.private.coffee';

  /// Endpoints Piped API.
  static const String pathSearch = '/search';
  static const String pathStreams = '/streams';
  static const String pathPlaylists = '/playlists';
  static const String pathChannel = '/channel';
  static const String pathNext = '/next';
  static const String pathTrending = '/trending';
  static const String pathSuggestions = '/suggestions';

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
