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
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _errorText = 'Please enter a valid 10-digit number');
      return;
    }
    setState(() { _isLoading = true; _errorText = null; });
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(phone);
      _phone = phone;
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;
      setState(() { _isPhoneStep = false; _resendTimer = 30; });
      _startResendTimer();
      _showOtpToast();
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOtpToast() {
    if (_receivedOtp != null && _receivedOtp!.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔑 Test OTP is: $_receivedOtp', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.secondaryPurple,
          duration: const Duration(seconds: 30),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), _countdown);
  }

  void _countdown() {
    if (!mounted) return;
    setState(() { if (_resendTimer > 0) _resendTimer--; });
    if (_resendTimer > 0) Future.delayed(const Duration(seconds: 1), _countdown);
  }

  Future<void> _resendOtp() async {
    setState(() => _resendTimer = 30);
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(_phone);
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;
      _startResendTimer();
      _showOtpToast();
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _errorText = 'Please enter the complete 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _errorText = null; });
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final result = await notifier.verifyOtp(phoneNumber: _phone, otp: _otp);
      if (!mounted) return;

      if (result == 'new_user') {
        // New user — redirect to registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your registration first!'),
            backgroundColor: AppColors.primaryPink,
          ),
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/register');
        });
      } else if (result == 'approved') {
        context.go('/home');
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

  void _goBackToPhone() {
    setState(() {
      _isPhoneStep = true;
      _errorText = null;
      for (final c in _otpControllers) { c.clear(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isPhoneStep ? _buildPhoneSection() : _buildOtpSection(),
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
        const SizedBox(height: 60),

        // Logo
        Center(
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.electric_bike, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Woosh', style: TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryPink)),
            const Text('Driver Portal', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.lightGray)),
          ]),
        ),

        const SizedBox(height: 36),

        // Female-only notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryPink.withValues(alpha: 0.08), AppColors.secondaryPurple.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.female, color: AppColors.primaryPink, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(AppConstants.femaleOnlyNotice, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText))),
          ]),
        ),

        const SizedBox(height: 28),
        const Text("Welcome Back!", style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text('Enter your WhatsApp number to login', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 20),

        // Phone field
        const Text('WhatsApp Number', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Text('+91', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(fontSize: 15, fontFamily: 'Poppins'),
              onChanged: (_) { if (_errorText != null) setState(() => _errorText = null); },
              decoration: InputDecoration(hintText: '98765 43210', counterText: '', errorText: _errorText),
            ),
          ),
        ]),

        const SizedBox(height: 8),
        const Text('📱 OTP will be sent on WhatsApp', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),

        const SizedBox(height: 28),
        WooshGradientButton(text: 'Send OTP', isLoading: _isLoading, icon: Icons.send, onPressed: _sendOtp),

        const SizedBox(height: 36),
        Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("New to Woosh? ", style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text('Register as Driver →', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryPink)),
            ),
          ]),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── OTP Section (inline, same page) ────────────────────────────────
  Widget _buildOtpSection() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        // Back to phone
        GestureDetector(
          onTap: _goBackToPhone,
          child: Row(children: [
            const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.primaryPink),
            const SizedBox(width: 4),
            const Text('Change Number', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
          ]),
        ),

        const SizedBox(height: 24),

        // WhatsApp badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('OTP sent via WhatsApp', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF25D366))),
                Text('Check: $_phone', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
                if (_receivedOtp != null && _receivedOtp!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondaryPurple.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '🔑 Test OTP: $_receivedOtp (Auto-filled)',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondaryPurple),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 28),
        const Text('Enter OTP', style: AppTextStyles.headline),
        const SizedBox(height: 6),
        const Text('Enter the 6-digit verification code', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 24),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48, height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  filled: true, fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPink, width: 2)),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (v.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (_otp.length == 6) _verifyOtp();
                },
              ),
            );
          }),
        ),

        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontFamily: 'Poppins')),
        ],

        const SizedBox(height: 28),
        WooshGradientButton(text: 'Login', isLoading: _isLoading, onPressed: _verifyOtp),

        const SizedBox(height: 20),
        Center(
          child: _resendTimer > 0
              ? Text('Resend in $_resendTimer s', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray))
              : GestureDetector(
                  onTap: _resendOtp,
                  child: const Text('Resend OTP', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
