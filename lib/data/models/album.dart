import 'package:hive/hive.dart';
import 'song.dart';

@HiveType(typeId: 4)
class Album extends HiveObject {
  Album({
    required this.id,
    required this.name,
    required this.artist,
    this.thumbnailUrl,
    this.year,
    this.songCount,
    this.songs = const [],
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String? thumbnailUrl;

  @HiveField(4)
  final int? year;

  @HiveField(5)
  final int? songCount;

  @HiveField(6)
  List<Song> songs;

  factory Album.fromMap(Map<String, dynamic> json) {
    final url = json['url']?.toString() ?? '';
    final id = url.split('=').last;
    return Album(
      id: id,
      name: json['name'] ?? 'Álbum desconocido',
      artist: json['uploaderName'] ?? '',
      thumbnailUrl: json['thumbnail'],
    );
  }
}
