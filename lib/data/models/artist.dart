import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class Artist extends HiveObject {
  Artist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
    this.subscribers,
    this.verified = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? thumbnailUrl;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final int? subscribers;

  @HiveField(5)
  final bool verified;

  String get subscribersLabel {
    final s = subscribers ?? 0;
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}K';
    return '$s';
  }

  factory Artist.fromPipedSearchItem(Map<String, dynamic> json) {
    final url = json['url']?.toString() ?? '';
    final id = url.split('/').last;
    return Artist(
      id: id,
      name: (json['name'] ?? 'Artista desconocido').toString(),
      thumbnailUrl: json['thumbnail'],
      subscribers: json['subscribers'] != null
          ? int.tryParse(json['subscribers'].toString())
          : null,
      verified: json['verified'] == true,
    );
  }
}
