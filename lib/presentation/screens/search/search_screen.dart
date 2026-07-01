import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/piped_api_service.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/widgets/loading_skeleton.dart';
import 'package:harmonix/presentation/widgets/song_tile.dart';
import 'package:harmonix/presentation/widgets/staggered_list_animation.dart';
import 'package:provider/provider.dart';

/// Pantalla de búsqueda con filtros (canciones, videos, álbumes, playlists,
/// artistas) + sugerencias.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final TabController _tabs;
  bool _loading = false;
  String _query = '';
  PipedSearchResult _result = PipedSearchResult();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _ctrl.addListener(_onType);
  }

  void _onType() async {
    final q = _ctrl.text.trim();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final s = await MusicRepository.instance.suggestions(q);
    if (!mounted) return;
    setState(() => _suggestions = s.take(6).toList());
  }

  Future<void> _submit(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _query = q;
      _suggestions = [];
    });
    try {
      final res = await MusicRepository.instance.search(q);
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (e, s) {
      HarmonixLogger.instance.error('Search failed',
          tag: 'Search', error: e, stack: s);
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                controller: _ctrl,
                focusNode: _focus,
                hintText: 'Canciones, artistas, álbumes...',
                leading: const Icon(Icons.search_rounded,
                    color: HarmonixColors.accent),
                trailing: [
                  if (_ctrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _result = PipedSearchResult();
                          _query = '';
                        });
                      },
                    ),
                ],
                onSubmitted: _submit,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(
                    HarmonixColors.surface),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                )),
                textStyle: const WidgetStatePropertyAll(TextStyle(
                    color: HarmonixColors.textPrimary, fontSize: 15)),
              ),
            ),
            if (_suggestions.isNotEmpty && _query.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _suggestions
                      .map((s) => ListTile(
                            leading: const Icon(Icons.search_rounded,
                                color: HarmonixColors.textSecondary, size: 20),
                            title: Text(s,
                                style: const TextStyle(
                                    color: HarmonixColors.textPrimary,
                                    fontSize: 14)),
                            onTap: () {
                              _ctrl.text = s;
                              _submit(s);
                            },
                          ))
                      .toList(),
                ),
              ),
            if (_query.isNotEmpty) ...[
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Canciones'),
                  Tab(text: 'Álbumes'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Artistas'),
                ],
                indicatorColor: HarmonixColors.accent,
                labelColor: HarmonixColors.accentBright,
                unselectedLabelColor: HarmonixColors.textSecondary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _songList(_result.songs),
                    _albumList(_result.albums),
                    _playlistList(_result.playlists),
                    _artistList(_result.artists),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded,
                          size: 72, color: HarmonixColors.textDisabled),
                      const SizedBox(height: 12),
                      const Text('Busca tu música favorita',
                          style: TextStyle(
                              color: HarmonixColors.textSecondary,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _songList(List<Song> songs) {
    if (_loading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LoadingSkeleton(height: 56, borderRadius: 14),
        ),
      );
    }
    if (songs.isEmpty) {
      return const Center(
        child: Text('Sin resultados',
            style: TextStyle(color: HarmonixColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, i) => StaggeredItem(
        index: i,
        child: SongTile(
          song: songs[i],
          index: i,
          onTap: () {
            final player = context.read<PlayerProvider>();
            player.playQueue(songs, initialIndex: i);
            player.openFullPlayer();
          },
        ),
      ),
    );
  }

  Widget _albumList(List albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('Sin álbumes',
            style: TextStyle(color: HarmonixColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(albums[i].name),
        subtitle: Text(albums[i].artist),
      ),
    );
  }

  Widget _playlistList(List playlists) {
    if (playlists.isEmpty) {
      return const Center(
        child: Text('Sin playlists',
            style: TextStyle(color: HarmonixColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(playlists[i].name),
        subtitle: Text(playlists[i].uploader ?? ''),
      ),
    );
  }

  Widget _artistList(List artists) {
    if (artists.isEmpty) {
      return const Center(
        child: Text('Sin artistas',
            style: TextStyle(color: HarmonixColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.person_rounded, color: HarmonixColors.accent),
        title: Text(artists[i].name),
      ),
    );
  }
}
