import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harmonix/core/theme/app_theme.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/hive_adapters.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/audio_player_service.dart';
import 'package:harmonix/data/services/cache_service.dart';
import 'package:harmonix/data/services/download_service.dart';
import 'package:harmonix/data/services/settings_service.dart';
import 'package:harmonix/presentation/providers/library_provider.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/providers/settings_provider.dart';
import 'package:harmonix/presentation/screens/splash/splash_screen.dart';
import 'package:harmonix/presentation/widgets/main_scaffold.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

export 'package:harmonix/presentation/widgets/main_scaffold.dart'
    show HarmonixMain;

/// Completer expuesto para que la splash espere a que la inicialización
/// termine.
class HarmonixBootstrap {
  HarmonixBootstrap._();
  static final Completer<void> _completer = Completer<void>();
  static Future<void> get ready => _completer.future;
  static void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Handler de audio — nullable para que la app sobreviva si AudioService falla.
HarmonixAudioHandler? harmonixAudioHandler;

Future<void> main() async {
  // Capturar errores de Flutter en release para diagnosticar white screen.
  FlutterError.onError = (details) {
    HarmonixLogger.instance.error(
      'FlutterError: ${details.exception}',
      tag: 'Flutter',
      error: details.exception.toString(),
      stack: details.stack,
    );
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: HarmonixColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Hive.initFlutter();
    registerHiveAdapters();
    await SettingsService.instance.init();
    await CacheService.instance.init();
    await DownloadService.instance.init();
    await MusicRepository.instance.init();
  } catch (e, s) {
    HarmonixLogger.instance
        .error('Core init failed', tag: 'App', error: e, stack: s);
  }

  // AudioService init — separado para que un fallo no impida iniciar la app.
  try {
    harmonixAudioHandler = await AudioService.init(
      builder: () => HarmonixAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.harmonix.app.audio',
        androidNotificationChannelName: 'Harmonix',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    HarmonixLogger.instance.info('AudioService init OK', tag: 'App');
  } catch (e, s) {
    HarmonixLogger.instance
        .error('AudioService init failed', tag: 'App', error: e, stack: s);
  }

  try {
    await SettingsProvider.instance.init();
  } catch (e, s) {
    HarmonixLogger.instance
        .error('SettingsProvider init failed', tag: 'App', error: e, stack: s);
  }

  HarmonixLogger.instance.info('Bootstrap completo', tag: 'App');
  HarmonixBootstrap.complete();

  runApp(const HarmonixApp());
}

class HarmonixApp extends StatelessWidget {
  const HarmonixApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Si audioService falló, crear un handler dummy para que PlayerProvider
    // no crashee por null.
    final handler = harmonixAudioHandler ?? HarmonixAudioHandler.fallback();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsProvider.instance),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(handler),
        ),
        ChangeNotifierProvider.value(value: LibraryProvider.instance),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          HarmonixTheme.setSeed(settings.accentSeed);
          return MaterialApp(
            title: 'Harmonix',
            debugShowCheckedModeBanner: false,
            theme: HarmonixTheme.dark(),
            home: const SplashScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}