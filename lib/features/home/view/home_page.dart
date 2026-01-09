import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter untuk push

import '../../../l10n/app_localizations.dart';
import '../../navigation/view/main_navigation.dart';
import '../../navigation/viewmodel/navigation_viewmodel.dart';
import '../../sidebar/view/sidebar_drawer.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import '../../../core/constants/app_colors.dart';
import 'feed_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    String displayName = "";
    String? photoUrl;
    userAsync.whenData((userData) {
      if (userData != null) {
        final email = userData['email'] as String? ?? "";
        final metadata = userData['user_metadata'] as Map<String, dynamic>?;
        if (metadata != null) {
          displayName =
              metadata['full_name'] ?? metadata['name'] ?? email.split('@')[0];
          photoUrl = metadata['avatar_url'] ?? metadata['picture'];
        } else {
          displayName = email.split('@')[0];
        }
      }
    });

    final homeState = ref.watch(homeViewModelProvider);
    final homeNotifier = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: SizedBox(
          height: 32,
          child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () =>
            ref.read(bottomNavIndexProvider.notifier).state = 3,
            child: Row(
              children: [
                if (displayName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      displayName.length > 10 ? '${displayName.substring(0, 10)}...' : displayName,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      radius: 16,
                      backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                      child: (photoUrl == null) ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const SidebarDrawer(),

      // [TAMBAHAN] Floating Action Button Chatbot
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chatbot'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),

      body: (homeState.isLoading && homeState.feed.isEmpty)
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await homeNotifier.refresh();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: homeState.feed.isEmpty ? 1 : homeState.feed.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (homeState.feed.isEmpty) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("Belum ada laporan.", style: GoogleFonts.poppins(color: Colors.grey)),
                      TextButton(
                          onPressed: () => homeNotifier.refresh(),
                          child: const Text("Coba Lagi")
                      )
                    ],
                  ),
                ),
              );
            }

            if (index == homeState.feed.length) {
              return _buildPaginationControls(homeState, homeNotifier);
            }

            final item = homeState.feed[index];
            return FeedCard(item: item);
          },
        ),
      ),
    );
  }

  Widget _buildPaginationControls(HomeState state, HomeViewModel notifier) {
    if (state.isLoading && state.feed.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Posisi di tengah
        children: [
          if (state.currentPage > 1) ...[
            _buildCircleNavBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => notifier.prevPage(),
            ),
          ],
          if (state.currentPage > 1 && !state.isLastPage)
            const SizedBox(width: 40),
          if (!state.isLastPage) ...[
            _buildCircleNavBtn(
              icon: Icons.arrow_forward_rounded,
              onTap: () => notifier.nextPage(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleNavBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}