import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/rider_repository.dart';
import '../../../data/models/auth_model.dart';

// Provider for RiderRepository
final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  // Reuse api service from auth
  return RiderRepository(ApiService());
});

// KYC state - tracks all steps
class KycState {
  final bool isLoading;
  final String? error;
  final String? kycStatus; // pending | under_review | approved | rejected
  final String? rejectionReason;
  final int currentStep; // 1-5
  final bool isSubmitting;

  // Step 1 - Personal
  final String name;
  final String city;
  final String dateOfBirth;

  // Step 2 - Vehicle
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;

  // Step 3 - Documents
  final Map<String, String> uploadedDocuments; // docKey -> filePath

  // Step 4 - Selfie
  final String? selfiePath;

  // Step 5 - Safety
  final bool helmetAvailable;
  final bool firstAidKitAvailable;
  final bool sanitaryPadsAvailable;
  final bool phoneBatteryCheck;

  const KycState({
    this.isLoading = false,
    this.error,
    this.kycStatus,
    this.rejectionReason,
    this.currentStep = 1,
    this.isSubmitting = false,
    this.name = '',
    this.city = '',
    this.dateOfBirth = '',
    this.vehicleNumber = '',
    this.vehicleModel = '',
    this.vehicleColor = '',
    this.uploadedDocuments = const {},
    this.selfiePath,
    this.helmetAvailable = false,
    this.firstAidKitAvailable = false,
    this.sanitaryPadsAvailable = false,
    this.phoneBatteryCheck = false,
  });

  KycState copyWith({
    bool? isLoading, String? error, String? kycStatus, String? rejectionReason,
    int? currentStep, bool? isSubmitting, String? name, String? city,
    String? dateOfBirth, String? vehicleNumber, String? vehicleModel,
    String? vehicleColor, Map<String, String>? uploadedDocuments,
    String? selfiePath, bool? helmetAvailable, bool? firstAidKitAvailable,
    bool? sanitaryPadsAvailable, bool? phoneBatteryCheck,
  }) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      name: name ?? this.name,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      selfiePath: selfiePath ?? this.selfiePath,
      helmetAvailable: helmetAvailable ?? this.helmetAvailable,
      firstAidKitAvailable: firstAidKitAvailable ?? this.firstAidKitAvailable,
      sanitaryPadsAvailable: sanitaryPadsAvailable ?? this.sanitaryPadsAvailable,
      phoneBatteryCheck: phoneBatteryCheck ?? this.phoneBatteryCheck,
    );
  }

  bool get allRequiredDocsUploaded {
    final required = ['aadhaar', 'driving_license', 'rc_book', 'vehicle_insurance', 'puc'];
    return required.every((key) => uploadedDocuments.containsKey(key));
  }
}

class KycViewModel extends StateNotifier<KycState> {
  final RiderRepository _repo;
  KycViewModel(this._repo) : super(const KycState());

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = await _repo.getKycStatus();
      state = state.copyWith(
        isLoading: false,
        kycStatus: status.status,
        rejectionReason: status.rejectionReason,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1, error: null);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1, error: null);
    }
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  // Step 1
  void updatePersonalInfo({String? name, String? city, String? dob}) {
    state = state.copyWith(name: name, city: city, dateOfBirth: dob);
  }

  Future<void> savePersonalInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateProfile(city: state.city, dateOfBirth: state.dateOfBirth);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Step 2
  void updateVehicleInfo({String? number, String? model, String? color}) {
    state = state.copyWith(vehicleNumber: number, vehicleModel: model, vehicleColor: color);
  }

  Future<void> saveVehicleInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateProfile(
        vehicleNumber: state.vehicleNumber,
        vehicleModel: state.vehicleModel,
        vehicleColor: state.vehicleColor,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Step 3 - Add/remove document
  void addDocument(String docKey, String filePath) {
    final docs = Map<String, String>.from(state.uploadedDocuments);
    docs[docKey] = filePath;
    state = state.copyWith(uploadedDocuments: docs);
  }

  void removeDocument(String docKey) {
    final docs = Map<String, String>.from(state.uploadedDocuments);
    docs.remove(docKey);
    state = state.copyWith(uploadedDocuments: docs);
  }

  // Step 4
  void setSelfie(String path) => state = state.copyWith(selfiePath: path);

  // Submit KYC (Step 3+4 combined upload)
  Future<void> submitKyc() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final docs = Map<String, String>.from(state.uploadedDocuments);
      if (state.selfiePath != null) docs['selfie_verification'] = state.selfiePath!;
      await _repo.submitKyc(docs);
      state = state.copyWith(isSubmitting: false, kycStatus: 'under_review');
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  // Step 5 - Safety
  void updateSafety({bool? helmet, bool? firstAid, bool? sanitary, bool? phone}) {
    state = state.copyWith(
      helmetAvailable: helmet,
      firstAidKitAvailable: firstAid,
      sanitaryPadsAvailable: sanitary,
      phoneBatteryCheck: phone,
    );
  }

  Future<void> submitSafetyChecklist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.submitSafetyChecklist(
        helmetAvailable: state.helmetAvailable,
        firstAidKitAvailable: state.firstAidKitAvailable,
        sanitaryPadsAvailable: state.sanitaryPadsAvailable,
        phoneBatteryCheck: state.phoneBatteryCheck,
        faceVerified: state.selfiePath != null,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final kycViewModelProvider = StateNotifierProvider<KycViewModel, KycState>(
  (ref) => KycViewModel(ref.read(riderRepositoryProvider)),
);
