import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../data/feed_item.dart';

class HomeState {
  final List<FeedItem> feed;
  final bool isLoading;
  final int currentPage;
  final bool isLastPage;

  HomeState({
    this.feed = const [],
    this.isLoading = true,
    this.currentPage = 1,
    this.isLastPage = false,
  });

  HomeState copyWith({
    List<FeedItem>? feed,
    bool? isLoading,
    int? currentPage,
    bool? isLastPage,
  }) {
    return HomeState(
      feed: feed ?? this.feed,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final HomeRepository _repo;

  List<FeedItem> _allDetections = [];
  List<FeedItem> _allBMKG = [];

  HomeViewModel(this._repo) : super(HomeState()) {
    loadFeed(page: 1);
  }

  Future<void> loadFeed({int page = 1, bool isRefresh = false}) async {
    // 1. Tampilkan loading awal (hanya jika bukan refresh tarik layar)
    if (!isRefresh) {
      state = state.copyWith(isLoading: true);
    }

    try {
      // --- TAHAP 1: AMBIL DETEKSI (PRIORITAS UTAMA) ---
      final newDetections = await _repo.fetchDetections(page: page);

      if (page == 1) {
        _allDetections = newDetections;
        // Jangan hapus _allBMKG dulu biar user liat data lama sambil nunggu yang baru (opsional)
        // Tapi untuk fresh start, kita kosongkan atau pertahankan kalau mau.
      } else {
        _allDetections.addAll(newDetections);
      }

      // LANGSUNG UPDATE STATE! Jangan tunggu BMKG.
      // User langsung melihat data deteksi sekarang.
      _updateFeedState(page: page, isLastPage: newDetections.length < 20, isLoading: page == 1);
      // Note: isLoading true di sini artinya "masih ada proses BMKG" khusus page 1

      // --- TAHAP 2: AMBIL BMKG (NYUSUL) ---
      // Hanya ambil BMKG jika di halaman 1
      if (page == 1) {
        // Ambil data BMKG
        final bmkgData = await _repo.fetchBMKG();
        _allBMKG = bmkgData;

        // UPDATE STATE LAGI (Gabungkan Deteksi + BMKG)
        // Matikan loading sepenuhnya
        _updateFeedState(page: page, isLastPage: newDetections.length < 20, isLoading: false);
      } else {
        // Jika page > 1, matikan loading karena tidak fetch BMKG
        state = state.copyWith(isLoading: false);
      }

    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("ViewModel Error: $e");
    }
  }

  // Helper untuk update state agar kodingan rapi
  void _updateFeedState({required int page, required bool isLastPage, required bool isLoading}) {
    final List<FeedItem> combinedFeed = [..._allDetections, ..._allBMKG];

    // Sort setiap kali update
    combinedFeed.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = state.copyWith(
      feed: combinedFeed,
      isLoading: isLoading, // Loading dikontrol dari parameter
      currentPage: page,
      isLastPage: isLastPage,
    );
  }

  Future<void> refresh() async {
    await loadFeed(page: 1, isRefresh: true);
  }

  void nextPage() {
    if (!state.isLastPage && !state.isLoading) {
      loadFeed(page: state.currentPage + 1);
    }
  }

  void prevPage() {
    if (state.currentPage > 1 && !state.isLoading) {
      loadFeed(page: state.currentPage - 1);
    }
  }
}

final homeRepositoryProvider = Provider((ref) => HomeRepository());

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref.read(homeRepositoryProvider));
});