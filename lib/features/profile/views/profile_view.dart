import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/storage_service.dart';
import '../view_models/profile_view_model.dart';
import 'edit_profile_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Logout Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.errorRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title & Subtitle
            const Text(
              'Log Out of Woosh?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to log out? You will stop receiving ride requests until you log back in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.lightGray,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await StorageService.clearAll();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _openEditProfile(BuildContext context) {
    EditProfileView.showAsBottomSheet(context);
  }

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Picture',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryPink),
                title: const Text('Take Photo', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryPink),
                title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Uploading profile picture...', style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        backgroundColor: AppColors.primaryPink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );

    final success = await ref
        .read(profileViewModelProvider.notifier)
        .uploadProfileImage(pickedFile.path);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Profile photo updated!', style: TextStyle(fontFamily: 'Poppins')),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final errorMsg = ref.read(profileViewModelProvider).error ?? 'Failed to upload image';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
            tooltip: 'Refresh Profile',
            onPressed: () => ref.read(profileViewModelProvider.notifier).loadProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryPink),
            tooltip: 'Edit Profile',
            onPressed: () => _openEditProfile(context),
          ),
        ],
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : state.error != null && state.data == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load profile\n${state.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Poppins', color: AppColors.bodyText),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(profileViewModelProvider.notifier).loadProfile(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryPink,
                  onRefresh: () => ref.read(profileViewModelProvider.notifier).loadProfile(),
                  child: _buildProfileContent(context, ref, state),
                ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, ProfileState state) {
    final name = state.name.isNotEmpty ? state.name : 'Rider';
    final phone = state.phone.isNotEmpty ? state.phone : 'Not provided';
    final email = state.email.isNotEmpty ? state.email : 'No email added';
    final rating = state.rating.toStringAsFixed(1);
    final kycStatus = state.kycStatus.toUpperCase();
    final profileImg = state.profileImage;
    final fullImageUrl = AppConstants.getFullImageUrl(profileImg);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Avatar with Camera Edit badge
                GestureDetector(
                  onTap: () => _pickAndUploadImage(context, ref),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                        backgroundImage: fullImageUrl.isNotEmpty ? CachedNetworkImageProvider(fullImageUrl) : null,
                        child: fullImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 48, color: AppColors.primaryPink)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x20000000), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Details
                Text(name, style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android_outlined, size: 14, color: AppColors.lightGray),
                    const SizedBox(width: 4),
                    Text(phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
                    if (email.isNotEmpty && email != 'No email added') ...[
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: AppColors.lightGray)),
                      const SizedBox(width: 8),
                      const Icon(Icons.email_outlined, size: 14, color: AppColors.lightGray),
                      const SizedBox(width: 4),
                      Text(email, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Status Badges (Rating, KYC status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warningAmber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kycStatus == 'APPROVED'
                            ? AppColors.successGreen.withValues(alpha: 0.1)
                            : AppColors.warningAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kycStatus == 'APPROVED'
                              ? AppColors.successGreen.withValues(alpha: 0.3)
                              : AppColors.warningAmber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            kycStatus == 'APPROVED' ? Icons.verified_rounded : Icons.pending_actions_rounded,
                            color: kycStatus == 'APPROVED' ? AppColors.successGreen : AppColors.warningAmber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kycStatus,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kycStatus == 'APPROVED' ? AppColors.successGreen : AppColors.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Stats Grid Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatTile('Total Rides', '${state.totalRides}', Icons.two_wheeler_rounded, AppColors.primaryPink),
                const SizedBox(width: 12),
                _buildStatTile('Earnings', '₹${state.totalEarnings}', Icons.account_balance_wallet_rounded, AppColors.successGreen),
                const SizedBox(width: 12),
                _buildStatTile('City', state.city.isNotEmpty ? state.city : 'Indore', Icons.location_city_rounded, AppColors.secondaryPurple),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Details Preview Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openEditProfile(context),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryPink),
                      label: const Text(
                        'Edit',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.primaryPink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12, color: AppColors.dividerColor),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.two_wheeler_outlined, 'Model', state.vehicleModel.isNotEmpty ? state.vehicleModel : 'Not set'),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.badge_outlined, 'Number', state.vehicleNumber.isNotEmpty ? state.vehicleNumber : 'Not set'),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.palette_outlined, 'Color', state.vehicleColor.isNotEmpty ? state.vehicleColor : 'Not set'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main Action Menu Items
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.edit_outlined,
                  'Edit Profile',
                  'Update name, email, city & vehicle details',
                  () => _openEditProfile(context),
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                _buildMenuItem(
                  Icons.description_outlined,
                  'KYC Documents',
                  'View & upload verification documents',
                  () => context.push('/kyc-documents'),
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                _buildMenuItem(
                  Icons.support_agent_outlined,
                  'Help & Support',
                  'Contact Woosh support team',
                  () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(
                          children: [
                            Icon(Icons.support_agent_rounded, color: AppColors.primaryPink),
                            SizedBox(width: 10),
                            Text('Help & Support', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                          ],
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('For rider assistance, contact Woosh support:', style: TextStyle(fontFamily: 'Poppins')),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: AppColors.primaryPink),
                                SizedBox(width: 8),
                                Text('+91 1800-WOOSH-RIDER', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.email, size: 16, color: AppColors.primaryPink),
                                SizedBox(width: 8),
                                Text('support@woosh.com', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primaryPink)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.errorRed, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.lightGray,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryPink, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.lightGray,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.hintGray),
        onTap: onTap,
      ),
    );
  }
}
