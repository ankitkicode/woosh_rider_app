import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../view_models/earnings_view_model.dart';

class EarningsView extends ConsumerWidget {
  const EarningsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(earningsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Earnings', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : state.error != null && state.data == null
              ? Center(child: Text('Error: ${state.error}'))
              : _buildEarningsContent(context, ref, state.data),
    );
  }

  Widget _buildEarningsContent(BuildContext context, WidgetRef ref, Map<String, dynamic>? data) {
    final balance = data?['walletBalance'] ?? 0;
    final totalEarnings = data?['totalEarnings'] ?? 0;
    final todayEarnings = data?['todayEarnings'] ?? 0;
    final transactions = (data?['recentTransactions'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: () => ref.read(earningsViewModelProvider.notifier).loadEarnings(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Wallet Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B2D42), Color(0xFF1B1C29)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF2B2D42).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text('Available Balance', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('₹$balance', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2B2D42),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Withdraw Funds', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
                      const SizedBox(height: 4),
                      Text('₹$todayEarnings', style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.successGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Earnings', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
                      const SizedBox(height: 4),
                      Text('₹$totalEarnings', style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.infoBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text('Recent Transactions', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No recent transactions', style: TextStyle(fontFamily: 'Poppins', color: AppColors.lightGray)),
              ),
            )
          else
            ...transactions.map((tx) {
              final isCredit = tx['type'] == 'credit';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCredit ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward, 
                        color: isCredit ? AppColors.successGreen : AppColors.errorRed, 
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['description'] ?? (isCredit ? 'Earnings' : 'Withdrawal'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkText)),
                          const SizedBox(height: 4),
                          Text(tx['status']?.toString().toUpperCase() ?? 'COMPLETED', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.lightGray)),
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}₹${tx['amount']}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isCredit ? AppColors.successGreen : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
