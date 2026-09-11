import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/rider_repository.dart';

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiServiceProvider));
});

// ViewModel state
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});
  AuthState copyWith({bool? isLoading, String? error}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, error: error);
}

// ViewModel notifier
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final ApiService _api;

  AuthViewModel(this._repo, this._api) : super(const AuthState());

  Future<String?> sendOtp(String phoneNumber, {String action = 'login'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      return await _repo.sendOtp(phoneNumber, action: action);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Returns: 'new_user' | 'approved' | 'kyc_pending_review' | 'kyc_pending'
  Future<String> verifyOtp({required String phoneNumber, required String otp}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repo.verifyOtp(phoneNumber: phoneNumber, otp: otp);
      // ALWAYS save tokens (backend returns them for both new and existing users)
      if (data.containsKey('accessToken')) {
        await _repo.saveAuthFromVerify(data);
      }

      // New user - needs to fill profile
      if (data['isNewUser'] == true) {
        return 'new_user';
      }
      
      // Existing user — check real KYC status from server
      try {
        final riderRepo = RiderRepository(_api);
        final kycStatusModel = await riderRepo.getKycStatus();
        if (kycStatusModel.isApproved) {
          return 'approved';
        } else if (kycStatusModel.status == 'under_review' || kycStatusModel.status == 'rejected') {
          return 'kyc_pending_review';
        } else {
          return 'kyc_pending';
        }
      } catch (_) {
        // Fallback if KYC status fetch fails
        final kycStatus = (data['user'] as Map?)?['kycStatus']?.toString() ??
            (data['riderProfile'] as Map?)?['kycStatus']?.toString();
        if (kycStatus == 'approved') return 'approved';
        if (kycStatus == 'under_review' || kycStatus == 'rejected') return 'kyc_pending_review';
        return 'kyc_pending';
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> register({
    required String phoneNumber,
    required String name,
    required String city,
    String? email,
    required List<Map<String, String>> emergencyContacts,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.register(
        phoneNumber: phoneNumber,
        name: name,
        city: city,
        email: email,
        emergencyContacts: emergencyContacts,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(ref.read(authRepositoryProvider), ref.read(apiServiceProvider)),
);
