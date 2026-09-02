class AuthModel {
  final String userId;
  final String name;
  final String phoneNumber;
  final String role;
  final String accessToken;
  final String refreshToken;

  AuthModel({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return AuthModel(
      userId: user['_id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      phoneNumber: user['phoneNumber']?.toString() ?? '',
      role: user['role']?.toString() ?? 'rider',
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }
}

class KycStatusModel {
  final String status; // pending | under_review | approved | rejected
  final String? rejectionReason;
  final bool hasProfile;
  final String? vehicleNumber;
  final List<UploadedDocument> documents;

  KycStatusModel({
    required this.status,
    this.rejectionReason,
    required this.hasProfile,
    this.vehicleNumber,
    this.documents = const [],
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending' || status == 'under_review';

  factory KycStatusModel.fromJson(Map<String, dynamic> json) {
    // Backend might return the profile directly in the data object, or wrapped in a 'profile' key
    final profile = json.containsKey('profile') ? json['profile'] as Map<String, dynamic> : json;
    
    return KycStatusModel(
      status: profile['kycStatus']?.toString() ?? 'pending',
      rejectionReason: profile['kycRejectionReason']?.toString(),
      hasProfile: profile.isNotEmpty,
      vehicleNumber: profile['vehicleNumber']?.toString(),
      documents: (profile['documents'] as List<dynamic>?)
              ?.map((d) => UploadedDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UploadedDocument {
  final String type;
  final String url;
  final String status;
  final String? rejectionReason;

  UploadedDocument({
    required this.type,
    required this.url,
    required this.status,
    this.rejectionReason,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}
