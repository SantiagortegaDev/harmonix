import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Song extends HiveObject {
  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.thumbnailUrl,
    this.streamUrl,
    this.audioStreams,
    this.videoUrl,
    this.lyrics,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.localPath,
    this.lastPlayed,
    this.playCount = 0,
    this.downloadedAt,
  });

  /// ID de YouTube (videoId).
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String? album;

  @HiveField(4)
  final int? durationMs;

  @HiveField(5)
  final String? thumbnailUrl;

  /// URL directa del stream de audio (resuelta vía YtDlpService).
  /// Es mutable para poder actualizarla cuando se resuelve en background.
  @HiveField(6)
  String? streamUrl;

  /// Lista cruda de streams (mantenida por compatibilidad con Hive).
  @HiveField(7)
  List<AudioStream>? audioStreams;

  @HiveField(8)
  final String? videoUrl;

  @HiveField(9)
  String? lyrics;

  @HiveField(10)
  bool isFavorite;

  @HiveField(11)
  bool isDownloaded;

  @HiveField(12)
  String? localPath;

  @HiveField(13)
  DateTime? lastPlayed;

  @HiveField(14)
  int playCount;

  @HiveField(15)
  DateTime? downloadedAt;

  String get durationLabel {
    final ms = durationMs ?? 0;
    final s = (ms / 1000).floor();
    final m = (s / 60).floor();
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? thumbnailUrl,
    String? streamUrl,
    List<AudioStream>? audioStreams,
    String? videoUrl,
    String? lyrics,
    bool? isFavorite,
    bool? isDownloaded,
    String? localPath,
    DateTime? lastPlayed,
    int? playCount,
    DateTime? downloadedAt,
  }) =>
      Song(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        durationMs: durationMs ?? this.durationMs,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        streamUrl: streamUrl ?? this.streamUrl,
        audioStreams: audioStreams ?? this.audioStreams,
        videoUrl: videoUrl ?? this.videoUrl,
        lyrics: lyrics ?? this.lyrics,
        isFavorite: isFavorite ?? this.isFavorite,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        localPath: localPath ?? this.localPath,
        lastPlayed: lastPlayed ?? this.lastPlayed,
        playCount: playCount ?? this.playCount,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
}

@HiveType(typeId: 2)
class AudioStream extends HiveObject {
  AudioStream({
    required this.url,
    required this.mimeType,
    required this.bitrate,
    required this.quality,
  });

  @HiveField(0)
  final String url;
  @HiveField(1)
  final String mimeType;
  @HiveField(2)
  final int bitrate;
  @HiveField(3)
  final String quality;

  factory AudioStream.fromJson(Map<String, dynamic> json) => AudioStream(
        url: json['url'] ?? '',
        mimeType: json['mimeType'] ?? 'audio/mp4',
        bitrate: ((json['bitrate'] ?? 0) as num).toInt(),
        quality: json['quality']?.toString() ?? '',
      );
}
