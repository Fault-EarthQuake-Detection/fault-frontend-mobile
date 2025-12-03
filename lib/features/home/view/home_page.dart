import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'article_card.dart';
import '../../sidebar/view/sidebar_drawer.dart';
import '../../auth/viewmodel/auth_viewmodel.dart'; // 2. Import AuthViewModel

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    String displayName = "";
    String? photoUrl;

    userAsync.whenData((user) {
      if (user != null) {
        final metadata = user.userMetadata;
        displayName = metadata?['full_name'] ?? metadata?['name'] ?? user.email?.split('@')[0] ?? "User";
        photoUrl = metadata?['avatar_url'] ?? metadata?['picture'];
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD46E46),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/Logo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              if (displayName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    displayName.length > 10
                        ? '${displayName.substring(0, 10)}...'
                        : displayName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Avatar
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: 16,
                    backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                    child: (photoUrl == null)
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const SidebarDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ArticleCard(
            source: "bmkg.go.id",
            title: "Antisipasi Gempa Bumi",
          ),
          ArticleCard(
            source: "tempo.co",
            title: "Zona Merah Sesar Lembang",
          ),
          ArticleCard(
            source: "detik.com",
            title: "Mengenal Sesar Aktif di Jawa Barat",
          ),
          ArticleCard(
            source: "kompas.com",
            title: "Mitigasi Bencana Geologi Sejak Dini",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/chatbot');
        },
        backgroundColor: const Color(0xFFD46E46),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}