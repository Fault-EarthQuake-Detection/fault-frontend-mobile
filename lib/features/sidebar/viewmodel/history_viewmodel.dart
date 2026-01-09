import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_repository.dart';

class HistoryState {
  final List<dynamic> fullHistory;
  final List<dynamic> displayHistory;
  final bool isLoading;

  HistoryState({
    this.fullHistory = const [],
    this.displayHistory = const [],
    this.isLoading = true,
  });

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

class HistoryViewModel extends StateNotifier<HistoryState> {
  final HistoryRepository _repo;

  HistoryViewModel(this._repo) : super(HistoryState()) {
    loadMyHistory();
  }

  Future<void> loadMyHistory({bool forceRefresh = false}) async {
    // Loading State Logic
    if (forceRefresh || state.fullHistory.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    try {
      // Data yang diterima dari repo SUDAH di-filter dan SUDAH di-sort
      // Jadi ViewModel tidak perlu kerja berat lagi
      final data = await _repo.getUserHistory();

      state = state.copyWith(
          fullHistory: data,
          displayHistory: data,
          isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("History Error: $e");
    }
  }

  void search(String query) {
    // Logic search tetap di sini (Main Thread) karena biasanya cepat untuk < 100 item.
    // Kalau mau lebih cepat lagi, bisa pindah ke compute, tapi untuk history user biasanya belum perlu.
    if (query.trim().isEmpty) {
      state = state.copyWith(displayHistory: state.fullHistory);
      return;
    }

    final filtered = state.fullHistory.where((item) {
      final title = (item['faultType'] ?? item['fault_type'] ?? "").toString().toLowerCase();
      final status = (item['statusLevel'] ?? item['status_level'] ?? "").toString().toLowerCase();
      final q = query.toLowerCase();
      return title.contains(q) || status.contains(q);
    }).toList();

    state = state.copyWith(displayHistory: filtered);
  }
}

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

final historyViewModelProvider = StateNotifierProvider<HistoryViewModel, HistoryState>((ref) {
  final repo = ref.read(historyRepositoryProvider);
  return HistoryViewModel(repo);
});