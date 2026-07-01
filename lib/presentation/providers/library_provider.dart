import 'package:flutter/foundation.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/repositories/music_repository.dart';
import 'package:harmonix/data/services/download_service.dart';

/// Provider para la sección Librería / Descargas / Favoritos / Recientes.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider._();
  static final LibraryProvider instance = LibraryProvider._();

  List<Song> _favorites = [];
  List<Song> _recents = [];
  List<DownloadedSong> _downloads = [];
  List<String> _playlists = [];

  List<Song> get favorites => _favorites;
  List<Song> get recents => _recents;
  List<DownloadedSong> get downloads => _downloads;
  List<String> get playlists => _playlists;

  Future<void> refresh() async {
    _favorites = MusicRepository.instance.favorites;
    _recents = MusicRepository.instance.recents;
    _downloads = DownloadService.instance.downloads;
    _playlists = MusicRepository.instance.playlistNames;
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    await MusicRepository.instance.toggleFavorite(song);
    await refresh();
  }

  Future<void> removeDownload(String videoId) async {
    await DownloadService.instance.remove(videoId);
    await refresh();
  }
}
