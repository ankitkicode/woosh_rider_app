import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../view_models/ride_history_view_model.dart';

class RideHistoryView extends ConsumerStatefulWidget {
  const RideHistoryView({super.key});

  @override
  ConsumerState<RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends ConsumerState<RideHistoryView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideHistoryViewModelProvider);
    final vm = ref.read(rideHistoryViewModelProvider.notifier);
    final filteredRides = vm.filteredRides;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Ride History', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.isLoading && state.rides.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : state.error != null && state.rides.isEmpty
              ? Center(child: Text('Error: ${state.error}'))
              : RefreshIndicator(
                  color: AppColors.primaryPink,
                  onRefresh: () => vm.loadHistory(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildFilterTabs(state.filter, vm),
                      const SizedBox(height: 24),
                      if (filteredRides.isEmpty)
                        const Center(child: Text('No rides found.', style: TextStyle(color: AppColors.lightGray)))
                      else
                        ...filteredRides.map((ride) => _buildRideCard(ride)).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterTabs(String currentFilter, RideHistoryViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
      child: Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryPink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primaryPink : AppColors.dividerColor),
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

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed' || status == 'payment_completed';
    
    final dateStr = ride['createdAt'] as String?;
    final date = dateStr != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr).toLocal()) : 'Unknown Date';
    
    final amount = '₹${ride['finalFare'] ?? ride['estimatedFare'] ?? 0}';
    final passengerName = ride['passenger']?['name'] ?? 'Passenger';
    final pickup = ride['pickup']?['address'] ?? 'Unknown Pickup';
    final drop = ride['drop']?['address'] ?? 'Unknown Drop';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.successGreen : AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: AppColors.scaffoldBg, child: const Icon(Icons.person, size: 16, color: AppColors.lightGray)),
                  const SizedBox(width: 10),
                  Text(passengerName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                ],
              ),
              Text(amount, style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: isCompleted ? AppColors.primaryPink : AppColors.lightGray)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.dividerColor)),
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: AppColors.lightGray),
              const SizedBox(width: 8),
              Expanded(child: Text(pickup, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primaryPink),
              const SizedBox(width: 8),
              Expanded(child: Text(drop, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }
}
