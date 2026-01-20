import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // [WAJIB IMPORT INI]

import '../../../core/constants/app_colors.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../data/chat_message.dart';
import '../data/chat_model_type.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatViewModelProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  // Fungsi untuk memunculkan BottomSheet pemilihan model
  void _showModelSelector(BuildContext context, ChatModelType currentModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pilih Model AI", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Pilihan RAG
              _buildModelOption(
                  context,
                  ChatModelType.rag,
                  "GeoValid RAG",
                  "Menjawab berdasarkan data jurnal & dokumen valid.",
                  Icons.library_books,
                  currentModel == ChatModelType.rag
              ),

              const SizedBox(height: 12),

              // Pilihan Generative
              _buildModelOption(
                  context,
                  ChatModelType.generative,
                  "GeoValid Generative",
                  "Menjawab lebih cepat & luas (General Knowledge).",
                  Icons.auto_awesome,
                  currentModel == ChatModelType.generative
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelOption(BuildContext context, ChatModelType type, String title, String desc, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        ref.read(chatViewModelProvider.notifier).switchModel(type);
        Navigator.pop(context); // Tutup bottom sheet
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
                  Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);

    ref.listen(chatViewModelProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        // Title bisa diklik untuk ganti model
        title: GestureDetector(
          onTap: () => _showModelSelector(context, chatState.selectedModel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatState.selectedModel == ChatModelType.rag ? "GeoValid RAG" : "GeoValid Gen",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // [BARU] Tombol New Chat / Reset
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Percakapan Baru',
            onPressed: () {
              // Tampilkan dialog konfirmasi
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text("Mulai Percakapan Baru?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  content: Text("Ini akan menghapus tampilan chat saat ini untuk topik baru.", style: GoogleFonts.poppins()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Panggil fungsi reset di ViewModel
                        ref.read(chatViewModelProvider.notifier).startNewChat();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text("Ya, Mulai Baru", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text("Sedang berpikir...", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Tanya sesuatu...",
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: chatState.isLoading ? null : _handleSend,
                    child: CircleAvatar(
                      backgroundColor: chatState.isLoading ? Colors.grey.shade300 : AppColors.primary,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    // Tentukan warna teks agar kontras
    final textColor = msg.isUser ? Colors.white : (msg.isError ? Colors.red : Colors.black87);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          boxShadow: [if (!msg.isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        // [MODIFIKASI] Gunakan MarkdownBody untuk render teks bold/italic
        child: MarkdownBody(
          data: msg.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            // Normal Text
            p: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
            // Bold Text (**teks**)
            strong: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            // Italic Text (*teks*)
            em: GoogleFonts.poppins(
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
            // List Bullet
            listBullet: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}