import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../shared/widgets/kyc_widgets.dart';
import '../view_models/kyc_view_model.dart';
import 'steps/personal_info_step.dart';
import 'steps/vehicle_info_step.dart';
import 'steps/documents_step.dart';
import 'steps/face_verify_step.dart';
import 'steps/safety_checklist_step.dart';

/// Shell wrapper that shows step indicator + content
class KycStepWrapper extends ConsumerWidget {
  const KycStepWrapper({super.key});

  static const _stepLabels = ['Personal', 'Vehicle', 'Documents', 'Selfie', 'Safety'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycViewModelProvider);

    Widget body;
    switch (state.currentStep) {
      case 1: body = const PersonalInfoStep(); break;
      case 2: body = const VehicleInfoStep(); break;
      case 3: body = const DocumentsStep(); break;
      case 4: body = const FaceVerifyStep(); break;
      case 5: body = const SafetyChecklistStep(); break;
      default: body = const PersonalInfoStep();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Driver KYC'),
        leading: state.currentStep > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => ref.read(kycViewModelProvider.notifier).prevStep(),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: KycStepIndicator(
              currentStep: state.currentStep,
              totalSteps: 5,
              stepLabels: _stepLabels,
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}
