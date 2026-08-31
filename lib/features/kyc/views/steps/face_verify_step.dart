import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../../../shared/widgets/document_upload_card.dart';
import '../../view_models/kyc_view_model.dart';
import 'personal_info_step.dart' show stepHeader;

class FaceVerifyStep extends ConsumerStatefulWidget {
  const FaceVerifyStep({super.key});

  @override
  ConsumerState<FaceVerifyStep> createState() => _FaceVerifyStepState();
}

class _FaceVerifyStepState extends ConsumerState<FaceVerifyStep> {
  bool _isSubmitting = false;

  Future<void> _takeSelfie() async {
    final path = await pickImage(fromCamera: true);
    if (path != null) {
      ref.read(kycViewModelProvider.notifier).setSelfie(path);
    }
  }

  Future<void> _submitKyc() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(kycViewModelProvider.notifier).submitKyc();
      ref.read(kycViewModelProvider.notifier).nextStep(); // Go to safety checklist
    } catch (e) {
      // Error shown in UI
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycViewModelProvider);
    final hasSelfie = state.selfiePath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        stepHeader(icon: Icons.face, title: 'Selfie Verification', subtitle: 'Take a clear selfie for identity check'),
        const SizedBox(height: 32),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightPink,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderPink),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 Selfie Guidelines', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            ...[
              '✅ Face clearly visible — no sunglasses or mask',
              '✅ Good lighting — avoid shadows on face',
              '✅ Hold camera at eye level',
              '✅ Plain background preferred',
            ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(tip, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.bodyText)),
            )),
          ]),
        ),

        const SizedBox(height: 28),

        // Selfie preview / placeholder
        Center(
          child: GestureDetector(
            onTap: _takeSelfie,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: hasSelfie ? AppColors.successGreen : AppColors.borderPink,
                  width: 3,
                ),
              ),
              child: hasSelfie
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.file(File(state.selfiePath!), fit: BoxFit.cover),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.camera_front, size: 60, color: AppColors.borderPink),
                      const SizedBox(height: 8),
                      const Text('Tap to take\nselfie', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
                    ]),
            ),
          ),
        ),

        const SizedBox(height: 20),
        if (hasSelfie)
          Center(
            child: TextButton.icon(
              onPressed: _takeSelfie,
              icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
              label: const Text('Retake Selfie', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
            ),
          ),

        if (state.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(state.error!, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.errorRed, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 32),

        WooshGradientButton(
          text: hasSelfie ? 'Submit Documents & Selfie' : 'Take Selfie First',
          isLoading: _isSubmitting,
          onPressed: hasSelfie ? _submitKyc : null,
        ),
      ]),
    );
  }
}
