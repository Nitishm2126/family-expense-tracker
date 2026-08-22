import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/services/local_cache_service.dart';
import '../models/income_model.dart';
import 'dashboard_provider.dart';
import 'service_providers.dart';

class IncomeState {
  final List<IncomeModel> incomes;
  final bool isLoading;
  final String? errorMessage;

  const IncomeState({
    this.incomes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  IncomeState copyWith({
    List<IncomeModel>? incomes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  double get total => incomes.fold(0.0, (sum, i) => sum + i.amount);
}

class IncomeController extends StateNotifier<IncomeState> {
  final Ref ref;
  IncomeController(this.ref) : super(const IncomeState()) {
    loadIncomes();
  }

  Future<void> loadIncomes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final cached = LocalCacheService.getCachedIncomes();
    if (cached.isNotEmpty) {
      state = state.copyWith(
        incomes: cached.map(IncomeModel.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    }

    try {
      final api = ref.read(supabaseServiceProvider);
      final raw = await api.getIncomes();
      await LocalCacheService.cacheIncomes(raw);
      final list = raw.map(IncomeModel.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(incomes: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: cached.isEmpty ? e.toString() : null,
      );
    }
  }

  Future<bool> addIncome({
    String? memberId,
    required String receivedBy,
    required String source,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    final localId = const Uuid().v4();
    final income = IncomeModel(
      id: localId,
      memberId: memberId,
      receivedBy: receivedBy,
      source: source,
      description: description,
      amount: amount,
      date: date,
      createdAt: DateTime.now(),
    );
    try {
      final api = ref.read(supabaseServiceProvider);
      await api.addIncome(income.toJson());
      // Reload from backend so list reflects exactly what the server has.
      await loadIncomes();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateIncome(IncomeModel updated) async {
    try {
      final api = ref.read(supabaseServiceProvider);
      await api.updateIncome(updated.id, updated.toJson());
      await loadIncomes();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteIncome(String id) async {
    final previous = state.incomes;
    state = state.copyWith(incomes: previous.where((i) => i.id != id).toList());
    try {
      final api = ref.read(supabaseServiceProvider);
      await api.deleteIncome(id);
      await loadIncomes();
      return true;
    } catch (e) {
      state = state.copyWith(incomes: previous, errorMessage: e.toString());
      return false;
    }
  }
}

final incomeControllerProvider =
    StateNotifierProvider<IncomeController, IncomeState>((ref) => IncomeController(ref));

