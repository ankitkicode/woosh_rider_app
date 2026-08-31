import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_colors.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../../../shared/widgets/document_upload_card.dart';
import '../../view_models/kyc_view_model.dart';
import 'personal_info_step.dart' show stepHeader;

class DocumentsStep extends ConsumerWidget {
  const DocumentsStep({super.key});

  static const _documents = [
    {'key': 'aadhaar', 'title': 'Aadhaar Card', 'subtitle': 'Front & back sides', 'required': true},
    {'key': 'driving_license', 'title': 'Driving License', 'subtitle': 'Valid DL for two-wheelers', 'required': true},
    {'key': 'rc_book', 'title': 'RC Book', 'subtitle': 'Vehicle registration certificate', 'required': true},
    {'key': 'vehicle_insurance', 'title': 'Vehicle Insurance', 'subtitle': 'Valid and not expired', 'required': true},
    {'key': 'puc', 'title': 'PUC Certificate', 'subtitle': 'Pollution Under Control cert.', 'required': true},
    {'key': 'pan', 'title': 'PAN Card', 'subtitle': 'For tax purposes', 'required': false},
    {'key': 'police_verification', 'title': 'Police Verification', 'subtitle': 'Character certificate', 'required': false},
  ];

  Future<void> _handleUpload(BuildContext context, WidgetRef ref, String docKey) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Upload Document', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primaryPink),
            title: const Text('Take Photo', style: TextStyle(fontFamily: 'Poppins')),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.primaryPink),
            title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Poppins')),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    final path = await pickImage(fromCamera: choice == 'camera');
    if (path != null) {
      ref.read(kycViewModelProvider.notifier).addDocument(docKey, path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycViewModelProvider);
    final requiredDone = state.allRequiredDocsUploaded;

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            stepHeader(icon: Icons.description_outlined, title: 'KYC Documents', subtitle: 'Upload clear photos of documents'),
            const SizedBox(height: 8),

            // Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: requiredDone ? AppColors.successGreen.withValues(alpha: 0.08) : AppColors.lightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(requiredDone ? Icons.check_circle : Icons.info_outline,
                    color: requiredDone ? AppColors.successGreen : AppColors.primaryPink, size: 18),
                const SizedBox(width: 8),
                Text(
                  requiredDone
                      ? 'All required documents uploaded!'
                      : '${state.uploadedDocuments.length} of 5 required docs uploaded',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: requiredDone ? AppColors.successGreen : AppColors.primaryPink, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            ..._documents.map((doc) => DocumentUploadCard(
              title: doc['title'] as String,
              subtitle: doc['subtitle'] as String,
              docKey: doc['key'] as String,
              isRequired: doc['required'] as bool,
              uploadedFilePath: state.uploadedDocuments[doc['key']],
              onUpload: () => _handleUpload(context, ref, doc['key'] as String),
            )),

            if (state.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Text(state.error!, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.errorRed, fontSize: 13)),
              ),
            ],
          ]),
        ),
      ),

      // Bottom CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: WooshGradientButton(
          text: requiredDone ? 'Continue to Selfie Verification' : 'Upload Required Documents First',
          isLoading: state.isSubmitting,
          onPressed: requiredDone ? () => ref.read(kycViewModelProvider.notifier).nextStep() : null,
        ),
      ),
    ]);
  }
}
