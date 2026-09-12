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

  /// Update rider profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? city,
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (city != null) body['city'] = city;
      if (vehicleNumber != null) body['vehicleNumber'] = vehicleNumber;
      if (vehicleModel != null) body['vehicleModel'] = vehicleModel;
      if (vehicleColor != null) body['vehicleColor'] = vehicleColor;

      final response = await _api.post('/rider/profile', data: body);
      final data = ApiService.parseData(response);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return body;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        final body = <String, dynamic>{};
        if (name != null) body['name'] = name;
        if (email != null) body['email'] = email;
        if (gender != null) body['gender'] = gender;
        if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
        if (city != null) body['city'] = city;
        if (vehicleNumber != null) body['vehicleNumber'] = vehicleNumber;
        if (vehicleModel != null) body['vehicleModel'] = vehicleModel;
        if (vehicleColor != null) body['vehicleColor'] = vehicleColor;
        final response = await _api.put('/rider/profile', data: body);
        final data = ApiService.parseData(response);
        if (data is Map<String, dynamic>) {
          return data;
        }
        return body;
      }
      throw ApiService.parseError(e);
    }
  }

  /// Upload rider profile image (multipart upload - field: image)
  Future<Map<String, dynamic>> updateProfileImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: 'profile_image.jpg',
        ),
      });

      final response = await _api.post('/rider/profile-image', formData: formData);
      final data = ApiService.parseData(response);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: 'profile_image.jpg',
          ),
        });
        final response = await _api.post('/rider/profile/image', formData: formData);
        final data = ApiService.parseData(response);
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {};
      }
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

  /// Accept a ride request
  Future<void> acceptRide(String rideId) async {
    try {
      await _api.put('/ride/$rideId/accept');
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Reject a ride request
  Future<void> rejectRide(String rideId) async {
    try {
      await _api.put('/ride/$rideId/reject');
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Get details of a ride
  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    try {
      final response = await _api.get('/ride/$rideId');
      return ApiService.parseData(response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Mark rider as arrived at pickup
  Future<void> markArrived(String rideId) async {
    try {
      await _api.put('/ride/$rideId/arrived');
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Start the ride with OTP
  Future<Map<String, dynamic>> startRide(String rideId, String otp) async {
    try {
      final response = await _api.put('/ride/$rideId/start', data: {'otp': otp});
      return ApiService.parseData(response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Complete the ride
  Future<Map<String, dynamic>> completeRide(String rideId) async {
    try {
      final response = await _api.put('/ride/$rideId/complete');
      return ApiService.parseData(response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }

  /// Confirm cash collected
  Future<void> confirmCashPayment(String rideId) async {
    try {
      await _api.put('/ride/$rideId/confirm-payment');
    } on DioException catch (e) {
      throw ApiService.parseError(e);
    }
  }
}
