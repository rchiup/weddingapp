class SongModel {
  final String id;
  final String title;
  final String artist;
  final String userId;
  final String userName;
  final DateTime createdAt;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory SongModel.fromMap(String id, Map<String, dynamic> data) {
    final createdRaw = data['created_at'];
    final createdAt = createdRaw is String
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();
    return SongModel(
      id: id,
      title: (data['title'] ?? '').toString(),
      artist: (data['artist'] ?? '').toString(),
      userId: (data['user_id'] ?? '').toString(),
      userName: (data['user_name'] ?? '').toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'user_id': userId,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

