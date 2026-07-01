import 'package:audio_service/audio_service.dart';
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

late final HarmonixAudioHandler harmonixAudioHandler;

Future<void> main() async {
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
    await SettingsProvider.instance.init();
    HarmonixLogger.instance.info('Bootstrap completo', tag: 'App');
  } catch (e, s) {
    HarmonixLogger.instance
        .error('Bootstrap failed', tag: 'App', error: e, stack: s);
  } finally {
    HarmonixBootstrap.complete();
  }

  runApp(const HarmonixApp());
}

class HarmonixApp extends StatelessWidget {
  const HarmonixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsProvider.instance),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(harmonixAudioHandler),
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
