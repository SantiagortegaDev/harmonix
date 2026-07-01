import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Registro persistente de canciones descargadas para offline.
class DownloadedSong {
  DownloadedSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.sizeBytes,
    required this.downloadedAt,
    this.thumbnailUrl,
    this.durationMs,
  });

  final String videoId;
  final String title;
  final String artist;
  final String filePath;
  final int sizeBytes;
  final DateTime downloadedAt;
  final String? thumbnailUrl;
  final int? durationMs;
}

/// Servicio de descargas para escuchar sin conexión.
///
/// Descarga el stream de audio (vía Piped) a un directorio persistente
/// dentro del almacenamiento de la app.
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  Box<DownloadedSong>? _box;
  Directory? _dir;

  Future<void> init() async {
    _box = await Hive.openBox<DownloadedSong>(AppConstants.boxDownloads);
    final base = await getExternalStorageDirectory();
    _dir = Directory('${base?.path}/Harmonix/Downloads');
    if (!_dir!.existsSync()) _dir!.createSync(recursive: true);
    HarmonixLogger.instance.info('DownloadService init: ${_dir!.path}',
        tag: 'Downloads');
  }

  Directory? get downloadsDir => _dir;
  List<DownloadedSong> get downloads =>
      _box?.values.toList() ?? [];

  bool isDownloaded(String videoId) => _box?.containsKey(videoId) ?? false;

  DownloadedSong? get(String videoId) => _box?.get(videoId);

  /// Descarga el stream desde [streamUrl] y lo registra. Devuelve el path.
  Future<String?> download(Song song, String streamUrl) async {
    if (isDownloaded(song.id)) {
      return _box!.get(song.id)!.filePath;
    }
    if (_dir == null) await init();
    try {
      final file = File('${_dir!.path}/${song.id}.m4a');
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(streamUrl));
      final resp = await req.close();
      final sink = file.openWrite();
      int size = 0;
      await for (final chunk in resp) {
        sink.add(chunk);
        size += chunk.length;
      }
      await sink.flush();
      await sink.close();
      client.close();
      final entry = DownloadedSong(
        videoId: song.id,
        title: song.title,
        artist: song.artist,
        filePath: file.path,
        sizeBytes: size,
        downloadedAt: DateTime.now(),
        thumbnailUrl: song.thumbnailUrl,
        durationMs: song.durationMs,
      );
      await _box?.put(song.id, entry);
      HarmonixLogger.instance.info(
          'Descargado: ${song.title} (${(size / 1024 / 1024).toStringAsFixed(1)}MB)',
          tag: 'Downloads');
      return file.path;
    } catch (e, s) {
      HarmonixLogger.instance.error('Fallo descargando ${song.id}',
          tag: 'Downloads', error: e, stack: s);
      return null;
    }
  }

  Future<void> remove(String videoId) async {
    final e = _box?.get(videoId);
    if (e == null) return;
    final file = File(e.filePath);
    if (file.existsSync()) file.deleteSync();
    await _box?.delete(videoId);
  }

  Future<void> clearAll() async {
    await _box?.clear();
    if (_dir != null && _dir!.existsSync()) {
      for (final f in _dir!.listSync()) {
        f.deleteSync(recursive: true);
      }
    }
  }
}
