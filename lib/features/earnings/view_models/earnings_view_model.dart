import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kyc/view_models/kyc_view_model.dart';

class EarningsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  EarningsState({this.isLoading = false, this.error, this.data});

  EarningsState copyWith({bool? isLoading, String? error, Map<String, dynamic>? data}) {
    return EarningsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class EarningsViewModel extends StateNotifier<EarningsState> {
  final Ref _ref;

  EarningsViewModel(this._ref) : super(EarningsState()) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      final data = await repo.getEarnings();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final earningsViewModelProvider = StateNotifierProvider<EarningsViewModel, EarningsState>((ref) {
  return EarningsViewModel(ref);
});
