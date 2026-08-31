import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Save auth tokens after login/signup
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
    await _storage.write(key: AppConstants.userIdKey, value: userId);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  static Future<String?> getUserId() =>
      _storage.read(key: AppConstants.userIdKey);

  static Future<void> saveKycStatus(String status) =>
      _storage.write(key: AppConstants.kycStatusKey, value: status);

  static Future<String?> getKycStatus() =>
      _storage.read(key: AppConstants.kycStatusKey);

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
