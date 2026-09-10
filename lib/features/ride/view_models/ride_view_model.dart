import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kyc/view_models/kyc_view_model.dart'; // for riderRepositoryProvider

class RideState {
  final Map<String, dynamic>? activeRide;
  final bool isLoading;
  final String? error;

  const RideState({
    this.activeRide,
    this.isLoading = false,
    this.error,
  });

  RideState copyWith({
    Map<String, dynamic>? activeRide,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RideState(
      activeRide: activeRide ?? this.activeRide,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RideViewModel extends StateNotifier<RideState> {
  final Ref _ref;
  Timer? _pollingTimer;

  RideViewModel(this._ref) : super(const RideState());

  Future<void> getRideDetails(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      final ride = await repo.getRideDetails(rideId);
      state = state.copyWith(activeRide: ride, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void startPolling(String rideId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollRideDetails(rideId);
    });
  }

  Future<void> _pollRideDetails(String rideId) async {
    try {
      final repo = _ref.read(riderRepositoryProvider);
      final ride = await repo.getRideDetails(rideId);
      state = state.copyWith(activeRide: ride);
    } catch (_) {}
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> markArrived(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.markArrived(rideId);
      await getRideDetails(rideId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> startRide(String rideId, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.startRide(rideId, otp);
      await getRideDetails(rideId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> completeRide(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.completeRide(rideId);
      await getRideDetails(rideId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmCashPayment(String rideId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.confirmCashPayment(rideId);
      state = const RideState(); // Clear state after completion
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final rideViewModelProvider = StateNotifierProvider<RideViewModel, RideState>((ref) {
  return RideViewModel(ref);
});
