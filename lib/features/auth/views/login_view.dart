import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../view_models/auth_view_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isPhoneStep = true; // true = phone input, false = OTP input
  bool _isLoading = false;
  String? _errorText;
  int _resendTimer = 0;
  String _phone = '';
  String? _receivedOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _errorText = 'Please enter a valid 10-digit mobile number');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(phone);
      _phone = phone;
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;

      // Auto-fill OTP if test OTP received
      if (_receivedOtp != null && _receivedOtp!.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = _receivedOtp![i];
        }
      }

      setState(() {
        _isPhoneStep = false;
        _resendTimer = 30;
      });
      _startResendTimer();
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), _countdown);
  }

  void _countdown() {
    if (!mounted) return;
    setState(() {
      if (_resendTimer > 0) _resendTimer--;
    });
    if (_resendTimer > 0) {
      Future.delayed(const Duration(seconds: 1), _countdown);
    }
  }

  Future<void> _resendOtp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _resendTimer = 30;
      _errorText = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(_phone);
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;

      if (_receivedOtp != null && _receivedOtp!.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = _receivedOtp![i];
        }
      }

      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP re-sent successfully via WhatsApp'),
            backgroundColor: Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _errorText = 'Please enter the complete 6-digit OTP');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final result = await notifier.verifyOtp(phoneNumber: _phone, otp: _otp);
      if (!mounted) return;

      if (result == 'new_user') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New driver! Please complete registration.'),
            backgroundColor: AppColors.primaryPink,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) context.go('/register');
        });
      } else if (result == 'approved') {
        context.go('/home');
      } else if (result == 'kyc_pending_review') {
        context.go('/kyc/pending');
      } else if (result == 'kyc_pending') {
        context.go('/kyc');
      } else {
        context.go('/kyc/pending');
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleOtpInput(String value, int index) {
    if (_errorText != null) setState(() => _errorText = null);

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _otpFocusNodes[5].unfocus();
        _verifyOtp();
      } else {
        _otpFocusNodes[digits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    if (_otp.length == 6) {
      _verifyOtp();
    }
  }

  void _goBackToPhone() {
    setState(() {
      _isPhoneStep = true;
      _errorText = null;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF0F5), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isPhoneStep ? _buildPhoneSection() : _buildOtpSection(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Phone Entry Section ────────────────────────────────────────────
  Widget _buildPhoneSection() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo & Header
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/woosh_rider_logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primaryPink,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Woosh Driver',
                style: AppTextStyles.heading2,
              ),
              const Text(
                'Female Driver Service Portal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.lightGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Female-only Community Safety Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPink.withValues(alpha: 0.08),
                AppColors.secondaryPurple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.female_rounded, color: AppColors.primaryPink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppConstants.femaleOnlyNotice,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.bodyText,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Please enter your registered WhatsApp number.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray),
        ),

        const SizedBox(height: 20),

        // Phone Input
        const Text(
          'WhatsApp Number',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Text(
                '🇮🇳 +91',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.darkText),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  counterText: '',
                  errorText: _errorText,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.chat_rounded, size: 14, color: Color(0xFF25D366)),
            SizedBox(width: 6),
            Text(
              'OTP will be sent to your WhatsApp number',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
            ),
          ],
        ),

        const SizedBox(height: 28),

        WooshGradientButton(
          text: 'Send OTP',
          isLoading: _isLoading,
          icon: Icons.send_rounded,
          onPressed: _sendOtp,
        ),

        const SizedBox(height: 28),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("New driver? ", style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: const Text(
                  'Register as Driver →',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── OTP Entry Section ──────────────────────────────────────────────
  Widget _buildOtpSection() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back / Change Number Button
        InkWell(
          onTap: _goBackToPhone,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primaryPink),
                const SizedBox(width: 6),
                Text(
                  'Change Number (+91 $_phone)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPink,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // WhatsApp Success Badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OTP sent via WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF25D366),
                      ),
                    ),
                    Text(
                      'Sent to +91 $_phone',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text('Enter Verification Code', style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text(
          'Enter the 6-digit OTP code sent to your mobile',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray),
        ),

        const SizedBox(height: 24),

        // 6 OTP Box Inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: AppColors.darkText,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
                  ),
                ),
                onChanged: (v) => _handleOtpInput(v, index),
              ),
            );
          }),
        ),

        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 28),

        WooshGradientButton(
          text: 'Verify & Login',
          isLoading: _isLoading,
          icon: Icons.check_circle_rounded,
          onPressed: _verifyOtp,
        ),

        const SizedBox(height: 20),

        // Resend Timer Row
        Center(
          child: _resendTimer > 0
              ? Text(
                  'Resend OTP in ${_resendTimer}s',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray, fontWeight: FontWeight.w500),
                )
              : TextButton.icon(
                  onPressed: _resendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryPink),
                  label: const Text(
                    'Resend OTP via WhatsApp',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
