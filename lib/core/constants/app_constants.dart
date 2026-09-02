class AppConstants {
  static const String appName = 'Woosh Driver';
  
  // Use 10.0.2.2 for Android Emulator to connect to localhost
  // static const String baseUrl = 'http://10.0.2.2:5001/api/v1'; 
  static const String baseUrl = 'https://wooshride.in/api/v1'; 
  
  // Use your Mac's IP (like 10.169.140.20) ONLY if testing on a PHYSICAL device
  // static const String baseUrl = 'http://10.169.140.20:5001/api/v1';
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String kycStatusKey = 'kyc_status';
  
  // KYC Steps
  static const int totalKycSteps = 5;
  
  // Timeouts
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30;
  
  // Ride request
  static const int rideRequestTimeoutSeconds = 10;
  
  // Female-only notice
  static const String femaleOnlyNotice = 
    'Woosh is a female-only platform.\nBoth drivers and passengers are women.';
}
