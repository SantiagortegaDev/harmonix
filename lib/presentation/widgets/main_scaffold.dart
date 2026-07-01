import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/screens/downloads/downloads_screen.dart';
import 'package:harmonix/presentation/screens/files/files_screen.dart';
import 'package:harmonix/presentation/screens/home/home_screen.dart';
import 'package:harmonix/presentation/screens/library/library_screen.dart';
import 'package:harmonix/presentation/screens/player/full_player_screen.dart';
import 'package:harmonix/presentation/widgets/mini_player.dart';
import 'package:provider/provider.dart';

/// Scaffold principal con NavigationBar MD3 flotante y mini-player.
/// El reproductor completo aparece como overlay cuando [PlayerProvider.showFullPlayer]
/// es true, con animación hero desde el mini-player.
class HarmonixMain extends StatefulWidget {
  const HarmonixMain({super.key});

  @override
  State<HarmonixMain> createState() => _HarmonixMainState();
}

class _HarmonixMainState extends State<HarmonixMain> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    LibraryScreen(),
    DownloadsScreen(),
    FilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: HarmonixColors.background,
          body: IndexedStack(
            index: _index,
            children: _screens,
          ),
          bottomNavigationBar: _HarmonixNavigationBar(
            index: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
        ),
        // Mini-player flotante sobre la nav bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 76,
          child: const MiniPlayer(),
        ),
        // Reproductor completo como overlay hero
        if (player.showFullPlayer)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !player.showFullPlayer,
              child: Hero(
                tag: MiniPlayer.heroTag,
                child: Material(
                  color: HarmonixColors.background,
                  child: const FullPlayerScreen(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HarmonixNavigationBar extends StatelessWidget {
  const _HarmonixNavigationBar({
    required this.index,
    required this.onChanged,
  });
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onChanged,
        backgroundColor: HarmonixColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: HarmonixColors.accent.withValues(alpha: 0.18),
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Librería',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download_rounded),
            label: 'Descargas',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Archivos',
          ),
        ],
      ),
    );
  }
}
