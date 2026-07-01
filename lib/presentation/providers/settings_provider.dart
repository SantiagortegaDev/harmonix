import 'package:flutter/foundation.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/services/settings_service.dart';

/// Provider reactivo para ajustes que afectan a la UI (semilla de color,
/// instancia Piped, etc.).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider._();
  static final SettingsProvider instance = SettingsProvider._();

  late SettingsService _service;
  Color _accentSeed = HarmonixColors.accent;
  String _pipedInstance = '';
  int _cacheLimitMB = 500;

  Future<void> init() async {
    _service = SettingsService.instance;
    await _service.init();
    _accentSeed = _service.accentSeed;
    _pipedInstance = _service.pipedInstance;
    _cacheLimitMB = _service.cacheLimitMB;
    _service.addListener(_onService);
  }

  void _onService() {
    _accentSeed = _service.accentSeed;
    _pipedInstance = _service.pipedInstance;
    _cacheLimitMB = _service.cacheLimitMB;
    notifyListeners();
  }

  SettingsService get service => _service;

  Color get accentSeed => _accentSeed;
  String get pipedInstance => _pipedInstance;
  int get cacheLimitMB => _cacheLimitMB;

  Future<void> setAccentSeedIndex(int idx) async {
    await _service.setAccentSeedIndex(idx);
  }

  Future<void> setPipedInstance(String v) async {
    await _service.setPipedInstance(v);
  }

  Future<void> setCacheLimitMB(int v) async {
    await _service.setCacheLimitMB(v);
  }
}
