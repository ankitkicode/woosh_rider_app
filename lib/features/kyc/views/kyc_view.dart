import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import 'kyc_step_wrapper.dart';
import '../view_models/kyc_view_model.dart';

// Main KYC orchestrator - shows the right step
class KycView extends ConsumerStatefulWidget {
  const KycView({super.key});

  @override
  ConsumerState<KycView> createState() => _KycViewState();
}

class _KycViewState extends ConsumerState<KycView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycViewModelProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycViewModelProvider);

    // Already approved - go home
    if (state.kycStatus == 'approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
    }

    // Pending or under review - show pending screen
    if (state.kycStatus == 'under_review' && state.currentStep == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/kyc/pending'));
    }

    return const KycStepWrapper();
  }
}
