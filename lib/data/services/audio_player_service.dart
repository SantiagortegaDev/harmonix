import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/song.dart';
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
      );
}

/// Servicio de audio basado en just_audio + audio_service.
///
/// Implementa [AudioHandler] para background playback, notificación multimedia
/// y soporte Android Auto.
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
    ));
    _broadcastMediaItem();
  }

  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue
      ..clear()
      ..addAll(songs);
    _index = initialIndex.clamp(0, songs.length - 1);
    await _loadCurrent();
    await _player.play();
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

  Future<void> _loadCurrent() async {
    final song = currentSong;
    if (song == null) return;
    try {
      final uri = song.isDownloaded && song.localPath != null
          ? song.localPath!
          : song.streamUrl;
      if (uri == null) {
        HarmonixLogger.instance.warning('streamUrl null para ${song.id}',
            tag: 'Audio');
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
    } catch (e, s) {
      HarmonixLogger.instance.error('Error cargando ${song.id}',
          tag: 'Audio', error: e, stack: s);
    }
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
    await _loadCurrent();
    await _player.play();
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
    if (_queue.isEmpty) return;
    if (_player.shuffleModeEnabled) {
      _index = (_index + 1) % _queue.length;
    } else {
      _index = _index + 1;
      if (_index >= _queue.length) {
        if (_player.loopMode == LoopMode.all) {
          _index = 0;
        } else {
          await _player.stop();
          return;
        }
      }
    }
    await _loadCurrent();
    await _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _index = _index - 1;
    if (_index < 0) {
      _index = _player.loopMode == LoopMode.all ? _queue.length - 1 : 0;
    }
    await _loadCurrent();
    await _player.play();
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
