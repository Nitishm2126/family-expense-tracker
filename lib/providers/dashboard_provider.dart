import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_summary_model.dart';
import 'service_providers.dart';

class DashboardState {
  final DashboardSummaryModel summary;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    required this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardSummaryModel? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardController(this.ref)
      : super(DashboardState(summary: DashboardSummaryModel.empty())) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(supabaseServiceProvider);
      final raw = await api.getDashboardSummary();
      if (raw != null) {
        final summary = DashboardSummaryModel.fromJson(raw);
        state = state.copyWith(summary: summary, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});

final dashboardSummaryProvider = Provider<DashboardSummaryModel>((ref) {
  return ref.watch(dashboardControllerProvider).summary;
});

final isDashboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardControllerProvider).isLoading;
});

