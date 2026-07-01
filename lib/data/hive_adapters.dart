import 'package:flutter/foundation.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:harmonix/data/models/album.dart';
import 'package:harmonix/data/models/artist.dart';
import 'package:harmonix/data/models/playlist.dart';
import 'package:harmonix/data/models/song.dart';
import 'package:harmonix/data/services/cache_service.dart';
import 'package:harmonix/data/services/download_service.dart';
import 'package:hive/hive.dart';

/// Registra manualmente todos los TypeAdapter de Hive.
///
/// En lugar de generar archivos *.g.dart con build_runner, usamos
/// `Hive.registerAdapter` con adaptadores definidos en código. Esto evita
/// el paso de codegen y mantiene el repo más simple.
void registerHiveAdapters() {
  Hive.registerAdapter(_SongAdapter());
  Hive.registerAdapter(_AudioStreamAdapter());
  Hive.registerAdapter(_ArtistAdapter());
  Hive.registerAdapter(_AlbumAdapter());
  Hive.registerAdapter(_PlaylistAdapter());
  Hive.registerAdapter(_CachedAudioAdapter());
  Hive.registerAdapter(_DownloadedSongAdapter());
  HarmonixLogger.instance.debug('Hive adapters registered', tag: 'Hive');
}

// ---- Song ----
class _SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 1;
  @override
  Song read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String?,
      durationMs: fields[4] as int?,
      thumbnailUrl: fields[5] as String?,
      streamUrl: fields[6] as String?,
      audioStreams: (fields[7] as List?)?.cast<AudioStream>(),
      videoUrl: fields[8] as String?,
      lyrics: fields[9] as String?,
      isFavorite: (fields[10] as bool?) ?? false,
      isDownloaded: (fields[11] as bool?) ?? false,
      localPath: fields[12] as String?,
      lastPlayed: fields[13] as DateTime?,
      playCount: (fields[14] as int?) ?? 0,
      downloadedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer.writeByte(16);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.title);
    writer.writeByte(2); writer.write(obj.artist);
    writer.writeByte(3); writer.write(obj.album);
    writer.writeByte(4); writer.write(obj.durationMs);
    writer.writeByte(5); writer.write(obj.thumbnailUrl);
    writer.writeByte(6); writer.write(obj.streamUrl);
    writer.writeByte(7); writer.write(obj.audioStreams);
    writer.writeByte(8); writer.write(obj.videoUrl);
    writer.writeByte(9); writer.write(obj.lyrics);
    writer.writeByte(10); writer.write(obj.isFavorite);
    writer.writeByte(11); writer.write(obj.isDownloaded);
    writer.writeByte(12); writer.write(obj.localPath);
    writer.writeByte(13); writer.write(obj.lastPlayed);
    writer.writeByte(14); writer.write(obj.playCount);
    writer.writeByte(15); writer.write(obj.downloadedAt);
  }
}

class _AudioStreamAdapter extends TypeAdapter<AudioStream> {
  @override
  final int typeId = 2;
  @override
  AudioStream read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return AudioStream(
      url: f[0] as String,
      mimeType: f[1] as String,
      bitrate: (f[2] as num?)?.toInt() ?? 0,
      quality: f[3] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AudioStream obj) {
    writer.writeByte(4);
    writer.writeByte(0); writer.write(obj.url);
    writer.writeByte(1); writer.write(obj.mimeType);
    writer.writeByte(2); writer.write(obj.bitrate);
    writer.writeByte(3); writer.write(obj.quality);
  }
}

class _ArtistAdapter extends TypeAdapter<Artist> {
  @override
  final int typeId = 3;
  @override
  Artist read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Artist(
      id: f[0] as String,
      name: f[1] as String,
      thumbnailUrl: f[2] as String?,
      description: f[3] as String?,
      subscribers: (f[4] as num?)?.toInt(),
      verified: (f[5] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Artist obj) {
    writer.writeByte(6);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.thumbnailUrl);
    writer.writeByte(3); writer.write(obj.description);
    writer.writeByte(4); writer.write(obj.subscribers);
    writer.writeByte(5); writer.write(obj.verified);
  }
}

class _AlbumAdapter extends TypeAdapter<Album> {
  @override
  final int typeId = 4;
  @override
  Album read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Album(
      id: f[0] as String,
      name: f[1] as String,
      artist: f[2] as String,
      thumbnailUrl: f[3] as String?,
      year: (f[4] as num?)?.toInt(),
      songCount: (f[5] as num?)?.toInt(),
      songs: (f[6] as List?)?.cast<Song>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, Album obj) {
    writer.writeByte(7);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.artist);
    writer.writeByte(3); writer.write(obj.thumbnailUrl);
    writer.writeByte(4); writer.write(obj.year);
    writer.writeByte(5); writer.write(obj.songCount);
    writer.writeByte(6); writer.write(obj.songs);
  }
}

class _PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 5;
  @override
  Playlist read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Playlist(
      id: f[0] as String,
      name: f[1] as String,
      thumbnailUrl: f[2] as String?,
      uploader: f[3] as String?,
      videoCount: (f[4] as num?)?.toInt(),
      songs: (f[5] as List?)?.cast<Song>() ?? const [],
      isLocal: (f[6] as bool?) ?? false,
      category: f[7] as String?,
      createdAt: f[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer.writeByte(9);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.thumbnailUrl);
    writer.writeByte(3); writer.write(obj.uploader);
    writer.writeByte(4); writer.write(obj.videoCount);
    writer.writeByte(5); writer.write(obj.songs);
    writer.writeByte(6); writer.write(obj.isLocal);
    writer.writeByte(7); writer.write(obj.category);
    writer.writeByte(8); writer.write(obj.createdAt);
  }
}

class _CachedAudioAdapter extends TypeAdapter<CachedAudio> {
  @override
  final int typeId = 10;
  @override
  CachedAudio read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return CachedAudio(
      videoId: f[0] as String,
      filePath: f[1] as String,
      sizeBytes: (f[2] as num?)?.toInt() ?? 0,
      cachedAt: f[3] as DateTime,
      songTitle: f[4] as String,
      songArtist: f[5] as String,
      thumbnailUrl: f[6] as String?,
      lastAccessed: f[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAudio obj) {
    writer.writeByte(8);
    writer.writeByte(0); writer.write(obj.videoId);
    writer.writeByte(1); writer.write(obj.filePath);
    writer.writeByte(2); writer.write(obj.sizeBytes);
    writer.writeByte(3); writer.write(obj.cachedAt);
    writer.writeByte(4); writer.write(obj.songTitle);
    writer.writeByte(5); writer.write(obj.songArtist);
    writer.writeByte(6); writer.write(obj.thumbnailUrl);
    writer.writeByte(7); writer.write(obj.lastAccessed);
  }
}

class _DownloadedSongAdapter extends TypeAdapter<DownloadedSong> {
  @override
  final int typeId = 11;
  @override
  DownloadedSong read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return DownloadedSong(
      videoId: f[0] as String,
      title: f[1] as String,
      artist: f[2] as String,
      filePath: f[3] as String,
      sizeBytes: (f[4] as num?)?.toInt() ?? 0,
      downloadedAt: f[5] as DateTime,
      thumbnailUrl: f[6] as String?,
      durationMs: (f[7] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedSong obj) {
    writer.writeByte(8);
    writer.writeByte(0); writer.write(obj.videoId);
    writer.writeByte(1); writer.write(obj.title);
    writer.writeByte(2); writer.write(obj.artist);
    writer.writeByte(3); writer.write(obj.filePath);
    writer.writeByte(4); writer.write(obj.sizeBytes);
    writer.writeByte(5); writer.write(obj.downloadedAt);
    writer.writeByte(6); writer.write(obj.thumbnailUrl);
    writer.writeByte(7); writer.write(obj.durationMs);
  }
}
