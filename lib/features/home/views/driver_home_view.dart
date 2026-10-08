import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../kyc/view_models/kyc_view_model.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../../data/services/socket_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/location_foreground_service.dart';
import '../view_models/city_view_model.dart';
import 'package:geolocator/geolocator.dart';

final isOnlineProvider = StateProvider<bool>((ref) => false);

class DriverHomeView extends ConsumerStatefulWidget {
  const DriverHomeView({super.key});

  @override
  ConsumerState<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends ConsumerState<DriverHomeView> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _earnings;
  bool _loadingEarnings = false;
  String? _riderId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadEarnings();
    _initSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycViewModelProvider.notifier).loadStatus();
      ref.read(profileViewModelProvider.notifier).loadProfile();
      ref.read(cityViewModelProvider.notifier).fetchCities().then((_) {
        ref.read(cityViewModelProvider.notifier).checkCurrentLocationServiceAvailability();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    _riderId = await StorageService.getUserId();
    final socketService = SocketService();
    socketService.connect();

    Future.delayed(const Duration(seconds: 1), () {
      if (_riderId != null) {
        socketService.joinRiderRoom(_riderId!);
      }
    });

    socketService.onNewRideRequest((data) {
      if (!mounted) return;
      _showRideRequestPopup(data);
    });
  }

  void _showRideRequestPopup(Map<String, dynamic> data) {
    try {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.glass,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (_) {}
    HapticFeedback.vibrate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RideRequestPopupDialog(
        data: data,
        onResponse: (rideId, accept) {
          try {
            FlutterRingtonePlayer().stop();
          } catch (_) {}
          Navigator.of(ctx).pop();
          _handleRideResponse(rideId, accept);
        },
      ),
    ).then((_) {
      try {
        FlutterRingtonePlayer().stop();
      } catch (_) {}
    });
  }

  Future<void> _handleRideResponse(String rideId, bool accept) async {
    try {
      final repo = ref.read(riderRepositoryProvider);
      if (accept) {
        await repo.acceptRide(rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride Accepted!'), backgroundColor: AppColors.successGreen),
          );
          context.push('/ride-active/$rideId');
        }
      } else {
        await repo.rejectRide(rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride Rejected'), backgroundColor: AppColors.infoBlue),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _loadEarnings() async {
    setState(() => _loadingEarnings = true);
    try {
      final repo = ref.read(riderRepositoryProvider);
      final data = await repo.getEarnings();
      setState(() => _earnings = data);
    } catch (_) {}
    setState(() => _loadingEarnings = false);
  }

  void _showServiceUnavailableDialog(BuildContext context) {
    const message = 'In this area service is not available. Coming soon.';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        duration: Duration(seconds: 4),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wrong_location_rounded, color: AppColors.errorRed, size: 28),
            SizedBox(width: 10),
            Text(
              'Service Unavailable',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        content: const Text(
          message,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.bodyText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOnline(bool current) async {
    final kycStatus = ref.read(kycViewModelProvider).kycStatus;
    if (kycStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️Your KYC is not yet approved. Please wait for admin approval.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    try {
      final repo = ref.read(riderRepositoryProvider);
      final newStatus = !current;

      if (newStatus) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryPink),
                    SizedBox(height: 16),
                    Text(
                      'Checking service area...',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final cityNotifier = ref.read(cityViewModelProvider.notifier);
        final isAvailable = await cityNotifier.checkCurrentLocationServiceAvailability();

        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (!isAvailable) {
          if (mounted) {
            _showServiceUnavailableDialog(context);
          }
          return;
        }
      }

      await repo.toggleOnlineStatus(isOnline: newStatus);
      ref.read(isOnlineProvider.notifier).state = newStatus;

      if (!newStatus) {
        SocketService().emitStatusChanged(_riderId!, newStatus);
      }

      if (newStatus) {
        if (_riderId != null) {
          final started = await LocationForegroundService.start(_riderId!);
          if (!started && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to go online.'),
                backgroundColor: AppColors.errorRed,
              ),
            );
            await repo.toggleOnlineStatus(isOnline: false);
            if (mounted) {
              ref.read(isOnlineProvider.notifier).state = false;
            }
          } else {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            SocketService().emitStatusChanged(
              _riderId!,
              newStatus,
              lat: position.latitude,
              lng: position.longitude,
            );
          }
        }
      } else {
        await LocationForegroundService.stop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final kycState = ref.watch(kycViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final cityState = ref.watch(cityViewModelProvider);
    final isKycApproved = kycState.kycStatus == 'approved';
    final riderName = profileState.name.isNotEmpty ? profileState.name : 'Rider';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // Profile Avatar
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                      backgroundImage: profileState.profileImage != null && profileState.profileImage!.isNotEmpty
                          ? CachedNetworkImageProvider(AppConstants.getFullImageUrl(profileState.profileImage))
                          : null,
                      child: profileState.profileImage == null || profileState.profileImage!.isEmpty
                          ? const Icon(Icons.person, color: AppColors.primaryPink, size: 22)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Greeting & Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.lightGray,
                          ),
                        ),
                        Text(
                          riderName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Online/Offline Status Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.onlineGreen.withValues(alpha: 0.1)
                          : AppColors.offlineGray.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnline ? AppColors.onlineGreen : AppColors.offlineGray,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? AppColors.onlineGreen : AppColors.offlineGray,
                              shape: BoxShape.circle,
                              boxShadow: isOnline
                                  ? [
                                      BoxShadow(
                                        color: AppColors.onlineGreen.withValues(alpha: 0.6),
                                        blurRadius: 4 * _pulseController.value,
                                        spreadRadius: 2 * _pulseController.value,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isOnline ? AppColors.onlineGreen : AppColors.offlineGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPink,
                onRefresh: () async {
                  await _loadEarnings();
                  ref.read(profileViewModelProvider.notifier).loadProfile();
                  await ref.read(cityViewModelProvider.notifier).fetchCities();
                  await ref.read(cityViewModelProvider.notifier).checkCurrentLocationServiceAvailability();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Service Area Unavailable Banner
                      if (cityState.isCurrentLocationInService == false)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.location_off_rounded, color: AppColors.errorRed, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'In this area service is not available. Coming soon.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // KYC Pending Banner
                      if (kycState.kycStatus != null && !isKycApproved)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppColors.warningAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.warningAmber),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pending_actions_rounded, color: AppColors.warningAmber, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'KYC Approval Required',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.warningAmber,
                                      ),
                                    ),
                                    const Text(
                                      'You cannot go online until your KYC is approved.',
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/kyc/pending'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Check Status →',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.primaryPink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // HERO DUTY TOGGLE CARD
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: isOnline
                              ? const LinearGradient(
                                  colors: [Color(0xFFE8F8F5), Color(0xFFD1F2EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isOnline ? const Color(0xFFA3E4D7) : const Color(0xFFD1C4E9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline ? AppColors.onlineGreen : AppColors.secondaryPurple).withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOnline ? 'ON DUTY' : 'OFF DUTY',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isOnline ? AppColors.onlineGreen : AppColors.secondaryPurple,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      isOnline ? 'Ready for Rides' : 'Not Accepting Rides',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),

                                // Status Pulse Circle Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? AppColors.onlineGreen.withValues(alpha: 0.12)
                                        : AppColors.secondaryPurple.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isOnline ? Icons.electric_bike_rounded : Icons.power_settings_new_rounded,
                                    color: isOnline ? AppColors.onlineGreen : AppColors.secondaryPurple,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Main Large Interactive Toggle Button
                            GestureDetector(
                              onTap: () => _toggleOnline(isOnline),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: isOnline
                                        ? AppColors.onlineGradient
                                        : const LinearGradient(
                                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                                          ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isOnline ? AppColors.onlineGreen : AppColors.primaryPink).withValues(
                                          alpha: isOnline ? 0.4 + (_pulseController.value * 0.2) : 0.3,
                                        ),
                                        blurRadius: 20 + (_pulseController.value * 8),
                                        spreadRadius: isOnline ? 4 * _pulseController.value : 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isOnline ? Icons.pause_rounded : Icons.power_settings_new_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOnline ? 'OFFLINE' : 'GO ONLINE',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              isOnline
                                  ? 'Searching for nearby passenger requests...'
                                  : 'Tap the button to start receiving rides',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.bodyText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Daily Safety Checklist Button
                      if (isKycApproved && !isOnline)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: kycState.isChecklistUpdatedToday
                              ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Today's Safety Checklist Done",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryPink,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: AppColors.primaryPink, width: 1.5),
                                    ),
                                  ),
                                  icon: const Icon(Icons.checklist_rtl_rounded),
                                  label: const Text(
                                    'Update Daily Safety Checklist',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () => _showDailyChecklistDialog(context, ref),
                                ),
                        ),

                      // STATS SECTION HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Performance Summary",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/earnings'),
                            child: const Text(
                              'Earnings Details →',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Today's Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: "Today's Rides",
                              value: _loadingEarnings ? '—' : '${_earnings?['summary']?['todayRides'] ?? 0}',
                              icon: Icons.electric_bike_rounded,
                              color: AppColors.infoBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: "Today's Earnings",
                              value: _loadingEarnings ? '—' : '₹${_earnings?['summary']?['todayEarnings'] ?? 0}',
                              icon: Icons.currency_rupee_rounded,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Total Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Rides',
                              value: _loadingEarnings ? '—' : '${_earnings?['summary']?['totalRides'] ?? 0}',
                              icon: Icons.history_rounded,
                              color: AppColors.secondaryPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Earnings',
                              value: _loadingEarnings ? '—' : '₹${_earnings?['summary']?['totalEarnings'] ?? 0}',
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}

void _showDailyChecklistDialog(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _DailyChecklistDialog(),
  );
}

class _DailyChecklistDialog extends ConsumerStatefulWidget {
  const _DailyChecklistDialog();

  @override
  ConsumerState<_DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends ConsumerState<_DailyChecklistDialog> {
  bool _helmet = false;
  bool _firstAid = false;
  bool _sanitary = false;
  bool _battery = false;
  bool _isLoading = false;

  int get _completedCount {
    int count = 0;
    if (_helmet) count++;
    if (_firstAid) count++;
    if (_sanitary) count++;
    if (_battery) count++;
    return count;
  }

  bool get _allChecked => _completedCount == 4;

  void _toggleAll() {
    HapticFeedback.lightImpact();
    final targetState = !_allChecked;
    setState(() {
      _helmet = targetState;
      _firstAid = targetState;
      _sanitary = targetState;
      _battery = targetState;
    });
  }

  Future<void> _submit() async {
    if (!_allChecked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please verify all safety checklist items before submitting.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(riderRepositoryProvider);
      await repo.submitSafetyChecklist(
        helmetAvailable: _helmet,
        firstAidKitAvailable: _firstAid,
        sanitaryPadsAvailable: _sanitary,
        phoneBatteryCheck: _battery,
        faceVerified: true,
      );
      if (mounted) {
        ref.read(kycViewModelProvider.notifier).loadStatus();

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily safety checklist completed successfully!',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _completedCount / 4.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Handle Indicator
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.primaryPink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Safety Checklist',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verify mandatory rider equipment before taking rides',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress Bar and Select All Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Completion: ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _allChecked
                                      ? AppColors.successGreen.withValues(alpha: 0.15)
                                      : AppColors.primaryPink.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_completedCount / 4',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _allChecked ? AppColors.successGreen : AppColors.primaryPink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _toggleAll,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _allChecked ? Icons.deselect_rounded : Icons.select_all_rounded,
                                    size: 16,
                                    color: AppColors.primaryPink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _allChecked ? 'Deselect All' : 'Select All',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: _allChecked ? AppColors.successGreen : AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive Item Cards
                _ChecklistTile(
                  icon: Icons.sports_motorsports_rounded,
                  iconColor: const Color(0xFFE91E63),
                  title: 'Rider & Passenger Helmet',
                  subtitle: 'Clean helmet ready for passenger safety',
                  value: _helmet,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _helmet = v);
                  },
                ),
                const SizedBox(height: 10),

                _ChecklistTile(
                  icon: Icons.medical_services_rounded,
                  iconColor: const Color(0xFFE53935),
                  title: 'First Aid Kit',
                  subtitle: 'Basic medical supplies stored on vehicle',
                  value: _firstAid,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _firstAid = v);
                  },
                ),
                const SizedBox(height: 10),

                _ChecklistTile(
                  icon: Icons.clean_hands_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Sanitary Pads',
                  subtitle: 'Hygiene products available for riders',
                  value: _sanitary,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _sanitary = v);
                  },
                ),
                const SizedBox(height: 10),

                _ChecklistTile(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF00C853),
                  title: 'Phone Battery Check',
                  subtitle: 'Sufficient phone battery (>20%) for navigation',
                  value: _battery,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _battery = v);
                  },
                ),

                const SizedBox(height: 24),

                // Submit Button
                WooshGradientButton(
                  text: 'SUBMIT SAFETY CHECKLIST',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value ? iconColor.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value ? iconColor.withValues(alpha: 0.6) : AppColors.borderLight,
              width: value ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (value)
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else
                const BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: value ? iconColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: value ? iconColor : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: value ? AppColors.darkText : AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Check Mark Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? iconColor : Colors.transparent,
                  border: Border.all(
                    color: value ? iconColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideRequestPopupDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String rideId, bool accept) onResponse;

  const _RideRequestPopupDialog({
    required this.data,
    required this.onResponse,
  });

  @override
  State<_RideRequestPopupDialog> createState() => _RideRequestPopupDialogState();
}

class _RideRequestPopupDialogState extends State<_RideRequestPopupDialog> with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 15;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      } else {
        _timer?.cancel();
        final rideId = (widget.data['rideId'] ?? widget.data['_id'])?.toString() ?? '';
        widget.onResponse(rideId, false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideId = (widget.data['rideId'] ?? widget.data['_id'])?.toString() ?? '';
    final fare = widget.data['fare']?.toString() ?? '0';
    final distance = widget.data['distanceKm']?.toString() ?? widget.data['distance']?.toString() ?? '0';

    String pickupAddr = 'Nearby Pickup';
    if (widget.data['pickup'] is Map && widget.data['pickup']['address'] != null) {
      pickupAddr = widget.data['pickup']['address'].toString();
    } else if (widget.data['pickupAddress'] != null) {
      pickupAddr = widget.data['pickupAddress'].toString();
    }

    String dropAddr = 'Destination';
    if (widget.data['drop'] is Map && widget.data['drop']['address'] != null) {
      dropAddr = widget.data['drop']['address'].toString();
    } else if (widget.data['dropAddress'] != null) {
      dropAddr = widget.data['dropAddress'].toString();
    }

    final double progress = _secondsRemaining / 15.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              color: progress > 0.3 ? AppColors.primaryPink : AppColors.errorRed,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.1).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primaryPink, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW RIDE REQUEST!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primaryPink,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Female Passenger Nearby',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: progress > 0.3 ? AppColors.lightPink : AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: progress > 0.3 ? AppColors.borderPink : AppColors.errorRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: progress > 0.3 ? AppColors.primaryPink : AppColors.errorRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_secondsRemaining}s',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: progress > 0.3 ? AppColors.primaryPink : AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF2C2C4E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x20000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTIMATED FARE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$fare',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.white24,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'DISTANCE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$distance km',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PICKUP LOCATION',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pickupAddr,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 18,
                            width: 2,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DROP-OFF LOCATION',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryPink,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dropAddr,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => widget.onResponse(rideId, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Decline',
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
                      flex: 3,
                      child: WooshGradientButton(
                        text: 'ACCEPT RIDE',
                        icon: Icons.check_circle_rounded,
                        onPressed: () => widget.onResponse(rideId, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
