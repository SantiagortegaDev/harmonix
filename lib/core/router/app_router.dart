import 'package:flutter/material.dart';

// Re-export simplificado: en esta app usaremos Navigator 1.0 estándar con
// nombres de rutas para tener control fino sobre las transiciones hero y
// los PageTransitions del tema. Este archivo queda como catálogo central
// de rutas nombradas.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String library = '/library';
  static const String downloads = '/downloads';
  static const String files = '/files';
  static const String search = '/search';
  static const String player = '/player';
  static const String settings = '/settings';
  static const String debugLogs = '/debug-logs';
  static const String playlistDetail = '/playlist';
  static const String artistDetail = '/artist';
  static const String albumDetail = '/album';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const _Placeholder(), settings);
      default:
        return null;
    }
  }

  static Route<_Placeholder> _fadeRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder<_Placeholder>(
      settings: settings,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

/// Helpers de navegación con transiciones personalizadas.
class Nav {
  Nav._();

  static Future<T?> push<T extends Object?>(BuildContext context, Widget page,
      {String? heroTag}) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  static Future<T?> pushHero<T extends Object?>(
      BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => page,
        fullscreenDialog: false,
      ),
    );
  }
}
