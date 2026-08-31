import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/auth_model.dart';

class RiderRepository {
  final ApiService _api;
  RiderRepository(this._api);

  /// Get KYC status + profile details
  Future<KycStatusModel> getKycStatus() async {
    try {
      final response = await _api.get('/rider/kyc/status');
      final data = ApiService.parseData(response);
      final status = KycStatusModel.fromJson(data as Map<String, dynamic>);
      await StorageService.saveKycStatus(status.status);
      return status;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Update rider profile (personal info & vehicle info steps)
  Future<void> updateProfile({
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleColor,
    String? city,
    String? dateOfBirth,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (vehicleNumber != null) body['vehicleNumber'] = vehicleNumber;
      if (vehicleModel != null) body['vehicleModel'] = vehicleModel;
      if (vehicleColor != null) body['vehicleColor'] = vehicleColor;
      if (city != null) body['city'] = city;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      await _api.put('/rider/profile', data: body);
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Submit KYC documents (multipart upload)
  Future<void> submitKyc(Map<String, String> documentPaths) async {
    try {
      final formData = FormData();
      for (final entry in documentPaths.entries) {
        formData.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(entry.value, filename: '${entry.key}.jpg'),
        ));
      }
      await _api.post('/rider/kyc', formData: formData);
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Submit safety checklist (Step 5)
  Future<void> submitSafetyChecklist({
    required bool helmetAvailable,
    required bool firstAidKitAvailable,
    required bool sanitaryPadsAvailable,
    required bool phoneBatteryCheck,
    required bool faceVerified,
  }) async {
    try {
      await _api.put('/rider/safety-checklist', data: {
        'helmetAvailable': helmetAvailable,
        'firstAidKitAvailable': firstAidKitAvailable,
        'sanitaryPadsAvailable': sanitaryPadsAvailable,
        'phoneBatteryCheck': phoneBatteryCheck,
        'faceVerified': faceVerified,
      });
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Toggle online/offline status
  Future<void> toggleOnlineStatus({required bool isOnline}) async {
    try {
      await _api.put('/rider/status', data: {'isOnline': isOnline});
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Get earnings summary
  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await _api.get('/rider/earnings');
      return ApiService.parseData(response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Get full rider profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get('/rider/profile');
      return ApiService.parseData(response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }
}
