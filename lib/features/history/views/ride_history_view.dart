import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/app_colors.dart';
import '../view_models/ride_history_view_model.dart';

class RideHistoryView extends ConsumerStatefulWidget {
  const RideHistoryView({super.key});

  @override
  ConsumerState<RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends ConsumerState<RideHistoryView> {
  void _showRideDetailsModal(BuildContext context, Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed' || status == 'payment_completed';

    final dateStr = ride['createdAt'] as String?;
    final date = dateStr != null
        ? DateFormat('EEE, MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr).toLocal())
        : 'Unknown Date';

    final amount = '₹${ride['finalFare'] ?? ride['estimatedFare'] ?? 0}';
    final passengerName = ride['passenger']?['name'] ?? 'Passenger';
    final passengerPhone = ride['passenger']?['phoneNumber'] ?? 'N/A';

    String pickup = 'Unknown Pickup';
    if (ride['pickup'] is Map && ride['pickup']['address'] != null) {
      pickup = ride['pickup']['address'].toString();
    } else if (ride['pickupAddress'] != null) {
      pickup = ride['pickupAddress'].toString();
    }

    String drop = 'Unknown Drop';
    if (ride['drop'] is Map && ride['drop']['address'] != null) {
      drop = ride['drop']['address'].toString();
    } else if (ride['dropAddress'] != null) {
      drop = ride['dropAddress'].toString();
    }

    final distance = ride['distanceKm']?.toString() ?? ride['distance']?.toString() ?? '—';
    final paymentMethod = ride['paymentMethod']?.toString().toUpperCase() ?? 'CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ride Summary',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.darkText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isCompleted ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isCompleted ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.successGreen : AppColors.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
            ),

            const SizedBox(height: 20),

            // Fare Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Fare',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
                      ),
                      Text(
                        amount,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? AppColors.primaryPink : AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Payment: $paymentMethod',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Passenger Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.lightPink,
                    child: Icon(Icons.person, color: AppColors.primaryPink, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passengerName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Phone: $passengerPhone',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me_rounded, color: AppColors.infoBlue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$distance km',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.infoBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Route Breakdown
            const Text(
              'Route Breakdown',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.darkText),
            ),
            const SizedBox(height: 10),
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
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.my_location_rounded, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PICKUP', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
                            Text(pickup, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.dividerColor),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DROP-OFF', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryPink)),
                            Text(drop, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.primaryPink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Close', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideHistoryViewModelProvider);
    final vm = ref.read(rideHistoryViewModelProvider.notifier);
    final filteredRides = vm.filteredRides;

    // Calculate Summary Stats
    int completedCount = 0;
    double totalEarned = 0;
    for (final ride in state.rides) {
      final status = (ride['status'] as String? ?? '').toLowerCase();
      if (status == 'completed' || status == 'payment_completed') {
        completedCount++;
        final fare = num.tryParse(ride['finalFare']?.toString() ?? ride['estimatedFare']?.toString() ?? '0') ?? 0;
        totalEarned += fare;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Ride History',
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
      ),
      body: state.isLoading && state.rides.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : state.error != null && state.rides.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load history\n${state.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Poppins', color: AppColors.bodyText),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => vm.loadHistory(),
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
                  onRefresh: () => vm.loadHistory(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Summary Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD1C4E9), width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x109C27B0), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryPurple.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, color: AppColors.secondaryPurple, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completedCount Completed Rides',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total Earned: ₹${totalEarned.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Filter Pills
                      _buildFilterTabs(state.filter, vm, state.rides.length),

                      const SizedBox(height: 16),

                      if (filteredRides.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.directions_bike_outlined, size: 48, color: AppColors.hintGray),
                              SizedBox(height: 12),
                              Text(
                                'No Rides Found',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No ride history matches the selected filter.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredRides.map((ride) => _buildRideCard(context, ride)),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterTabs(String currentFilter, RideHistoryViewModel vm, int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTab('All Rides', currentFilter == 'All Rides', () => vm.setFilter('All Rides')),
          _buildTab('Completed', currentFilter == 'Completed', () => vm.setFilter('Completed')),
          _buildTab('Cancelled', currentFilter == 'Cancelled', () => vm.setFilter('Cancelled')),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.dividerColor,
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed' || status == 'payment_completed';

    final dateStr = ride['createdAt'] as String?;
    final date = dateStr != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr).toLocal())
        : 'Unknown Date';

    final amount = '₹${ride['finalFare'] ?? ride['estimatedFare'] ?? 0}';
    final passengerName = ride['passenger']?['name'] ?? 'Passenger';

    String pickup = 'Unknown Pickup';
    if (ride['pickup'] is Map && ride['pickup']['address'] != null) {
      pickup = ride['pickup']['address'].toString();
    } else if (ride['pickupAddress'] != null) {
      pickup = ride['pickupAddress'].toString();
    }

    String drop = 'Unknown Drop';
    if (ride['drop'] is Map && ride['drop']['address'] != null) {
      drop = ride['drop']['address'].toString();
    } else if (ride['dropAddress'] != null) {
      drop = ride['dropAddress'].toString();
    }

    return GestureDetector(
      onTap: () => _showRideDetailsModal(context, ride),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Date & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isCompleted ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? AppColors.successGreen : AppColors.errorRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Passenger Info & Fare Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.lightPink,
                        child: Icon(Icons.person, size: 16, color: AppColors.primaryPink),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          passengerName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? AppColors.primaryPink : AppColors.lightGray,
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.dividerColor),
            ),

            // Pickup Location
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.my_location_rounded, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickup,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dropoff Location
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    drop,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
