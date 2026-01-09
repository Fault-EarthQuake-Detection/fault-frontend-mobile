import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import 'chat_model_type.dart'; // Import Enum tadi

class ChatRepository {

  // Tambahkan parameter modelType
  Future<String> sendMessage(String question, ChatModelType modelType) async {
    try {
      // 1. Tentukan URL berdasarkan Model yang dipilih
      final String urlString = (modelType == ChatModelType.rag)
          ? AppConstants.chatbotRagUrl
          : AppConstants.chatbotGenUrl;

      final url = Uri.parse(urlString);

      // 2. Kirim Request
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "question": question,
        }),
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
}