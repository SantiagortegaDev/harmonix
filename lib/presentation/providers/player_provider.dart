import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/audio_player_service.dart';
import 'package:harmonix/data/services/lyrics_service.dart';
import 'package:audio_service/audio_service.dart' show AudioServiceShuffleMode;
import 'package:just_audio/just_audio.dart' show LoopMode;

/// Provider principal del reproductor.
///
/// Envuelve [HarmonixAudioHandler] exponiendo estado reactivo a la UI
/// (canción actual, posición, cola, favorito, letra).
///
/// NOTA: la resolución de URL directa de YouTube (vía yt-dlp) se hace ahora
/// on-demand dentro del [HarmonixAudioHandler] para que el playback arranque
/// cuanto antes. Aquí solo orquestamos cola + letra + favoritos.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider(this._handler) {
    _handler.stateStream.listen(_onState);
  }

  final HarmonixAudioHandler _handler;
  HarmonixAudioHandler get handler => _handler;

  PlayerStateData _state = PlayerStateData();
  PlayerStateData get state => _state;

  Song? get currentSong => _state.song;
  bool get isPlaying => _state.isPlaying;
  bool get isResolving => _state.isResolving;
  Duration get position => _state.position;
  Duration get duration => _state.duration;

  List<LyricLine> _lyrics = [];
  List<LyricLine> get lyrics => _lyrics;

  List<LyricLine> _translatedLyrics = [];
  List<LyricLine> get translatedLyrics => _translatedLyrics;

  bool _translateLyrics = false;
  bool get translateLyrics => _translateLyrics;

  bool _showFullPlayer = false;
  bool get showFullPlayer => _showFullPlayer;

  int get currentLyricIndex {
    if (_lyrics.isEmpty) return -1;
    final pos = _state.position;
    for (int i = _lyrics.length - 1; i >= 0; i--) {
      if (_lyrics[i].time <= pos) return i;
    }
    return 0;
  }

  void _onState(PlayerStateData s) {
    _state = s;
    notifyListeners();
  }

  /// Carga la cola y arranca el playback SIN pre-resolver todas las URLs.
  /// El handler resuelve la URL de la pista actual on-demand (1-2s) y
  /// precarga la siguiente en background.
  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    await _handler.playQueue(songs, initialIndex: initialIndex);
    final initial = songs[initialIndex.clamp(0, songs.length - 1)];
    unawaited(_loadLyrics(initial));
    unawaited(MusicRepository.instance.markPlayed(initial));
  }

  Future<void> _loadLyrics(Song song) async {
    _lyrics = [];
    _translatedLyrics = [];
    notifyListeners();
    final res = await LyricsService.instance.fetch(
      title: song.title,
      artist: song.artist,
      album: song.album,
      durationMs: song.durationMs,
    );
    _lyrics = res.original;
    notifyListeners();
  }

  Future<void> toggleTranslation({String to = 'es'}) async {
    if (_translateLyrics) {
      _translateLyrics = false;
      notifyListeners();
      return;
    }
    if (_translatedLyrics.isEmpty && _lyrics.isNotEmpty) {
      _translatedLyrics = await LyricsService.instance.translate(_lyrics, to: to);
    }
    _translateLyrics = true;
    notifyListeners();
  }

  // Controles básicos delegados
  Future<void> togglePlay() async {
    if (isPlaying) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seekTo(Duration pos) => _handler.seek(pos);

  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();

  Future<void> setSpeed(double v) => _handler.setSpeed(v);
  Future<void> setPitch(double v) => _handler.setPitch(v);
  Future<void> setSkipSilence(bool v) => _handler.setSkipSilence(v);
  Future<void> setVolume(double v) => _handler.setVolume(v);

  Future<void> toggleShuffle() =>
      _handler.setShuffleMode(
        !_state.shuffleMode
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      );

  Future<void> cycleLoop() async {
    final next = _state.loopMode == LoopMode.off
        ? LoopMode.all
        : _state.loopMode == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    await _handler.player.setLoopMode(next);
  }

  Future<void> toggleFavorite() async {
    final s = currentSong;
    if (s == null) return;
    await MusicRepository.instance.toggleFavorite(s);
    notifyListeners();
  }

  bool get isCurrentFavorite {
    final s = currentSong;
    if (s == null) return false;
    return MusicRepository.instance.isFavorite(s.id);
  }

  void openFullPlayer() {
    _showFullPlayer = true;
    notifyListeners();
  }

  void closeFullPlayer() {
    _showFullPlayer = false;
    notifyListeners();
  }
}
