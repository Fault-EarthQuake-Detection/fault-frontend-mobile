import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // [WAJIB IMPORT]
import '../../../core/constants/app_constants.dart';
import 'chat_model_type.dart';
import 'chat_message.dart';

class ChatRepository {
  static const String _storageKey = 'chat_history_local';

  // --- API CALL (KODE LAMA TETAP SAMA) ---
  Future<String> sendMessage(String question, ChatModelType modelType) async {
    try {
      final String urlString = (modelType == ChatModelType.rag)
          ? AppConstants.chatbotRagUrl
          : AppConstants.chatbotGenUrl;

      final url = Uri.parse(urlString);

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"question": question}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['answer'] ?? "Tidak ada jawaban.";
      } else {
        throw "Server Error (${response.statusCode}) pada model ${modelType.id}";
      }
    } catch (e) {
      throw "Gagal terhubung ke ${modelType.label}: $e";
    }
  }

  // --- [BARU] FITUR PENYIMPANAN LOKAL ---

  // 1. Simpan List Pesan ke HP
  Future<void> saveLocalChat(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List<ChatMessage> menjadi List<String> (JSON)
    final List<String> jsonList = messages.map((msg) => jsonEncode(msg.toMap())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  // 2. Ambil List Pesan dari HP
  Future<List<ChatMessage>> loadLocalChat() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_storageKey);

    if (jsonList == null) return [];

    return jsonList
        .map((jsonStr) => ChatMessage.fromMap(jsonDecode(jsonStr)))
        .toList();
  }

  // 3. Hapus Chat (Dipanggil saat Logout atau New Chat)
  Future<void> clearLocalChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}