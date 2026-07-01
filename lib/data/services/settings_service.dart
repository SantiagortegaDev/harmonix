import 'package:flutter/material.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de preferencias de usuario (Hive box + SharedPreferences para
/// primitives frecuentes).
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late Box _box;

  // Claves
  static const _kPipedInstance = 'piped_instance';
  static const _kAccentSeed = 'accent_seed';
  static const _kCacheLimit = 'cache_limit_mb';
  static const _kLanguage = 'language';
  static const _kNotifications = 'notifications';
  static const _kBackgroundPlayback = 'background_playback';
  static const _kAllowedFolders = 'allowed_folders';
  static const _kShowHiddenFiles = 'show_hidden_files';
  static const _kFileFilter = 'file_filter';
  static const _kSkipSilence = 'skip_silence';
  static const _kNormalize = 'normalize_audio';
  static const _kDiscordRpc = 'discord_rpc';
  static const _kDebugMode = 'debug_mode';

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.boxSettings);
    HarmonixLogger.instance.info('SettingsService init', tag: 'Settings');
  }

  // --- Getters ---
  String get pipedInstance =>
      _box.get(_kPipedInstance, defaultValue: AppConstants.defaultPipedInstance) as String;

  Color get accentSeed {
    final idx = _box.get(_kAccentSeed, defaultValue: 0) as int;
    return HarmonixColors.accentSeeds[idx.clamp(0, HarmonixColors.accentSeeds.length - 1)];
  }

  int get accentSeedIndex =>
      _box.get(_kAccentSeed, defaultValue: 0) as int;

  int get cacheLimitMB =>
      _box.get(_kCacheLimit, defaultValue: AppConstants.defaultCacheLimitMB) as int;

  String get language =>
      _box.get(_kLanguage, defaultValue: 'es') as String;

  bool get notifications =>
      _box.get(_kNotifications, defaultValue: true) as bool;

  bool get backgroundPlayback =>
      _box.get(_kBackgroundPlayback, defaultValue: true) as bool;

  List<String> get allowedFolders =>
      (_box.get(_kAllowedFolders, defaultValue: <String>[]) as List)
          .map((e) => e.toString())
          .toList();

  bool get showHiddenFiles =>
      _box.get(_kShowHiddenFiles, defaultValue: false) as bool;

  String get fileFilter =>
      _box.get(_kFileFilter, defaultValue: '*.mp3;*.m4a;*.flac;*.wav;*.ogg') as String;

  bool get skipSilence =>
      _box.get(_kSkipSilence, defaultValue: false) as bool;

  bool get normalizeAudio =>
      _box.get(_kNormalize, defaultValue: false) as bool;

  bool get discordRpc =>
      _box.get(_kDiscordRpc, defaultValue: false) as bool;

  bool get debugMode =>
      _box.get(_kDebugMode, defaultValue: false) as bool;

  // --- Setters ---
  Future<void> setPipedInstance(String v) async {
    await _box.put(_kPipedInstance, v);
    notifyListeners();
  }

  Future<void> setAccentSeedIndex(int v) async {
    await _box.put(_kAccentSeed, v);
    notifyListeners();
  }

  Future<void> setCacheLimitMB(int v) async {
    await _box.put(_kCacheLimit, v);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    await _box.put(_kLanguage, v);
    notifyListeners();
  }

  Future<void> setNotifications(bool v) async {
    await _box.put(_kNotifications, v);
    notifyListeners();
  }

  Future<void> setBackgroundPlayback(bool v) async {
    await _box.put(_kBackgroundPlayback, v);
    notifyListeners();
  }

  Future<void> setAllowedFolders(List<String> v) async {
    await _box.put(_kAllowedFolders, v);
    notifyListeners();
  }

  Future<void> setShowHiddenFiles(bool v) async {
    await _box.put(_kShowHiddenFiles, v);
    notifyListeners();
  }

  Future<void> setFileFilter(String v) async {
    await _box.put(_kFileFilter, v);
    notifyListeners();
  }

  Future<void> setSkipSilence(bool v) async {
    await _box.put(_kSkipSilence, v);
    notifyListeners();
  }

  Future<void> setNormalizeAudio(bool v) async {
    await _box.put(_kNormalize, v);
    notifyListeners();
  }

  Future<void> setDiscordRpc(bool v) async {
    await _box.put(_kDiscordRpc, v);
    notifyListeners();
  }

  Future<void> setDebugMode(bool v) async {
    await _box.put(_kDebugMode, v);
    notifyListeners();
  }
}
