import 'dart:io';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/services/settings_service.dart';
import 'package:harmonix/presentation/providers/player_provider.dart';
import 'package:harmonix/presentation/widgets/staggered_list_animation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Pantalla de Archivos: explora carpetas locales permitidas y reproduce
/// archivos de audio locales.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  Directory? _root;
  final List<FileSystemEntity> _entries = [];
  bool _loading = true;
  String _currentPath = '';

  static const _audioExts = ['.mp3', '.m4a', '.flac', '.wav', '.ogg', '.aac'];

  @override
  void initState() {
    super.initState();
    _initRoot();
  }

  Future<void> _initRoot() async {
    Directory? base;
    try {
      base = await getExternalStorageDirectory();
    } catch (_) {}
    if (base == null) {
      base = await getApplicationDocumentsDirectory();
    }
    setState(() {
      _root = base;
      _currentPath = base.path;
    });
    await _loadDir(base.path);
  }

  Future<void> _loadDir(String path) async {
    setState(() {
      _loading = true;
      _currentPath = path;
      _entries.clear();
    });
    try {
      final dir = Directory(path);
      final entities = dir.listSync();
      final showHidden = SettingsService.instance.showHiddenFiles;
      final filtered = entities.where((e) {
        final name = e.path.split('/').last;
        if (!showHidden && name.startsWith('.')) return false;
        if (e is File) {
          final lower = e.path.toLowerCase();
          return _audioExts.any((ext) => lower.endsWith(ext));
        }
        return true;
      }).toList()
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return a.path
              .split('/')
              .last
              .toLowerCase()
              .compareTo(b.path.split('/').last.toLowerCase());
        });
      setState(() {
        _entries.addAll(filtered);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Archivos',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: HarmonixColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded,
                        color: HarmonixColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentPath.replaceAll(_root?.path ?? '', '~'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: HarmonixColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    if (_currentPath != _root?.path)
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded,
                            color: HarmonixColors.accent, size: 20),
                        onPressed: () {
                          final parent = Directory(_currentPath).parent;
                          if (parent.path == '/' ||
                              !_currentPath.startsWith(_root!.path)) return;
                          _loadDir(parent.path);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_entries.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No hay archivos de audio aquí',
                    style: TextStyle(color: HarmonixColors.textSecondary)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = _entries[i];
                  final name = entry.path.split('/').last;
                  final isDir = entry is Directory;
                  return StaggeredItem(
                    index: i,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDir
                              ? HarmonixColors.surfaceVariant
                              : HarmonixColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDir
                              ? Icons.folder_rounded
                              : Icons.music_note_rounded,
                          color: isDir
                              ? HarmonixColors.accent
                              : HarmonixColors.accentBright,
                        ),
                      ),
                      title: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: HarmonixColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      subtitle: Text(
                          isDir ? 'Carpeta' : 'Archivo de audio',
                          style: const TextStyle(
                              color: HarmonixColors.textSecondary,
                              fontSize: 11)),
                      onTap: () async {
                        if (isDir) {
                          await _loadDir(entry.path);
                        } else {
                          final song = Song(
                            id: 'local-${entry.path}',
                            title: name.replaceAll(
                                RegExp(r'\.[^.]+$'), ''),
                            artist: 'Local',
                            localPath: entry.path,
                            streamUrl: entry.path,
                            isDownloaded: true,
                          );
                          if (!context.mounted) return;
                          context
                              .read<PlayerProvider>()
                              .playQueue([song]);
                          context.read<PlayerProvider>().openFullPlayer();
                        }
                      },
                    ),
                  );
                },
                childCount: _entries.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
