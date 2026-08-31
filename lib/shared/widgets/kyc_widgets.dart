import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Shows the step progress bar at the top of each KYC step
class KycStepIndicator extends StatelessWidget {
  final int currentStep; // 1-based
  final int totalSteps;
  final List<String> stepLabels;

  const KycStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNum = index + 1;
            final isCompleted = stepNum < currentStep;
            final isActive = stepNum == currentStep;
            return Expanded(
              child: Row(
                children: [
                  _StepCircle(
                    stepNum: stepNum,
                    isCompleted: isCompleted,
                    isActive: isActive,
                  ),
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.kycStepCompleted : AppColors.kycStepPending,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNum = index + 1;
            final isActive = stepNum == currentStep;
            final isCompleted = stepNum < currentStep;
            return Expanded(
              child: Text(
                stepLabels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'Poppins',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primaryPink
                      : isCompleted
                          ? AppColors.successGreen
                          : AppColors.hintGray,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepNum;
  final bool isCompleted;
  final bool isActive;

  const _StepCircle({
    required this.stepNum,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Widget child;

    if (isCompleted) {
      bgColor = AppColors.kycStepCompleted;
      borderColor = AppColors.kycStepCompleted;
      child = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      bgColor = AppColors.kycStepActive;
      borderColor = AppColors.kycStepActive;
      child = Text(
        '$stepNum',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
      );
    } else {
      bgColor = Colors.white;
      borderColor = AppColors.kycStepPending;
      child = Text(
        '$stepNum',
        style: const TextStyle(color: AppColors.hintGray, fontSize: 12, fontFamily: 'Poppins'),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(child: child),
    );
  }
}

/// Status banner shown on KYC pending screen
class KycStatusBanner extends StatelessWidget {
  final String status;
  final String? rejectionReason;

  const KycStatusBanner({super.key, required this.status, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: config.iconColor, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(
                  rejectionReason != null ? 'Reason: $rejectionReason' : config.subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.bodyText, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _BannerConfig _getConfig() {
    switch (status) {
      case 'approved':
        return _BannerConfig(
          title: 'KYC Approved! 🎉',
          subtitle: 'You can now go online and accept rides.',
          icon: Icons.verified,
          iconColor: AppColors.successGreen,
          bgColor: const Color(0xFFE8F5E9),
          borderColor: AppColors.successGreen,
        );
      case 'rejected':
        return _BannerConfig(
          title: 'KYC Rejected',
          subtitle: 'Please re-submit your documents.',
          icon: Icons.cancel,
          iconColor: AppColors.errorRed,
          bgColor: const Color(0xFFFFEBEE),
          borderColor: AppColors.errorRed,
        );
      default:
        return _BannerConfig(
          title: 'Under Review',
          subtitle: 'Our team is reviewing your documents (1-2 business days).',
          icon: Icons.hourglass_top,
          iconColor: AppColors.warningAmber,
          bgColor: const Color(0xFFFFF8E1),
          borderColor: AppColors.warningAmber,
        );
    }
  }
}

class _BannerConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  _BannerConfig({required this.title, required this.subtitle, required this.icon, required this.iconColor, required this.bgColor, required this.borderColor});
}
