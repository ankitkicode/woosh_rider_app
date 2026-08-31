import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_colors.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryPink,
              unselectedItemColor: AppColors.lightGray,
              selectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet)),
                  label: 'Earnings',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history_outlined)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history)),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
