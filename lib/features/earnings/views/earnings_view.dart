import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../view_models/earnings_view_model.dart';

class EarningsView extends ConsumerWidget {
  const EarningsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(earningsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Earnings & Wallet',
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
                          'Failed to load earnings\n${state.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Poppins', color: AppColors.bodyText),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(earningsViewModelProvider.notifier).loadEarnings(),
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
                  onRefresh: () => ref.read(earningsViewModelProvider.notifier).loadEarnings(),
                  child: _buildEarningsContent(context, ref, state.data),
                ),
    );
  }

  Widget _buildEarningsContent(BuildContext context, WidgetRef ref, Map<String, dynamic>? data) {
    final balance = data?['summary']?['walletBalance'] ?? 0;
    final totalEarnings = data?['summary']?['totalEarnings'] ?? 0;
    final todayEarnings = data?['summary']?['todayEarnings'] ?? 0;
    final monthlyEarnings = data?['summary']?['monthlyEarnings'] ?? 0;
    final transactions = (data?['recentTransactions'] as List<dynamic>?) ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Main Lavender Wallet Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD1C4E9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x189C27B0),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryPurple.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.secondaryPurple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Available Balance',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryPurple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'RIDER WALLET',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryPurple,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹$balance',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              WooshGradientButton(
                text: 'Withdraw Funds',
                icon: Icons.payments_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal request initiated!'),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatTile('Today', '₹$todayEarnings', Icons.today_rounded, AppColors.successGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatTile('This Month', '₹$monthlyEarnings', Icons.calendar_month_rounded, AppColors.infoBlue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatTile('Total', '₹$totalEarnings', Icons.insights_rounded, AppColors.secondaryPurple),
            ),
          ],
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                style: AppTextStyles.heading3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${transactions.length} Activity',
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

        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: const Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: AppColors.hintGray),
                SizedBox(height: 10),
                Text(
                  'No recent transactions',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.lightGray),
                ),
              ],
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
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.dividerColor),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
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
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? AppColors.successGreen : AppColors.errorRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['description'] ?? (isCredit ? 'Ride Fare Credit' : 'Withdrawal'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tx['status']?.toString().toUpperCase() ?? 'COMPLETED',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCredit ? AppColors.successGreen : AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isCredit ? '+' : '-'}₹${tx['amount']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isCredit ? AppColors.successGreen : AppColors.darkText,
                    ),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.lightGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
