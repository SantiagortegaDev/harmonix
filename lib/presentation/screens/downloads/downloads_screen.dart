import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/services/download_service.dart';
import 'package:harmonix/presentation/providers/library_provider.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/widgets/loading_skeleton.dart';
import 'package:harmonix/presentation/widgets/song_tile.dart';
import 'package:harmonix/presentation/widgets/staggered_list_animation.dart';
import 'package:provider/provider.dart';

/// Pantalla de Descargas para escuchar sin conexión.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LibraryProvider.instance.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.select<LibraryProvider,
        List<DownloadedSong>>((p) => p.downloads);
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Descargas',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            floating: true,
            actions: [
              if (downloads.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('¿Borrar todas las descargas?'),
                        content: const Text(
                            'Esto eliminará todos los archivos descargados de tu dispositivo.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Borrar todo'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DownloadService.instance.clearAll();
                      await LibraryProvider.instance.refresh();
                    }
                  },
                ),
            ],
          ),
          if (downloads.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_for_offline_outlined,
                      size: 72, color: HarmonixColors.textDisabled),
                  const SizedBox(height: 16),
                  const Text('Sin descargas',
                      style: TextStyle(
                          color: HarmonixColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text(
                      'Descarga canciones para escucharlas sin conexión',
                      style: TextStyle(
                          color: HarmonixColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final d = downloads[i];
                  return StaggeredItem(
                    index: i,
                    child: SongTile(
                      song: Song(
                        id: d.videoId,
                        title: d.title,
                        artist: d.artist,
                        thumbnailUrl: d.thumbnailUrl,
                        durationMs: d.durationMs,
                        isDownloaded: true,
                        localPath: d.filePath,
                      ),
                      index: i,
                      isActive: false,
                      onTap: () async {
                        final song = Song(
                          id: d.videoId,
                          title: d.title,
                          artist: d.artist,
                          thumbnailUrl: d.thumbnailUrl,
                          durationMs: d.durationMs,
                          isDownloaded: true,
                          localPath: d.filePath,
                          streamUrl: d.filePath,
                        );
                        if (!context.mounted) return;
                        context.read<PlayerProvider>().playQueue([song]);
                        context.read<PlayerProvider>().openFullPlayer();
                      },
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: HarmonixColors.textSecondary),
                        onSelected: (v) async {
                          if (v == 'remove') {
                            await LibraryProvider.instance
                                .removeDownload(d.videoId);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'remove', child: Text('Eliminar')),
                        ],
                      ),
                    ),
                  );
                },
                childCount: downloads.length,
              ),
            ),
        ],
      ),
    );
  }
}
