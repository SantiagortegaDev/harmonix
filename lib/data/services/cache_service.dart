import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Índice de caché de audio (metadatos).
class CachedAudio {
  CachedAudio({
    required this.videoId,
    required this.filePath,
    required this.sizeBytes,
    required this.cachedAt,
    required this.songTitle,
    required this.songArtist,
    this.thumbnailUrl,
    this.lastAccessed,
  });

  final String videoId;
  final String filePath;
  final int sizeBytes;
  final DateTime cachedAt;
  final String songTitle;
  final String songArtist;
  final String? thumbnailUrl;
  DateTime? lastAccessed;
}

/// Caché inteligente de audio en disco.
///
/// Comportamiento tipo Spotify: las últimas canciones reproducidas se
/// guardan en disco para no volver a streamearlas. Se elimina por LRU
/// cuando se supera el límite configurado (MB).
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  final Dio _dio = Dio();

  Box<CachedAudio>? _box;
  Directory? _cacheDir;
  int _limitMB = AppConstants.defaultCacheLimitMB;

  Future<void> init() async {
    _box = await Hive.openBox<CachedAudio>(AppConstants.boxCache);
    _cacheDir = Directory('${(await getTemporaryDirectory()).path}/harmonix_audio_cache');
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
    HarmonixLogger.instance.info(
        'CacheService init: dir=${_cacheDir!.path} limit=${_limitMB}MB',
        tag: 'Cache');
  }

  void setLimit(int mb) {
    _limitMB = mb.clamp(
        AppConstants.minCacheLimitMB, AppConstants.maxCacheLimitMB);
    _evictIfNeeded();
  }

  int get limitMB => _limitMB;

  /// Devuelve la ruta local cacheada si existe; null si no está en caché.
  String? getCachedPath(String videoId) {
    final e = _box?.get(videoId);
    if (e == null) return null;
    final file = File(e.filePath);
    if (!file.existsSync()) {
      _box?.delete(videoId);
      return null;
    }
    e.lastAccessed = DateTime.now();
    _box?.put(videoId, e);
    return e.filePath;
  }

  /// Descarga el stream de audio a disco si no está cacheado y devuelve la
  /// ruta local. Si falla, devuelve null.
  Future<String?> cacheStream(Song song, String streamUrl) async {
    final existing = getCachedPath(song.id);
    if (existing != null) return existing;
    if (_cacheDir == null) await init();
    try {
      final fileName = '${song.id}.m4a';
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);
      await _dio.download(streamUrl, filePath,
          options: Options(receiveTimeout: const Duration(seconds: 60)));
      final size = await file.length();
      final entry = CachedAudio(
        videoId: song.id,
        filePath: filePath,
        sizeBytes: size,
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        songTitle: song.title,
        songArtist: song.artist,
        thumbnailUrl: song.thumbnailUrl,
      );
      await _box?.put(song.id, entry);
      HarmonixLogger.instance.debug(
          'Cache guardada: ${song.title} (${(size / 1024 / 1024).toStringAsFixed(1)}MB)',
          tag: 'Cache');
      _evictIfNeeded();
      return filePath;
    } catch (e, s) {
      HarmonixLogger.instance.error('Fallo cacheando ${song.id}',
          tag: 'Cache', error: e, stack: s);
      return null;
    }
  }

  int get currentSizeBytes {
    if (_box == null) return 0;
    int total = 0;
    for (final e in _box!.values) {
      total += e.sizeBytes;
    }
    return total;
  }

  double get currentSizeMB => currentSizeBytes / 1024 / 1024;

  Future<void> clearAll() async {
    await _box?.clear();
    if (_cacheDir != null && _cacheDir!.existsSync()) {
      for (final f in _cacheDir!.listSync()) {
        f.deleteSync(recursive: true);
      }
    }
    HarmonixLogger.instance.info('Caché limpiada', tag: 'Cache');
  }

  Future<void> remove(String videoId) async {
    final e = _box?.get(videoId);
    if (e == null) return;
    final file = File(e.filePath);
    if (file.existsSync()) file.deleteSync();
    await _box?.delete(videoId);
  }

  void _evictIfNeeded() {
    if (_box == null) return;
    final limitBytes = _limitMB * 1024 * 1024;
    var total = currentSizeBytes;
    if (total <= limitBytes) return;
    // Ordenar por último acceso (LRU).
    final entries = _box!.values.toList()
      ..sort((a, b) =>
          (a.lastAccessed ?? a.cachedAt).compareTo(b.lastAccessed ?? b.cachedAt));
    for (final e in entries) {
      if (total <= limitBytes) break;
      final file = File(e.filePath);
      if (file.existsSync()) file.deleteSync();
      _box!.delete(e.videoId);
      total -= e.sizeBytes;
    }
    HarmonixLogger.instance.info(
        'Caché evicted: ${currentSizeMB.toStringAsFixed(1)}MB / $_limitMB MB',
        tag: 'Cache');
  }
}
