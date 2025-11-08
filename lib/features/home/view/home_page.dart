import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'article_card.dart';
import '../../sidebar/view/sidebar_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 18,
              child: const Icon(Icons.person, color: Colors.white),
            ),
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
