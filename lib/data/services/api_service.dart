import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(seconds: AppConstants.connectTimeout),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request interceptor - attach JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired - clear storage
            await _storage.deleteAll();
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Convenience methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data, FormData? formData}) {
    return _dio.post(path, data: formData ?? data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  /// Parse the success response data from backend ApiResponse wrapper
  static dynamic parseData(Response response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  /// Extract error message from DioException
  static String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('message')) {
      return data['message'] as String;
    }
    return e.message ?? 'Something went wrong. Please try again.';
  }
}
