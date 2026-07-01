import 'package:hive/hive.dart';
import 'song.dart';

@HiveType(typeId: 5)
class Playlist extends HiveObject {
  Playlist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.uploader,
    this.videoCount,
    this.songs = const [],
    this.isLocal = false,
    this.category,
    this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? thumbnailUrl;

  @HiveField(3)
  final String? uploader;

  @HiveField(4)
  final int? videoCount;

  @HiveField(5)
  List<Song> songs;

  /// True para listas creadas por el usuario dentro de la app.
  @HiveField(6)
  final bool isLocal;

  /// Categoría para las tarjetas de "Playlists del Día".
  @HiveField(7)
  final String? category;

  @HiveField(8)
  final DateTime? createdAt;

  factory Playlist.fromPipedSearchItem(Map<String, dynamic> json) {
    final url = json['url']?.toString() ?? '';
    final id = url.split('=').last;
    return Playlist(
      id: id,
      name: json['name'] ?? 'Playlist sin nombre',
      thumbnailUrl: json['thumbnail'],
      uploader: json['uploaderName'],
      videoCount: json['videos'] != null
          ? int.tryParse(json['videos'].toString())
          : null,
    );
  }
}

/// Categorías predeterminadas para "Playlists del Día" en Home.
class PlaylistCategory {
  PlaylistCategory({
    required this.title,
    required this.gradient,
    required this.icon,
    this.playlistIds = const [],
  });

  final String title;
  final List<int> gradient; // índices en HarmonixColors.playlistGradients
  final int icon; // codeUnit del IconData
  final List<String> playlistIds;
}
