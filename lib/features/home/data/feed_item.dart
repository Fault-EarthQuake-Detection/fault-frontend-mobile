class FeedItem {
  final String id;
  final String type; // 'news' atau 'detection'
  final String title;
  final String source;
  final DateTime timestamp;
  final String? imageUrl;
  final String? statusLevel;
  final String? url;
  final Map<String, dynamic>? originalData;
  final String? userAvatarUrl;
  final bool isMine; // [BARU] Penanda milik sendiri

  FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.source,
    required this.timestamp,
    this.imageUrl,
    this.statusLevel,
    this.url,
    this.originalData,
    this.userAvatarUrl,
    this.isMine = false,
  });
}