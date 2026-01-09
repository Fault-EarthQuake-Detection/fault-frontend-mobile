import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/chat_model_type.dart'; // Import Enum

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ChatModelType selectedModel; // [BARU] Simpan model yang dipilih

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.selectedModel = ChatModelType.rag, // Default pakai RAG
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    ChatModelType? selectedModel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final ChatRepository _repo;

  ChatViewModel(this._repo) : super(ChatState()) {
    state = state.copyWith(messages: [
      ChatMessage(
        text: "Halo! Saya GeoValid Assistant. Saat ini menggunakan mode: ${state.selectedModel.label}.",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ]);
  }

  // [BARU] Fungsi Ganti Model
  void switchModel(ChatModelType newModel) {
    if (state.selectedModel == newModel) return;

    // Beri info ke user bahwa model berubah (Opsional, biar keren)
    final infoMsg = ChatMessage(
      text: "Mode beralih ke: ${newModel.label}",
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      selectedModel: newModel,
      messages: [...state.messages, infoMsg],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      // [UPDATE] Kirim model yang sedang dipilih ke repo
      final botResponseText = await _repo.sendMessage(text, state.selectedModel);

      final botMsg = ChatMessage(
          text: botResponseText,
          isUser: false,
          timestamp: DateTime.now()
      );

      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isLoading: false,
      );

    } catch (e) {
      final errorMsg = ChatMessage(
        text: "Gagal ($e)",
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }
}

// Providers
final chatRepositoryProvider = Provider((ref) => ChatRepository());

final chatViewModelProvider = StateNotifierProvider.autoDispose<ChatViewModel, ChatState>((ref) {
  return ChatViewModel(ref.read(chatRepositoryProvider));
});