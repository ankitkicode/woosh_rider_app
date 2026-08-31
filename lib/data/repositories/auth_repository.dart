import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiService _api;
  AuthRepository(this._api);

  /// Step 1: Send OTP via WhatsApp
  Future<String> sendOtp(String phoneNumber) async {
    try {
      final response = await _api.post(
        '/auth/send-otp',
        data: {'phoneNumber': phoneNumber},
      );
      final data = ApiService.parseData(response);
      return data['otp']?.toString() ?? '';
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Step 2: Verify OTP - returns AuthModel if user exists, null if new user
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await _api.post(
        '/auth/verify-otp',
        data: {'phoneNumber': phoneNumber, 'otp': otp, 'role': 'rider'},
      );
      final data = ApiService.parseData(response);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Register new driver (called after OTP verification for new users)
  Future<void> register({
    required String phoneNumber,
    required String name,
    required String city,
    String? email,
    required List<Map<String, String>> emergencyContacts,
  }) async {
    try {
      await _api.put(
        '/rider/profile',
        data: {
          'name': name,
          'city': city,
          'email': email,
          'emergencyContacts': emergencyContacts,
        },
      );
      // Tokens are already saved during verifyOtp
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Save tokens from OTP verify response (for existing users)
  Future<void> saveAuthFromVerify(Map<String, dynamic> data) async {
    if (data.containsKey('accessToken')) {
      await StorageService.saveTokens(
        accessToken: data['accessToken'].toString(),
        refreshToken: data['refreshToken']?.toString() ?? '',
        userId: (data['user'] as Map?)?['_id']?.toString() ?? '',
      );
    }
  }
}
