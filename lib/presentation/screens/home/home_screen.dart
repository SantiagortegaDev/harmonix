import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/artist.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/piped_api_service.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/screens/search/search_screen.dart';
import 'package:harmonix/presentation/screens/settings/settings_screen.dart';
import 'package:harmonix/presentation/widgets/artist_circle.dart';
import 'package:harmonix/presentation/widgets/loading_skeleton.dart';
import 'package:harmonix/presentation/widgets/playlist_card.dart';
import 'package:harmonix/presentation/widgets/song_card.dart';
import 'package:harmonix/presentation/widgets/staggered_list_animation.dart';
import 'package:provider/provider.dart';

/// Pantalla de Inicio: Quick picks, Playlists del Día, Nuevas canciones,
/// Tus artistas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _trending = [];
  List<Song> _recents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trending = await MusicRepository.instance.trending();
      final recents = MusicRepository.instance.recents.take(6).toList();
      setState(() {
        _trending = trending.take(10).toList();
        _recents = recents;
        _loading = false;
      });
    } catch (e, s) {
      HarmonixLogger.instance.error('Home load failed',
          tag: 'Home', error: e, stack: s);
      setState(() {
        _error = 'No se pudo cargar el contenido. Revisa la instancia Piped en Ajustes.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            toolbarHeight: 72,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [HarmonixColors.accent, HarmonixColors.surfaceVariant],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Harmonix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.equalizer_rounded),
                tooltip: 'Ecualizador',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ecualizador próximamente')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Buscar',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Ajustes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_loading)
            SliverToBoxAdapter(child: _buildLoading())
          else if (_error != null)
            SliverToBoxAdapter(child: _buildError())
          else ...[
            SliverToBoxAdapter(child: _buildGreeting()),
            SliverToBoxAdapter(child: _buildPlaylistsOfDay()),
            if (_recents.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader('Reproducido recientemente')),
              SliverToBoxAdapter(child: _buildRecentRow()),
            ],
            const SliverToBoxAdapter(child: _SectionHeader('Nuevas canciones')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final song = _trending[i];
                    return StaggeredItem(
                      index: i,
                      child: SongCard(
                        song: song,
                        onPlay: () => _playSongAt(i),
                        onTap: () => _playSongAt(i),
                      ),
                    );
                  },
                  childCount: _trending.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader('Tus artistas')),
            SliverToBoxAdapter(child: _buildArtistsRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: HarmonixColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            '¿Qué quieres escuchar?',
            style: TextStyle(
              color: HarmonixColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsOfDay() {
    final cats = <_CategoryCard>[
      _CategoryCard(
          title: 'Gym', icon: Icons.fitness_center_rounded, gradient: 0),
      _CategoryCard(title: 'Tristes', icon: Icons.sentiment_dissatisfied, gradient: 1),
      _CategoryCard(title: 'Románticas', icon: Icons.favorite_rounded, gradient: 2),
      _CategoryCard(title: 'Chill', icon: Icons.spa_rounded, gradient: 3),
      _CategoryCard(title: 'Foco', icon: Icons.psychology_rounded, gradient: 4),
      _CategoryCard(title: 'Party', icon: Icons.celebration_rounded, gradient: 5),
    ];
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => StaggeredItem(
          index: i,
          child: PlaylistGradientCard(
            title: cats[i].title,
            icon: cats[i].icon,
            gradientColors: HarmonixColors.playlistGradients[cats[i].gradient],
            subtitle: 'Playlist del día',
            onPlay: () => _searchAndPlay(cats[i].title),
            onTap: () => _searchAndPlay(cats[i].title),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRow() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _recents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = _recents[i];
          return StaggeredItem(
            index: i,
            child: Material(
              color: HarmonixColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.read<PlayerProvider>().playFromRecent(i),
                child: SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        child: SongCover(song: s, size: 64, borderRadius: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: HarmonixColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(s.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: HarmonixColors.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistsRow() {
    // Derivamos "artistas" de las canciones trending (únicos).
    final map = <String, String>{};
    for (final s in _trending) {
      map.putIfAbsent(s.artist, () => s.thumbnailUrl ?? '');
    }
    final artists = map.keys.take(10).toList();
    if (artists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => StaggeredItem(
          index: i,
          child: ArtistCircle(
            artist: Artist(
              id: 'home-$i',
              name: artists[i],
              thumbnailUrl: map[artists[i]],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(height: 20, width: 160),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const PlaylistCardSkeleton(),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: List.generate(6, (_) => const SongCardSkeleton()),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: HarmonixColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: HarmonixColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _playSongAt(int i) {
    final player = context.read<PlayerProvider>();
    player.playQueue(_trending, initialIndex: i);
    player.openFullPlayer();
  }

  Future<void> _searchAndPlay(String category) async {
    final res = await MusicRepository.instance.search('$category music mix',
        filter: PipedSearchFilter.musicSongs);
    if (res.songs.isEmpty) return;
    if (!mounted) return;
    final player = context.read<PlayerProvider>();
    player.playQueue(res.songs, initialIndex: 0);
    player.openFullPlayer();
  }
}

class _CategoryCard {
  _CategoryCard({required this.title, required this.icon, required this.gradient});
  final String title;
  final IconData icon;
  final int gradient;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
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

extension _PlayFromRecent on PlayerProvider {
  Future<void> playFromRecent(int i) async {
    final recents = MusicRepository.instance.recents;
    if (i < 0 || i >= recents.length) return;
    await playQueue(recents, initialIndex: i);
    openFullPlayer();
  }
}
