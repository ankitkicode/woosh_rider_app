import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/rider_repository.dart';
import '../../../core/app_colors.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      context.go('/login');
      return;
    }

    // Check KYC status
    try {
      final repo = RiderRepository(ApiService());
      final kycStatus = await repo.getKycStatus();
      if (!mounted) return;
      if (kycStatus.isApproved) {
        context.go('/home');
      } else if (kycStatus.status == 'under_review' || kycStatus.status == 'rejected') {
        context.go('/kyc/pending');
      } else {
        // 'pending' means they haven't submitted KYC documents yet
        context.go('/kyc');
      }
    } catch (_) {
      // If error checking KYC, go to KYC screen
      if (mounted) context.go('/kyc');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.electric_bike, color: Colors.white, size: 58),
              ),
              const SizedBox(height: 20),
              const Text(
                'Woosh',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
              ),
              const Text(
                'Driver Portal',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.white70, letterSpacing: 2),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
