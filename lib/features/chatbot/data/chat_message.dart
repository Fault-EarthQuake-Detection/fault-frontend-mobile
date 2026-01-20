class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  // [BARU] Mengubah Object ke Map (untuk disimpan)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(), // Simpan waktu sebagai String
      'isError': isError,
    };
  }

  // [BARU] Mengubah Map ke Object (untuk dibaca kembali)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isError: map['isError'] ?? false,
    );
  }
}