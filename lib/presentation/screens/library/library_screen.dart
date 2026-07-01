import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/presentation/providers/library_provider.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/widgets/loading_skeleton.dart';
import 'package:harmonix/presentation/widgets/song_tile.dart';
import 'package:harmonix/presentation/widgets/staggered_list_animation.dart';
import 'package:provider/provider.dart';

/// Pantalla de Librería: tarjetas grandes tipo grid (Agregar lista,
/// Canciones Favoritas, Recién añadidas, Más reproducidas) + lista debajo.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LibraryProvider.instance.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Tu Librería',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => StaggeredItem(index: i, child: _bigCard(i)),
                childCount: 5,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _LibSectionHeader('Canciones favoritas')),
          _FavoritesSection(),
          const SliverToBoxAdapter(child: _LibSectionHeader('Recién añadidas')),
          _RecentsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _bigCard(int index) {
    switch (index) {
      case 0:
        return _BigLibraryCard(
          title: 'Agregar lista',
          subtitle: 'Crear nueva playlist',
          icon: Icons.add_rounded,
          gradient: const [HarmonixColors.surfaceVariant, HarmonixColors.surface],
          iconColor: HarmonixColors.accent,
          onTap: () => _showCreatePlaylistDialog(context),
        );
      case 1:
        return _BigLibraryCard(
          title: 'Canciones Favoritas',
          subtitle: '${LibraryProvider.instance.favorites.length} canciones',
          icon: Icons.favorite_rounded,
          gradient: const [HarmonixColors.favorite, Color(0xFFC9184A)],
          iconColor: Colors.white,
          onTap: () => _playAllFavorites(context),
        );
      case 2:
        return _BigLibraryCard(
          title: 'Recién añadidas',
          subtitle: '${LibraryProvider.instance.recents.length} canciones',
          icon: Icons.access_time_rounded,
          gradient: const [HarmonixColors.recent, Color(0xFFE8590C)],
          iconColor: Colors.white,
          onTap: () => _playAllRecents(context),
        );
      case 3:
        return _BigLibraryCard(
          title: 'Más reproducidas',
          subtitle: 'Top reproducciones',
          icon: Icons.trending_up_rounded,
          gradient: const [HarmonixColors.library, Color(0xFF5F3DC4)],
          iconColor: Colors.white,
          onTap: () => _playTop(context),
        );
      case 4:
        return _BigLibraryCard(
          title: 'Descargas',
          subtitle: '${LibraryProvider.instance.downloads.length} canciones',
          icon: Icons.download_rounded,
          gradient: const [HarmonixColors.download, Color(0xFF2B8A3E)],
          iconColor: Colors.white,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva playlist'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Nombre de la playlist',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await MusicRepository.instance.createPlaylist(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
              await LibraryProvider.instance.refresh();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _playAllFavorites(BuildContext context) {
    final favs = LibraryProvider.instance.favorites;
    if (favs.isEmpty) return;
    context.read<PlayerProvider>().playQueue(favs);
    context.read<PlayerProvider>().openFullPlayer();
  }

  void _playAllRecents(BuildContext context) {
    final r = LibraryProvider.instance.recents;
    if (r.isEmpty) return;
    context.read<PlayerProvider>().playQueue(r);
    context.read<PlayerProvider>().openFullPlayer();
  }

  void _playTop(BuildContext context) {
    final r = LibraryRepositoryTop.instance.top;
    if (r.isEmpty) return;
    context.read<PlayerProvider>().playQueue(r);
    context.read<PlayerProvider>().openFullPlayer();
  }
}

class LibraryRepositoryTop {
  LibraryRepositoryTop._();
  static final LibraryRepositoryTop instance = LibraryRepositoryTop._();
  List<Song> get top => MusicRepository.instance.recents
      .where((s) => s.playCount > 0)
      .toList()
    ..sort((a, b) => b.playCount.compareTo(a.playCount));
}

class _BigLibraryCard extends StatelessWidget {
  const _BigLibraryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibSectionHeader extends StatelessWidget {
  const _LibSectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        text,
        style: const TextStyle(
          color: HarmonixColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favs = context.select<LibraryProvider, List<Song>>((p) => p.favorites);
    if (favs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text('Aún no tienes canciones favoritas.',
              style: TextStyle(color: HarmonixColors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => StaggeredItem(
          index: i,
          child: SongTile(
            song: favs[i],
            index: i,
            onTap: () {
              context.read<PlayerProvider>().playQueue(favs, initialIndex: i);
              context.read<PlayerProvider>().openFullPlayer();
            },
          ),
        ),
        childCount: favs.length,
      ),
    );
  }
}

class _RecentsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final recents =
        context.select<LibraryProvider, List<Song>>((p) => p.recents);
    if (recents.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text('No has reproducido canciones aún.',
              style: TextStyle(color: HarmonixColors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => StaggeredItem(
          index: i,
          child: SongTile(
            song: recents[i],
            index: i,
            onTap: () {
              context
                  .read<PlayerProvider>()
                  .playQueue(recents, initialIndex: i);
              context.read<PlayerProvider>().openFullPlayer();
            },
          ),
        ),
        childCount: recents.length,
      ),
    );
  }
}
