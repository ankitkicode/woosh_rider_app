import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_text_field.dart';
import '../view_models/auth_view_model.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> with TickerProviderStateMixin {
  // Current step: 0 = Phone, 1 = OTP, 2 = Details
  int _currentStep = 0;

  // Step 1 - Phone
  final _phoneController = TextEditingController();
  bool _isSendingOtp = false;
  String? _phoneError;

  // Step 2 - OTP
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifyingOtp = false;
  String? _otpError;
  int _resendTimer = 0;
  String _verifiedPhone = '';

  String? _receivedOtp;

  // Step 3 - Details
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isRegistering = false;
  String? _registerError;
  Map<String, String> _fieldErrors = {};

  // Emergency contacts
  final List<Map<String, TextEditingController>> _contacts = [
    {'name': TextEditingController(), 'number': TextEditingController()},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _nameController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    for (final c in _contacts) {
      c['name']!.dispose();
      c['number']!.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  // ─── Step 1: Send OTP ───────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _phoneError = 'Please enter a valid 10-digit number');
      return;
    }
    setState(() { _isSendingOtp = true; _phoneError = null; });
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(phone, action: 'register');
      _verifiedPhone = phone;
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;
      setState(() { _currentStep = 1; _resendTimer = 30; });
      _startResendTimer();
      _showOtpToast();
    } catch (e) {
      setState(() => _phoneError = e.toString());
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
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
      final otp = await notifier.sendOtp(_verifiedPhone, action: 'register');
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;
      _startResendTimer();
      _showOtpToast();
    } catch (e) {
      setState(() => _otpError = e.toString());
    }
  }

  // ─── Step 2: Verify OTP ─────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _otpError = 'Please enter the complete 6-digit OTP');
      return;
    }
    setState(() { _isVerifyingOtp = true; _otpError = null; });
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final result = await notifier.verifyOtp(phoneNumber: _verifiedPhone, otp: _otp);
      if (!mounted) return;

      if (result == 'new_user') {
        // New user — proceed to details step
        setState(() => _currentStep = 2);
      } else {
        // Existing user — they should use login instead
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account already exists! Redirecting to login...'),
              backgroundColor: AppColors.primaryPink,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go('/login');
          });
        }
      }
    } catch (e) {
      setState(() => _otpError = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  // ─── Step 3: Register ───────────────────────────────────────────────
  bool _validateDetails() {
    final errors = <String, String>{};
    if (_nameController.text.trim().length < 3) errors['name'] = 'Please enter your full name';
    if (_cityController.text.trim().isEmpty) errors['city'] = 'Please enter your city';
    for (int i = 0; i < _contacts.length; i++) {
      if (_contacts[i]['name']!.text.trim().isEmpty) errors['contactName$i'] = 'Required';
      if (_contacts[i]['number']!.text.trim().length != 10) errors['contactNumber$i'] = 'Invalid number';
    }
    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  Future<void> _register() async {
    if (!_validateDetails()) return;
    setState(() { _isRegistering = true; _registerError = null; });
    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      await notifier.register(
        phoneNumber: _verifiedPhone,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        emergencyContacts: _contacts.map((c) => {
          'name': c['name']!.text.trim(),
          'number': '+91${c['number']!.text.trim()}',
        }).toList(),
      );
      if (mounted) context.go('/kyc');
    } catch (e) {
      setState(() => _registerError = e.toString());
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top bar with back + step indicator ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.darkText),
                        onPressed: () => setState(() => _currentStep--),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.darkText),
                        onPressed: () => context.go('/login'),
                      ),
                    Expanded(child: _buildStepIndicator()),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              // ─── Content ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildPhoneStep()
                        : _currentStep == 1
                            ? _buildOtpStep()
                            : _buildDetailsStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step Indicator ─────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Phone', 'Verify', 'Details'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isCurrent = i == _currentStep;
        return Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? AppColors.brandGradient : null,
                color: isActive ? null : AppColors.borderLight,
                boxShadow: isCurrent ? [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 8)] : null,
              ),
              child: Center(
                child: i < _currentStep
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${i + 1}', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.lightGray,
                      )),
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 32, height: 2,
                color: i < _currentStep ? AppColors.primaryPink : AppColors.borderLight,
              ),
          ],
        );
      }),
    );
  }

  // ─── Step 1: Phone Number ───────────────────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Logo
        Center(
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.electric_bike, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Woosh Driver', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryPink)),
            const SizedBox(height: 2),
            const Text('Register as a Driver', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
          ]),
        ),

        const SizedBox(height: 28),

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
        const Text('Enter Your WhatsApp Number', style: AppTextStyles.heading3),
        const SizedBox(height: 6),
        const Text('We\'ll send you a verification code', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 20),

        // Phone input with +91
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
              onChanged: (_) { if (_phoneError != null) setState(() => _phoneError = null); },
              decoration: InputDecoration(hintText: '98765 43210', counterText: '', errorText: _phoneError),
            ),
          ),
        ]),

        const SizedBox(height: 8),
        const Text('📱 You will receive an OTP on WhatsApp', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),

        const SizedBox(height: 28),
        WooshGradientButton(text: 'Send OTP', isLoading: _isSendingOtp, icon: Icons.send, onPressed: _sendOtp),

        const SizedBox(height: 32),
        Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already registered? ', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('Login →', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryPink)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 2: OTP Verification ───────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Text('Check: $_verifiedPhone', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
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
        const Text('Verify Your Number', style: AppTextStyles.heading2),
        const SizedBox(height: 6),
        const Text('Enter the 6-digit code we sent you', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
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

        if (_otpError != null) ...[
          const SizedBox(height: 12),
          Text(_otpError!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontFamily: 'Poppins')),
        ],

        const SizedBox(height: 28),
        WooshGradientButton(text: 'Verify & Continue', isLoading: _isVerifyingOtp, onPressed: _verifyOtp),

        const SizedBox(height: 20),
        Center(
          child: _resendTimer > 0
              ? Text('Resend OTP in $_resendTimer seconds', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray))
              : GestureDetector(
                  onTap: _resendOtp,
                  child: const Text('Resend OTP', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 3: Personal Details ───────────────────────────────────────
  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey('details_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Verified phone badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
            const SizedBox(width: 8),
            Text('+91 $_verifiedPhone', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const Spacer(),
            const Text('✓ Verified', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successGreen)),
          ]),
        ),

        const SizedBox(height: 20),
        const Text('Your Details', style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text('Tell us about yourself to get started', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 20),

        WooshTextField(label: 'Full Name', hint: 'Enter your full name', icon: Icons.person_outline, controller: _nameController, errorText: _fieldErrors['name']),
        const SizedBox(height: 14),
        WooshTextField(label: 'City', hint: 'City where you want to drive', icon: Icons.location_city_outlined, controller: _cityController, errorText: _fieldErrors['city']),
        const SizedBox(height: 14),
        WooshTextField(label: 'Email (Optional)', hint: 'Enter your email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, controller: _emailController),

        const SizedBox(height: 24),

        // Emergency contacts header
        Row(children: [
          const Icon(Icons.emergency_share, size: 18, color: AppColors.primaryPink),
          const SizedBox(width: 8),
          const Text('Emergency Contacts', style: AppTextStyles.heading3),
          const Spacer(),
          Text('${_contacts.length}/3', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
        ]),
        const SizedBox(height: 4),
        const Text('They\'ll be notified during SOS alerts', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
        const SizedBox(height: 14),

        ..._contacts.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return _ContactCard(
            index: i + 1,
            nameController: c['name']!,
            numberController: c['number']!,
            nameError: _fieldErrors['contactName$i'],
            numberError: _fieldErrors['contactNumber$i'],
            canRemove: _contacts.length > 1,
            onRemove: () => setState(() => _contacts.removeAt(i)),
          );
        }),

        if (_contacts.length < 3)
          TextButton.icon(
            onPressed: () => setState(() => _contacts.add({'name': TextEditingController(), 'number': TextEditingController()})),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPink, size: 18),
            label: const Text('Add Contact', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primaryPink, fontWeight: FontWeight.w600, fontSize: 13)),
          ),

        if (_registerError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_registerError!, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.errorRed, fontSize: 13))),
            ]),
          ),
        ],

        const SizedBox(height: 28),
        WooshGradientButton(text: 'Register & Continue to KYC →', isLoading: _isRegistering, onPressed: _register),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Emergency Contact Card Widget ──────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final String? nameError;
  final String? numberError;
  final bool canRemove;
  final VoidCallback onRemove;

  const _ContactCard({required this.index, required this.nameController, required this.numberController, this.nameError, this.numberError, required this.canRemove, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.person_pin, size: 18, color: AppColors.primaryPink),
          const SizedBox(width: 8),
          Text('Contact $index', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          if (canRemove)
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18, color: AppColors.lightGray), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 10),
        TextField(controller: nameController, decoration: InputDecoration(hintText: 'Contact name', errorText: nameError, isDense: true, prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.primaryPink))),
        const SizedBox(height: 8),
        TextField(controller: numberController, keyboardType: TextInputType.phone, maxLength: 10, decoration: InputDecoration(hintText: '10-digit number', counterText: '', isDense: true, errorText: numberError, prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryPink))),
      ]),
    );
  }
}
