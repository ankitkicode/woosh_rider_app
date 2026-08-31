import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../view_models/kyc_view_model.dart';
import 'personal_info_step.dart' show stepHeader;

class SafetyChecklistStep extends ConsumerStatefulWidget {
  const SafetyChecklistStep({super.key});

  @override
  ConsumerState<SafetyChecklistStep> createState() => _SafetyChecklistStepState();
}

class _SafetyChecklistStepState extends ConsumerState<SafetyChecklistStep> {
  bool _isLoading = false;

  Future<void> _submit() async {
    final state = ref.read(kycViewModelProvider);
    if (!state.helmetAvailable || !state.firstAidKitAvailable || !state.sanitaryPadsAvailable || !state.phoneBatteryCheck) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please confirm all safety items before proceeding'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(kycViewModelProvider.notifier).submitSafetyChecklist();
      if (mounted) context.go('/kyc/pending');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycViewModelProvider);
    final notifier = ref.read(kycViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        stepHeader(icon: Icons.health_and_safety, title: 'Safety Checklist', subtitle: 'Confirm you are ride-ready'),
        const SizedBox(height: 20),

        // Explanation box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryPink.withValues(alpha: 0.06), AppColors.secondaryPurple.withValues(alpha: 0.03)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.15)),
          ),
          child: const Text(
            '🛡️ Woosh prioritizes the safety of both drivers and passengers. '
            'Please confirm you have all required safety items before your first ride.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.bodyText, height: 1.5),
          ),
        ),

        const SizedBox(height: 24),

        _SafetyItem(
          title: '⛑️ Helmet Available',
          subtitle: 'A certified helmet for you and the passenger',
          value: state.helmetAvailable,
          onChanged: (v) => notifier.updateSafety(helmet: v),
        ),
        _SafetyItem(
          title: '🩺 First Aid Kit',
          subtitle: 'Basic first aid supplies in your bag',
          value: state.firstAidKitAvailable,
          onChanged: (v) => notifier.updateSafety(firstAid: v),
        ),
        _SafetyItem(
          title: '🩸 Sanitary Pads',
          subtitle: 'For passenger emergency needs',
          value: state.sanitaryPadsAvailable,
          onChanged: (v) => notifier.updateSafety(sanitary: v),
        ),
        _SafetyItem(
          title: '🔋 Phone Battery Check',
          subtitle: 'Your phone is sufficiently charged',
          value: state.phoneBatteryCheck,
          onChanged: (v) => notifier.updateSafety(phone: v),
        ),

        // Selfie verified indicator (from previous step)
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.face, color: AppColors.successGreen, size: 22),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✅ Selfie Verification', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
              Text('Your selfie was captured in the previous step', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
            ])),
          ]),
        ),

        const SizedBox(height: 36),

        WooshGradientButton(
          text: 'Submit KYC Application',
          isLoading: _isLoading,
          onPressed: _submit,
        ),

        const SizedBox(height: 16),

        const Center(
          child: Text(
            'KYC review takes 1-2 business days.\nYou\'ll be notified once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _SafetyItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SafetyItem({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? AppColors.successGreen : AppColors.borderLight, width: value ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkText)),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
        activeColor: AppColors.successGreen,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
