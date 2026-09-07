import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../kyc/view_models/kyc_view_model.dart';
import '../../../data/services/socket_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/location_foreground_service.dart';

final isOnlineProvider = StateProvider<bool>((ref) => false);

class DriverHomeView extends ConsumerStatefulWidget {
  const DriverHomeView({super.key});

  @override
  ConsumerState<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends ConsumerState<DriverHomeView> {
  Map<String, dynamic>? _earnings;
  bool _loadingEarnings = false;
  String? _riderId;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
    _initSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycViewModelProvider.notifier).loadStatus();
    });
  }

  Future<void> _initSocket() async {
    _riderId = await StorageService.getUserId();
    final socketService = SocketService();
    socketService.connect();

    // Small delay to ensure socket connects before joining
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🚗 New Ride Request!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pickup: ${data['pickup']['address'] ?? 'Nearby'}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              const SizedBox(height: 8),
              Text('Drop: ${data['drop']['address'] ?? 'Destination'}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              const SizedBox(height: 12),
              Text('Distance: ${data['distanceKm']} km', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Fare: ₹${data['fare']}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleRideResponse(data['rideId'] as String, false);
              },
              child: const Text('Reject', style: TextStyle(color: AppColors.errorRed, fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                Navigator.pop(context);
                _handleRideResponse(data['rideId'] as String, true);
              },
              child: const Text('Accept', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRideResponse(String rideId, bool accept) async {
    try {
      final repo = ref.read(riderRepositoryProvider);
      if (accept) {
        await repo.acceptRide(rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Accepted!'), backgroundColor: AppColors.successGreen));
        }
        // TODO: Navigate to active ride view
      } else {
        await repo.rejectRide(rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride Rejected'), backgroundColor: AppColors.infoBlue));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
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

  Future<void> _toggleOnline(bool current) async {
    final kycStatus = ref.read(kycViewModelProvider).kycStatus;
    if (kycStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Your KYC is not yet approved. Please wait for admin approval.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }
    try {
      final repo = ref.read(riderRepositoryProvider);
      final newStatus = !current;
      await repo.toggleOnlineStatus(isOnline: newStatus);
      ref.read(isOnlineProvider.notifier).state = newStatus;

      if (_riderId != null) {
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
            // Revert online status since location is unavailable
            await repo.toggleOnlineStatus(isOnline: false);
            if (mounted) {
              ref.read(isOnlineProvider.notifier).state = false;
            }
          }
        }
      } else {
        await LocationForegroundService.stop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final kycState = ref.watch(kycViewModelProvider);
    final isKycApproved = kycState.kycStatus == 'approved';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: Colors.white,
            child: Row(children: [
              // Online/Offline indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.onlineGreen : AppColors.offlineGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isOnline ? AppColors.onlineGreen : AppColors.offlineGray,
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/woosh_rider_logo.png',
                // height: 30,
                width: 80,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // KYC warning if not approved
                if (kycState.kycStatus != null && !isKycApproved)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.warningAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warningAmber),
                    ),
                    child: Row(children: [
                      const Icon(Icons.pending_actions, color: AppColors.warningAmber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('KYC Pending Approval', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.warningAmber)),
                        const Text('You cannot go online until your KYC is approved.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText)),
                        TextButton(
                          onPressed: () => context.go('/kyc/pending'),
                          child: const Text('Check Status →', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                        ),
                      ])),
                    ]),
                  ),

                // MAIN ONLINE/OFFLINE TOGGLE
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(children: [
                    Text(
                      isOnline ? 'You are Online' : 'You are Offline',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOnline ? 'Waiting for ride requests...' : 'Tap the button to go online',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray),
                    ),
                    const SizedBox(height: 28),

                    // Big toggle button
                    GestureDetector(
                      onTap: () => _toggleOnline(isOnline),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: isOnline ? AppColors.onlineGradient : const LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFF757575)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline ? AppColors.onlineGreen : AppColors.offlineGray).withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isOnline ? Icons.pause : Icons.power_settings_new, color: Colors.white, size: 44),
                          const SizedBox(height: 6),
                          Text(isOnline ? 'Go Offline' : 'Go Online', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                      ),
                    ),

                    if (kycState.kycStatus != null && !isKycApproved) ...[
                      const SizedBox(height: 12),
                      Text('KYC approval required', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.warningAmber.withValues(alpha: 0.8))),
                    ],
                  ]),
                ),

                const SizedBox(height: 24),

                // Daily Safety Checklist Button
                if (isKycApproved && !isOnline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: kycState.isChecklistUpdatedToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.successGreen),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.successGreen),
                                SizedBox(width: 8),
                                Text(
                                  "Today's Safety Checklist Done",
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.successGreen),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryPink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.primaryPink),
                              ),
                            ),
                            icon: const Icon(Icons.checklist_rtl),
                            label: const Text(
                              'Update Daily Safety Checklist',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            onPressed: () => _showDailyChecklistDialog(context, ref),
                          ),
                  ),                // Today's stats
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      title: "Today's Rides",
                      value: _loadingEarnings ? '—' : '${_earnings?['todayRides'] ?? 0}',
                      icon: Icons.electric_bike,
                      color: AppColors.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: "Today's Earnings",
                      value: _loadingEarnings ? '—' : '₹${_earnings?['todayEarnings'] ?? 0}',
                      icon: Icons.currency_rupee,
                      color: AppColors.successGreen,
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Rides',
                      value: _loadingEarnings ? '—' : '${_earnings?['totalRides'] ?? 0}',
                      icon: Icons.history,
                      color: AppColors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Earnings',
                      value: _loadingEarnings ? '—' : '₹${_earnings?['totalEarnings'] ?? 0}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
      ]),
    );
  }
}

void _showDailyChecklistDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => const _DailyChecklistDialog(),
  );
}

class _DailyChecklistDialog extends ConsumerStatefulWidget {
  const _DailyChecklistDialog();

  @override
  ConsumerState<_DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends ConsumerState<_DailyChecklistDialog> {
  bool helmet = false;
  bool firstAid = false;
  bool sanitary = false;
  bool battery = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!helmet || !firstAid || !sanitary || !battery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check all safety items to proceed.'), backgroundColor: AppColors.errorRed),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(riderRepositoryProvider);
      await repo.submitSafetyChecklist(
        helmetAvailable: helmet,
        firstAidKitAvailable: firstAid,
        sanitaryPadsAvailable: sanitary,
        phoneBatteryCheck: battery,
        faceVerified: true,
      );
      if (mounted) {
        // Refresh status so the UI knows it's checked for today
        ref.read(kycViewModelProvider.notifier).loadStatus();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safety checklist updated!'), backgroundColor: AppColors.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFFCEEED), // Light pinkish background matching screenshot
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Safety\nChecklist',
              style: TextStyle(
                fontFamily: 'Poppins', 
                fontSize: 28, 
                fontWeight: FontWeight.w800, 
                height: 1.2,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 24),
            _buildChecklistItem(
              title: '⛑️ Helmet Available',
              value: helmet,
              onChanged: (v) => setState(() => helmet = v ?? false),
            ),
            const SizedBox(height: 12),
            _buildChecklistItem(
              title: '🩺 First Aid Kit',
              value: firstAid,
              onChanged: (v) => setState(() => firstAid = v ?? false),
            ),
            const SizedBox(height: 12),
            _buildChecklistItem(
              title: '🩸 Sanitary Pads',
              value: sanitary,
              onChanged: (v) => setState(() => sanitary = v ?? false),
            ),
            const SizedBox(height: 12),
            _buildChecklistItem(
              title: '🔋 Phone Battery Check',
              value: battery,
              onChanged: (v) => setState(() => battery = v ?? false),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.black54, fontSize: 15)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({required String title, required bool value, required ValueChanged<bool?> onChanged}) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.black54,
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppColors.primaryPink,
        checkColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.black87),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Colors.black54, width: 1.5),
      ),
    );
  }
}
