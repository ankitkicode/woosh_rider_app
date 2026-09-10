import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import 'package:dio/dio.dart';

class RideHistoryState {
  final List<dynamic> rides;
  final bool isLoading;
  final String? error;
  final String filter;

  const RideHistoryState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
    this.filter = 'All Rides',
  });

  RideHistoryState copyWith({
    List<dynamic>? rides,
    bool? isLoading,
    String? error,
    String? filter,
    bool clearError = false,
  }) {
    return RideHistoryState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

class RideHistoryViewModel extends StateNotifier<RideHistoryState> {
  RideHistoryViewModel() : super(const RideHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ApiService();
      final response = await api.get('/ride/history?limit=50');
      final data = ApiService.parseData(response) as Map<String, dynamic>;
      final rides = data['rides'] as List<dynamic>? ?? [];
      
      state = state.copyWith(rides: rides, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiService.parseError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  List<dynamic> get filteredRides {
    if (state.filter == 'All Rides') return state.rides;
    return state.rides.where((ride) {
      final status = ride['status'] as String? ?? '';
      if (state.filter == 'Completed') return status == 'completed' || status == 'payment_completed';
      if (state.filter == 'Cancelled') return status.contains('cancelled');
      return true;
    }).toList();
  }
}

final rideHistoryViewModelProvider = StateNotifierProvider<RideHistoryViewModel, RideHistoryState>((ref) {
  return RideHistoryViewModel();
});
