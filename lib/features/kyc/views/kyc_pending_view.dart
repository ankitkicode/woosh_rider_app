import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/kyc_widgets.dart';
import '../view_models/kyc_view_model.dart';

class KycPendingView extends ConsumerStatefulWidget {
  const KycPendingView({super.key});

  @override
  ConsumerState<KycPendingView> createState() => _KycPendingViewState();
}

class _KycPendingViewState extends ConsumerState<KycPendingView> with TickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadStatus();
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    await ref.read(kycViewModelProvider.notifier).loadStatus();
    final status = ref.read(kycViewModelProvider).kycStatus;
    if (status == 'approved' && mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycViewModelProvider);
    final status = state.kycStatus ?? 'under_review';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.06),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: status == 'approved'
                        ? const LinearGradient(colors: [AppColors.successGreen, Color(0xFF66BB6A)])
                        : status == 'rejected'
                            ? const LinearGradient(colors: [AppColors.errorRed, Color(0xFFEF5350)])
                            : AppColors.kycHeaderGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (status == 'approved' ? AppColors.successGreen : AppColors.primaryPink).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    status == 'approved' ? Icons.verified : status == 'rejected' ? Icons.cancel : Icons.hourglass_top,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              status == 'approved' ? 'You\'re Approved! 🎉' : status == 'rejected' ? 'KYC Rejected' : 'KYC Under Review',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              status == 'approved'
                  ? 'Your KYC is verified. You can now go online and start accepting rides!'
                  : status == 'rejected'
                      ? 'Unfortunately, your KYC was rejected. Please review the reason below and re-submit.'
                      : 'Our team is reviewing your documents.\nThis usually takes 1-2 business days.',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.lightGray, height: 1.6),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            KycStatusBanner(status: status, rejectionReason: state.rejectionReason),

            if (status == 'under_review') ...[
              const SizedBox(height: 24),
              // What happens next
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('What happens next?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...[
                    ('1', 'Our team verifies your submitted documents'),
                    ('2', 'Background check is completed'),
                    ('3', 'You receive an SMS/WhatsApp notification'),
                    ('4', 'You can start accepting rides!'),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text(item.$1, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryPink))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.$2, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.bodyText))),
                    ]),
                  )),
                ]),
              ),
            ],

            const SizedBox(height: 32),

            if (status == 'approved')
              WooshGradientButton(text: 'Go to Dashboard', onPressed: () => context.go('/home'))
            else if (status == 'rejected')
              WooshGradientButton(text: 'Re-submit KYC', onPressed: () => context.go('/kyc'))
            else
              OutlinedButton.icon(
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status', style: TextStyle(fontFamily: 'Poppins')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPink,
                  side: const BorderSide(color: AppColors.primaryPink),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
