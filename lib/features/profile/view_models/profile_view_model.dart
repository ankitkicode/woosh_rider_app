import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kyc/view_models/kyc_view_model.dart';

class ProfileState {
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final String? updateSuccessMessage;
  final Map<String, dynamic>? data;

  ProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.updateSuccessMessage,
    this.data,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    String? error,
    String? updateSuccessMessage,
    Map<String, dynamic>? data,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      updateSuccessMessage: updateSuccessMessage,
      data: data ?? this.data,
    );
  }

  // Getters for convenience
  Map<String, dynamic>? get user => data?['user'] as Map<String, dynamic>?;
  Map<String, dynamic>? get riderProfile => data?['riderProfile'] as Map<String, dynamic>?;

  String get name => user?['name'] as String? ?? '';
  String get email => user?['email'] as String? ?? '';
  String get phone => user?['phoneNumber'] as String? ?? '';
  String get gender => user?['gender'] as String? ?? 'female';
  String get dateOfBirth => user?['dateOfBirth'] as String? ?? '';
  String get city => user?['city'] as String? ?? '';

  String get vehicleNumber => riderProfile?['vehicleNumber'] as String? ?? '';
  String get vehicleModel => riderProfile?['vehicleModel'] as String? ?? '';
  String get vehicleColor => riderProfile?['vehicleColor'] as String? ?? '';
  String? get profileImage => riderProfile?['profileImage'] as String?;
  String get kycStatus => riderProfile?['kycStatus'] as String? ?? 'PENDING';
  num get rating => riderProfile?['rating'] as num? ?? 0;
  num get totalRides => riderProfile?['totalRides'] as num? ?? 0;
  num get walletBalance => riderProfile?['walletBalance'] as num? ?? 0;
  num get totalEarnings => riderProfile?['totalEarnings'] as num? ?? 0;
  List<dynamic> get documents => (riderProfile?['documents'] as List<dynamic>?) ?? [];
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileViewModel(this._ref) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      final data = await repo.getProfile();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String gender,
    required String dateOfBirth,
    required String city,
    required String vehicleNumber,
    required String vehicleModel,
    required String vehicleColor,
  }) async {
    state = state.copyWith(isUpdating: true, error: null, updateSuccessMessage: null);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.updateProfile(
        name: name,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        city: city,
        vehicleNumber: vehicleNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
      );

      // Re-fetch updated profile details from server
      await loadProfile();
      state = state.copyWith(
        isUpdating: false,
        updateSuccessMessage: 'Profile updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadProfileImage(String filePath) async {
    state = state.copyWith(isUpdating: true, error: null, updateSuccessMessage: null);
    try {
      final repo = _ref.read(riderRepositoryProvider);
      await repo.updateProfileImage(filePath);

      // Refresh profile data to load updated image URL
      await loadProfile();
      state = state.copyWith(
        isUpdating: false,
        updateSuccessMessage: 'Profile photo updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(ref);
});
