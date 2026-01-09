class ChatMessage {
  final String text;
  final bool isUser; // true = User (Kanan), false = Bot (Kiri)
  final DateTime timestamp;
  final bool isError; // Penanda jika pesan gagal terkirim

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}