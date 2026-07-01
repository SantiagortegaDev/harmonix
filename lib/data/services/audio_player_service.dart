import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/cache_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Estado expuesto por el reproductor a la UI.
class PlayerStateData {
  PlayerStateData({
    this.song,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.queueIndex = 0,
    this.shuffleMode = false,
    this.loopMode = LoopMode.off,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.skipSilence = false,
    this.volume = 1.0,
    this.isResolving = false,
  });

  final Song? song;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration buffered;
  final Duration duration;
  final List<Song> queue;
  final int queueIndex;
  final bool shuffleMode;
  final LoopMode loopMode;
  final double speed;
  final double pitch;
  final bool skipSilence;
  final double volume;

  /// True mientras se resuelve la URL directa en background (yt-dlp).
  final bool isResolving;

  PlayerStateData copyWith({
    Song? song,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? buffered,
    Duration? duration,
    List<Song>? queue,
    int? queueIndex,
    bool? shuffleMode,
    LoopMode? loopMode,
    double? speed,
    double? pitch,
    bool? skipSilence,
    double? volume,
    bool? isResolving,
  }) =>
      PlayerStateData(
        song: song ?? this.song,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        position: position ?? this.position,
        buffered: buffered ?? this.buffered,
        duration: duration ?? this.duration,
        queue: queue ?? this.queue,
        queueIndex: queueIndex ?? this.queueIndex,
        shuffleMode: shuffleMode ?? this.shuffleMode,
        loopMode: loopMode ?? this.loopMode,
        speed: speed ?? this.speed,
        pitch: pitch ?? this.pitch,
        skipSilence: skipSilence ?? this.skipSilence,
        volume: volume ?? this.volume,
        isResolving: isResolving ?? this.isResolving,
      );
}

/// Servicio de audio basado en just_audio + audio_service.
///
/// Implementa [AudioHandler] para background playback, notificación multimedia
/// y soporte Android Auto.
///
/// Estrategia de carga ultra-rápida (estilo Spotify):
///   1. `playQueue` setea la cola y arranca `_loadCurrent()` SIN esperarlo.
///   2. `_loadCurrent()` resuelve la URL directa vía `YtDlpService` (cacheada
///      en memoria: hit = 0ms, miss = ~1-2s) y apenas tenga la URL, llama a
///      `setAudioSource + play()`.
///   3. Una vez cargada la pista actual, precarga en background la URL de la
///      SIGUIENTE pista → el skip es cuasi-inmediato.
class HarmonixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  HarmonixAudioHandler() {
    _player = AudioPlayer();
    _setupEffects();
    _listenPlayer();
  }

  late final AudioPlayer _player;

  /// Cola interna de canciones Harmonix (paralela a queue.sequenceState).
  final List<Song> _queue = [];
  int _index = -1;
  bool _skipSilence = false;
  double _speed = 1.0;
  double _pitch = 1.0;

  /// True mientras se está resolviendo la URL de la pista actual.
  bool _resolving = false;

  AudioPlayer get player => _player;
  List<Song> get harmonixQueue => List.unmodifiable(_queue);
  int get harmonixIndex => _index;
  Song? get currentSong =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;

  final BehaviorSubject<PlayerStateData> _stateController =
      BehaviorSubject<PlayerStateData>.seeded(PlayerStateData());
  Stream<PlayerStateData> get stateStream => _stateController.stream;
  PlayerStateData get currentState => _stateController.value;

  void _setupEffects() {
    _player.setAudioPipeline(
      AudioPipeline(
        androidAudioEffects: [
          AndroidLoudnessEnhancer(),
        ],
        darwinAudioEffects: [],
      ),
    );
  }

  void _listenPlayer() {
    _player.playerStateStream.listen((state) {
      _emit();
      if (state.processingState == ProcessingState.completed) {
        _handleEnd();
      }
    });
    _player.positionStream.listen((_) => _emit());
    _player.bufferedPositionStream.listen((_) => _emit());
    _player.durationStream.listen((_) => _emit());
    _player.shuffleModeEnabledStream.listen((_) => _emit());
    _player.loopModeStream.listen((_) => _emit());
    _player.speedStream.listen((s) { _speed = s; _emit(); });
  }

  void _emit() {
    final ps = _player.playerState;
    _stateController.add(PlayerStateData(
      song: currentSong,
      isPlaying: ps.playing,
      isBuffering: ps.processingState == ProcessingState.buffering,
      position: _player.position,
      buffered: _player.bufferedPosition,
      duration: _player.duration ?? Duration.zero,
      queue: List.unmodifiable(_queue),
      queueIndex: _index,
      shuffleMode: _player.shuffleModeEnabled,
      loopMode: _player.loopMode,
      speed: _speed,
      pitch: _pitch,
      skipSilence: _skipSilence,
      volume: _player.volume,
      isResolving: _resolving,
    ));
    _broadcastMediaItem();
  }

  /// Carga la cola y arranca la reproducción inmediatamente (sin bloquear
  /// para resolver todas las URLs).
  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue
      ..clear()
      ..addAll(songs);
    _index = initialIndex.clamp(0, songs.length - 1);
    // NO esperamos a _loadCurrent para que la UI muestre "cargando" y
    // arranque el audio en cuanto la URL esté lista (1-2s).
    unawaited(_loadCurrent());
  }

  Future<void> playFrom(Song song) async {
    await playQueue([song], initialIndex: 0);
  }

  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    _emit();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _index) {
      _index--;
    } else if (index == _index) {
      if (_index >= _queue.length) _index = _queue.length - 1;
      await _loadCurrent();
    }
    _emit();
  }

  /// Carga la pista actual.
  ///
  /// Orden de resolución de URL:
  ///   1. Si está descargada → usar `localPath`.
  ///   2. Si hay caché en disco → usar el path cacheado.
  ///   3. Si `song.streamUrl` ya está poblado → usarlo.
  ///   4. Sino → resolver via `YtDlpService.getDirectAudioUrl(id)`.
  Future<void> _loadCurrent() async {
    final song = currentSong;
    if (song == null) return;

    _resolving = true;
    _emit();

    try {
      String? uri;

      // 1) Descarga / caché en disco → path local instantáneo.
      final cachedPath = CacheService.instance.getCachedPath(song.id);
      if (cachedPath != null) {
        uri = cachedPath;
      } else if (song.isDownloaded && song.localPath != null) {
        uri = song.localPath;
      } else if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
        // 2) URL ya resuelta (e.g., segundo play).
        uri = song.streamUrl;
      } else {
        // 3) Resolver con yt-dlp (youtube_explode_dart).
        try {
          final url = await MusicRepository.instance.resolveDirectUrl(song.id);
          uri = url;
          // Mutar la canción en cola para que un segundo play sea 0ms.
          song.streamUrl = url;
          // Cachear en disco en background (no bloquea playback).
          unawaited(
            CacheService.instance.cacheStream(song, url).catchError((_) => ''),
          );
        } catch (e, s) {
          HarmonixLogger.instance.error('resolve ${song.id} failed',
              tag: 'Audio', error: e, stack: s);
        }
      }

      if (uri == null) {
        HarmonixLogger.instance.warning('No se pudo resolver URL para ${song.id}',
            tag: 'Audio');
        _resolving = false;
        _emit();
        return;
      }

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(uri),
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            artUri: song.thumbnailUrl != null
                ? Uri.parse(song.thumbnailUrl!)
                : null,
            duration: song.durationMs != null
                ? Duration(milliseconds: song.durationMs!)
                : null,
          ),
        ),
      );

      _resolving = false;
      _emit();
      await _player.play();

      // Precargar la SIGUIENTE pista en background para skip cuasi-inmediato.
      final nextIdx = _nextIndex();
      if (nextIdx != null && nextIdx != _index) {
        final next = _queue[nextIdx];
        if (next.streamUrl == null ||
            (next.streamUrl?.isEmpty ?? true)) {
          if (!next.isDownloaded && next.localPath == null) {
            MusicRepository.instance.prefetchNext(next.id);
          }
        }
      }
    } catch (e, s) {
      HarmonixLogger.instance.error('Error cargando ${song.id}',
          tag: 'Audio', error: e, stack: s);
      _resolving = false;
      _emit();
    }
  }

  int? _nextIndex() {
    if (_queue.isEmpty) return null;
    if (_player.shuffleModeEnabled) {
      return (_index + 1) % _queue.length;
    }
    final next = _index + 1;
    if (next >= _queue.length) {
      return _player.loopMode == LoopMode.all ? 0 : null;
    }
    return next;
  }

  Future<void> _handleEnd() async {
    if (_player.loopMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    await skipToNext();
  }

  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    unawaited(_loadCurrent());
  }

  // ---- Controles BaseAudioHandler ----
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final next = _nextIndex();
    if (next == null) {
      await _player.stop();
      return;
    }
    _index = next;
    unawaited(_loadCurrent());
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _index = _index - 1;
    if (_index < 0) {
      _index = _player.loopMode == LoopMode.all ? _queue.length - 1 : 0;
    }
    unawaited(_loadCurrent());
  }

  @override
  Future<void> setShuffleMode(bool shuffle) async {
    await _player.setShuffleModeEnabled(shuffle);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loop = repeatMode == AudioServiceRepeatMode.one
        ? LoopMode.one
        : repeatMode == AudioServiceRepeatMode.all
            ? LoopMode.all
            : LoopMode.off;
    await _player.setLoopMode(loop);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setPitch(double pitch) async {
    await _player.setPitch(pitch);
    _pitch = pitch;
    _emit();
  }

  Future<void> setSkipSilence(bool enabled) async {
    _skipSilence = enabled;
    await _player.setSkipSilencesEnabled(enabled);
    _emit();
  }

  Future<void> setVolume(double vol) async {
    await _player.setVolume(vol);
    _emit();
  }

  void _broadcastMediaItem() {
    final s = currentSong;
    if (s == null) return;
    mediaItem.add(MediaItem(
      id: s.id,
      title: s.title,
      artist: s.artist,
      album: s.album,
      artUri: s.thumbnailUrl != null ? Uri.parse(s.thumbnailUrl!) : null,
      duration: s.durationMs != null
          ? Duration(milliseconds: s.durationMs!)
          : null,
    ));
  }
}
