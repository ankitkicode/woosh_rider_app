import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../view_models/profile_view_model.dart';

class KycDocumentsView extends ConsumerWidget {
  const KycDocumentsView({super.key});

  static Map<String, ({String title, IconData icon})> get _docTypeConfig => {
        'aadhaar': (title: 'Aadhaar Card', icon: Icons.badge_outlined),
        'driving_license': (title: 'Driving License', icon: Icons.card_membership_outlined),
        'pan': (title: 'PAN Card', icon: Icons.credit_card_outlined),
        'rc_book': (title: 'Vehicle RC Book', icon: Icons.description_outlined),
        'vehicle_insurance': (title: 'Vehicle Insurance', icon: Icons.shield_outlined),
        'puc': (title: 'PUC Certificate', icon: Icons.eco_outlined),
        'police_verification': (title: 'Police Verification', icon: Icons.local_police_outlined),
        'selfie_verification': (title: 'Selfie Verification', icon: Icons.face_outlined),
      };

  void _showFullImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16)),
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                        SizedBox(height: 8),
                        Text('Unable to load image', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    final documents = profileState.documents;
    final overallStatus = profileState.kycStatus.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'KYC Documents',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.darkText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : RefreshIndicator(
              color: AppColors.primaryPink,
              onRefresh: () => ref.read(profileViewModelProvider.notifier).loadProfile(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Overall Status Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: overallStatus == 'APPROVED'
                          ? const Color(0xFFE8F5E9)
                          : overallStatus == 'REJECTED'
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: overallStatus == 'APPROVED'
                            ? AppColors.successGreen
                            : overallStatus == 'REJECTED'
                                ? AppColors.errorRed
                                : AppColors.warningAmber,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          overallStatus == 'APPROVED'
                              ? Icons.verified_rounded
                              : overallStatus == 'REJECTED'
                                  ? Icons.cancel_rounded
                                  : Icons.hourglass_top_rounded,
                          color: overallStatus == 'APPROVED'
                              ? AppColors.successGreen
                              : overallStatus == 'REJECTED'
                                  ? AppColors.errorRed
                                  : AppColors.warningAmber,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Status: $overallStatus',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: overallStatus == 'APPROVED'
                                      ? AppColors.successGreen
                                      : overallStatus == 'REJECTED'
                                          ? AppColors.errorRed
                                          : AppColors.warningAmber,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                overallStatus == 'APPROVED'
                                    ? 'All submitted documents are verified.'
                                    : overallStatus == 'REJECTED'
                                        ? 'Some documents were rejected. Please re-upload.'
                                        : 'Verification in progress by Woosh team.',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submitted Documents',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        '${documents.length} Items',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.lightGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (documents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dividerColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.hintGray),
                          const SizedBox(height: 12),
                          const Text(
                            'No Documents Found',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Complete your KYC verification to upload required documents.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
                          ),
                          const SizedBox(height: 20),
                          WooshGradientButton(
                            text: 'Start KYC',
                            onPressed: () => context.go('/kyc'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...documents.map((docItem) {
                      final doc = docItem as Map<String, dynamic>;
                      final typeKey = doc['type']?.toString().toLowerCase() ?? '';
                      final status = doc['status']?.toString().toUpperCase() ?? 'PENDING';
                      final rawUrl = doc['url']?.toString();
                      final fullImageUrl = AppConstants.getFullImageUrl(rawUrl);

                      final config = _docTypeConfig[typeKey] ?? (
                        title: typeKey.replaceAll('_', ' ').toUpperCase(),
                        icon: Icons.description_outlined,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.dividerColor),
                          boxShadow: const [
                            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Item Header
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPink.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(config.icon, color: AppColors.primaryPink, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            config.title,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                          const Text(
                                            'Uploaded for verification',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: AppColors.lightGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusPill(status),
                                  ],
                                ),
                              ),

                              // Image Thumbnail Preview
                              if (fullImageUrl.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showFullImage(context, fullImageUrl, config.title),
                                  child: Container(
                                    height: 160,
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: fullImageUrl,
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2),
                                          ),
                                          errorWidget: (ctx, url, err) => const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_rounded, size: 36, color: AppColors.hintGray),
                                              SizedBox(height: 6),
                                              Text('Image not available', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                                SizedBox(width: 4),
                                                Text('Tap to expand', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 16),

                  if (overallStatus != 'APPROVED')
                    OutlinedButton.icon(
                      onPressed: () => context.go('/kyc'),
                      icon: const Icon(Icons.upload_file_rounded, color: AppColors.primaryPink),
                      label: const Text('Update / Re-submit Documents', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.primaryPink),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    IconData icon;

    if (status == 'APPROVED' || status == 'VERIFIED') {
      bg = AppColors.successGreen.withValues(alpha: 0.1);
      fg = AppColors.successGreen;
      icon = Icons.check_circle_rounded;
    } else if (status == 'REJECTED') {
      bg = AppColors.errorRed.withValues(alpha: 0.1);
      fg = AppColors.errorRed;
      icon = Icons.cancel_rounded;
    } else {
      bg = AppColors.warningAmber.withValues(alpha: 0.1);
      fg = AppColors.warningAmber;
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
