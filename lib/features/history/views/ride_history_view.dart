import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';

class RideHistoryView extends StatelessWidget {
  const RideHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Ride History', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFilterTabs(),
          const SizedBox(height: 24),
          _buildRideCard('Today, 10:30 AM', 'Completed', '₹150', 'Ankit Jatav', 'Mumbai Central', 'Andheri West'),
          _buildRideCard('Yesterday, 04:15 PM', 'Completed', '₹220', 'Rohan Sharma', 'Bandra', 'Dadar'),
          _buildRideCard('Yesterday, 09:00 AM', 'Cancelled', '₹0', 'Priya Singh', 'Juhu', 'Versova'),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab('All Rides', true),
          _buildTab('Completed', false),
          _buildTab('Cancelled', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
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
    );
  }

  Widget _buildRideCard(String date, String status, String amount, String passenger, String pickup, String drop) {
    final isCompleted = status == 'Completed';
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
                  Text(passenger, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
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
