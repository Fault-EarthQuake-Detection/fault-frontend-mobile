import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/chat_model_type.dart';
import '../../../core/utils/string_similarity.dart'; // [WAJIB IMPORT]

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ChatModelType selectedModel;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.selectedModel = ChatModelType.rag,
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

  // Ambang batas kemiripan (0.85 artinya 85% mirip)
  // Contoh: "Apa itu sesar?" vs "Apa itu sesar" (Mirip > 90%)
  static const double _similarityThreshold = 0.85;

  ChatViewModel(this._repo) : super(ChatState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true);
    final savedMessages = await _repo.loadLocalChat();

    if (savedMessages.isNotEmpty) {
      state = state.copyWith(messages: savedMessages, isLoading: false);
    } else {
      state = state.copyWith(
        messages: [
          ChatMessage(
            text: "Halo! Saya GeoValid Assistant. Riwayat chat tersimpan di perangkat ini.",
            isUser: false,
            timestamp: DateTime.now(),
          )
        ],
        isLoading: false,
      );
    }
  }

  Future<void> startNewChat() async {
    state = state.copyWith(messages: [], isLoading: false);
    await _repo.clearLocalChat();

    final welcomeMsg = ChatMessage(
        text: "Percakapan baru dimulai. Silakan tanya apa saja!",
        isUser: false,
        timestamp: DateTime.now()
    );
    state = state.copyWith(messages: [welcomeMsg]);
    _repo.saveLocalChat(state.messages);
  }

  void switchModel(ChatModelType newModel) {
    if (state.selectedModel == newModel) return;

    final infoMsg = ChatMessage(
      text: "Mode beralih ke: ${newModel.label}",
      isUser: false,
      timestamp: DateTime.now(),
    );

    final newMessages = [...state.messages, infoMsg];
    state = state.copyWith(
      selectedModel: newModel,
      messages: newMessages,
    );
    _repo.saveLocalChat(newMessages);
  }

  // --- LOGIKA UTAMA DISINI ---
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

    // 1. Tampilkan pesan user ke layar dulu
    List<ChatMessage> currentMsgs = [...state.messages, userMsg];
    state = state.copyWith(messages: currentMsgs, isLoading: true);
    _repo.saveLocalChat(currentMsgs);

    // [BARU] 2. Cek apakah ada pertanyaan serupa di history sebelumnya?
    final cachedAnswer = _findSimilarAnswerInHistory(text);

    if (cachedAnswer != null) {
      // JIKA KETEMU DI CACHE LOKAL:
      // Langsung balas tanpa loading, tanpa API.

      // Sedikit delay buatan biar terasa natural (opsional, 500ms)
      await Future.delayed(const Duration(milliseconds: 500));

      final botMsg = ChatMessage(
          text: "$cachedAnswer", // Bisa ditambah "(Cached)" kalau mau debugging
          isUser: false,
          timestamp: DateTime.now()
      );

      currentMsgs = [...state.messages, botMsg];
      state = state.copyWith(messages: currentMsgs, isLoading: false);
      _repo.saveLocalChat(currentMsgs);
      return; // [STOP] Jangan panggil API
    }

    // 3. Jika TIDAK ada di cache, baru panggil API (Lama)
    try {
      final botResponseText = await _repo.sendMessage(text, state.selectedModel);

      final botMsg = ChatMessage(
          text: botResponseText,
          isUser: false,
          timestamp: DateTime.now()
      );

      currentMsgs = [...state.messages, botMsg];
      state = state.copyWith(messages: currentMsgs, isLoading: false);
      _repo.saveLocalChat(currentMsgs);

    } catch (e) {
      final errorMsg = ChatMessage(
        text: "Gagal ($e)",
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      currentMsgs = [...state.messages, errorMsg];
      state = state.copyWith(messages: currentMsgs, isLoading: false);
      _repo.saveLocalChat(currentMsgs);
    }
  }

  // [BARU] Fungsi Pintar Mencari Jawaban Lama
  String? _findSimilarAnswerInHistory(String currentQuestion) {
    // Loop mundur dari pesan terakhir (biar dapat konteks paling baru)
    // Mulai dari length - 2 karena index terakhir adalah pesan user yang barusan dikirim
    for (int i = state.messages.length - 2; i >= 0; i--) {
      final msg = state.messages[i];

      // Kita hanya cek pesan dari USER (isUser == true)
      if (msg.isUser) {
        // Hitung kemiripan
        final similarity = StringSimilarity.calculateSimilarity(msg.text, currentQuestion);

        // Jika kemiripan di atas ambang batas (misal 85%)
        if (similarity >= _similarityThreshold) {
          // Cek apakah pesan SETELAHNYA adalah jawaban BOT?
          if (i + 1 < state.messages.length) {
            final nextMsg = state.messages[i + 1];
            // Pastikan itu jawaban bot & bukan error
            if (!nextMsg.isUser && !nextMsg.isError) {
              return nextMsg.text; // KEMBALIKAN JAWABAN LAMA
            }
          }
        }
      }
    }
    return null; // Tidak ketemu
  }
}

// Providers tetap sama
final chatRepositoryProvider = Provider((ref) => ChatRepository());

final chatViewModelProvider = StateNotifierProvider.autoDispose<ChatViewModel, ChatState>((ref) {
  return ChatViewModel(ref.read(chatRepositoryProvider));
});