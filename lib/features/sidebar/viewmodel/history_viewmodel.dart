import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/history_repository.dart';

// State Class
class HistoryState {
  final List<dynamic> fullHistory;    // Master Data (Semua data dari API)
  final List<dynamic> displayHistory; // Data untuk UI (Hasil Search/Filter)
  final bool isLoading;

  HistoryState({
    this.fullHistory = const [],
    this.displayHistory = const [],
    this.isLoading = true,
  });

  // CopyWith helper untuk update state parsial
  HistoryState copyWith({
    List<dynamic>? fullHistory,
    List<dynamic>? displayHistory,
    bool? isLoading,
  }) {
    return HistoryState(
      fullHistory: fullHistory ?? this.fullHistory,
      displayHistory: displayHistory ?? this.displayHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ViewModel Class
class HistoryViewModel extends StateNotifier<HistoryState> {
  final HistoryRepository _repo;

  HistoryViewModel(this._repo) : super(HistoryState()) {
    loadMyHistory();
  }

  // Load data awal
  Future<void> loadMyHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repo.getUserHistory();

      // Sort: Terbaru di atas
      data.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? a['created_at'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['createdAt'] ?? b['created_at'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      // Simpan ke KEDUA list (Master & Display)
      state = state.copyWith(
          fullHistory: data,
          displayHistory: data,
          isLoading: false
      );
    } catch (e) {
      print("ViewModel Error: $e");
      state = state.copyWith(
          fullHistory: [],
          displayHistory: [],
          isLoading: false
      );
    }
  }

  // Fitur Search Lokal (Fix: Filter dari fullHistory)
  void search(String query) {
    if (query.trim().isEmpty) {
      // Jika kosong, kembalikan ke list penuh
      state = state.copyWith(displayHistory: state.fullHistory);
      return;
    }

    final filtered = state.fullHistory.where((item) {
      final title = (item['faultType'] ?? item['fault_type'] ?? "").toString().toLowerCase();
      final status = (item['statusLevel'] ?? item['status_level'] ?? "").toString().toLowerCase();
      final q = query.toLowerCase();

      return title.contains(q) || status.contains(q);
    }).toList();

    // Update HANYA displayHistory
    state = state.copyWith(displayHistory: filtered);
  }
}

// --- PROVIDERS ---

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

// [FIX 1] Gunakan .autoDispose agar state hancur saat Logout/Ganti Halaman
final historyViewModelProvider = StateNotifierProvider<HistoryViewModel, HistoryState>((ref) {
  final repo = ref.read(historyRepositoryProvider);
  return HistoryViewModel(repo);
});