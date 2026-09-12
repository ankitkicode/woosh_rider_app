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
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
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

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _phoneError = 'Please enter a valid 10-digit number');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSendingOtp = true;
      _phoneError = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(phone, action: 'register');
      _verifiedPhone = phone;
      _receivedOtp = (otp != null && otp.isNotEmpty) ? otp : null;

      // Auto-fill OTP if test OTP received
      if (_receivedOtp != null && _receivedOtp!.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = _receivedOtp![i];
        }
      }

      setState(() {
        _currentStep = 1;
        _resendTimer = 30;
      });
      _startResendTimer();
    } catch (e) {
      setState(() => _phoneError = e.toString());
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
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
      _otpError = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final otp = await notifier.sendOtp(_verifiedPhone, action: 'register');
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
            content: Text('OTP re-sent via WhatsApp'),
            backgroundColor: Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _otpError = e.toString());
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _otpError = 'Please enter the complete 6-digit OTP');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      final result = await notifier.verifyOtp(phoneNumber: _verifiedPhone, otp: _otp);
      if (!mounted) return;

      if (result == 'new_user') {
        setState(() => _currentStep = 2);
      } else if (result == 'approved') {
        context.go('/home');
      } else if (result == 'kyc_pending_review') {
        context.go('/kyc/pending');
      } else if (result == 'kyc_pending') {
        context.go('/kyc');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account already exists! Redirecting to login...'),
              backgroundColor: AppColors.primaryPink,
              behavior: SnackBarBehavior.floating,
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

  void _handleOtpInput(String value, int index) {
    if (_otpError != null) setState(() => _otpError = null);

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

  bool _validateDetails() {
    final errors = <String, String>{};
    if (_nameController.text.trim().length < 2) errors['name'] = 'Please enter your full name';
    if (_cityController.text.trim().isEmpty) errors['city'] = 'Please enter your city';

    for (int i = 0; i < _contacts.length; i++) {
      if (_contacts[i]['name']!.text.trim().isEmpty) errors['contactName$i'] = 'Required';
      if (_contacts[i]['number']!.text.trim().length != 10) errors['contactNumber$i'] = 'Invalid 10-digit number';
    }
    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  Future<void> _register() async {
    if (!_validateDetails()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isRegistering = true;
      _registerError = null;
    });

    try {
      final notifier = ref.read(authViewModelProvider.notifier);
      await notifier.register(
        phoneNumber: _verifiedPhone,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        emergencyContacts: _contacts
            .map((c) => {
                  'name': c['name']!.text.trim(),
                  'number': '+91${c['number']!.text.trim()}',
                })
            .toList(),
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
            child: Column(
              children: [
                // Top Header Bar & Progress Steps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.darkText),
                        onPressed: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          } else {
                            context.go('/login');
                          }
                        },
                      ),
                      Expanded(child: _buildStepIndicator()),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
      ),
    );
  }

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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? AppColors.brandGradient : null,
                color: isActive ? null : AppColors.borderLight,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: i < _currentStep
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.lightGray,
                        ),
                      ),
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 32,
                height: 2,
                color: i < _currentStep ? AppColors.primaryPink : AppColors.borderLight,
              ),
          ],
        );
      }),
    );
  }

  // ─── Step 1: Phone Entry ────────────────────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Logo Header
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
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primaryPink,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Woosh Driver Registration', style: AppTextStyles.heading2),
              const Text('Join the female driver network', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Female-only notice
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

        const SizedBox(height: 24),
        const Text('Enter Your WhatsApp Number', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text('We will send a 6-digit OTP code to verify', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 16),

        // Phone input
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
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  counterText: '',
                  errorText: _phoneError,
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
              'OTP will be sent via WhatsApp',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray),
            ),
          ],
        ),

        const SizedBox(height: 28),
        WooshGradientButton(
          text: 'Send OTP',
          isLoading: _isSendingOtp,
          icon: Icons.send_rounded,
          onPressed: _sendOtp,
        ),

        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already registered? ', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Login →',
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
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 2: OTP Entry ──────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // WhatsApp Badge
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
                      'Sent to +91 $_verifiedPhone',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text('Verify Your Number', style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text('Enter the 6-digit code we sent you', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 24),

        // OTP Boxes
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

        if (_otpError != null) ...[
          const SizedBox(height: 12),
          Text(
            _otpError!,
            style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
        ],

        const SizedBox(height: 28),
        WooshGradientButton(
          text: 'Verify & Continue',
          isLoading: _isVerifyingOtp,
          icon: Icons.check_circle_rounded,
          onPressed: _verifyOtp,
        ),

        const SizedBox(height: 20),
        Center(
          child: _resendTimer > 0
              ? Text('Resend OTP in ${_resendTimer}s', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray, fontWeight: FontWeight.w500))
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
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Step 3: Details Entry ──────────────────────────────────────────
  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey('details_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Verified Phone Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                '+91 $_verifiedPhone',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText),
              ),
              const Spacer(),
              const Text(
                '✓ VERIFIED',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.successGreen),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Driver Personal Details', style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text('Enter your details to create your driver profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
        const SizedBox(height: 20),

        WooshTextField(
          label: 'Full Name',
          hint: 'As per Aadhaar Card',
          icon: Icons.person_outline_rounded,
          controller: _nameController,
          errorText: _fieldErrors['name'],
          onChanged: (_) {
            if (_fieldErrors.containsKey('name')) {
              setState(() => _fieldErrors.remove('name'));
            }
          },
        ),
        const SizedBox(height: 14),

        WooshTextField(
          label: 'City of Operation',
          hint: 'e.g. Indore',
          icon: Icons.location_city_outlined,
          controller: _cityController,
          errorText: _fieldErrors['city'],
          onChanged: (_) {
            if (_fieldErrors.containsKey('city')) {
              setState(() => _fieldErrors.remove('city'));
            }
          },
        ),
        const SizedBox(height: 14),

        WooshTextField(
          label: 'Email Address (Optional)',
          hint: 'rider@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
        ),

        const SizedBox(height: 24),

        // Emergency Contacts Header
        Row(
          children: [
            const Icon(Icons.emergency_share_rounded, size: 20, color: AppColors.primaryPink),
            const SizedBox(width: 8),
            const Text('Emergency Contacts', style: AppTextStyles.heading3),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_contacts.length}/3 Added',
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
        const SizedBox(height: 4),
        const Text('They will receive SOS notifications during emergencies', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
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
            onChanged: () {
              if (_fieldErrors.isNotEmpty) {
                setState(() {
                  _fieldErrors.remove('contactName$i');
                  _fieldErrors.remove('contactNumber$i');
                });
              }
            },
          );
        }),

        if (_contacts.length < 3)
          TextButton.icon(
            onPressed: () => setState(() => _contacts.add({'name': TextEditingController(), 'number': TextEditingController()})),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryPink, size: 18),
            label: const Text(
              'Add Emergency Contact',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.primaryPink, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),

        if (_registerError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _registerError!,
                    style: const TextStyle(fontFamily: 'Poppins', color: AppColors.errorRed, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        WooshGradientButton(
          text: 'Register & Continue to KYC →',
          isLoading: _isRegistering,
          icon: Icons.check_circle_rounded,
          onPressed: _register,
        ),
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
  final VoidCallback onChanged;

  const _ContactCard({
    required this.index,
    required this.nameController,
    required this.numberController,
    this.nameError,
    this.numberError,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, size: 18, color: AppColors.primaryPink),
              const SizedBox(width: 8),
              Text('Contact $index', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkText)),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.lightGray),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Contact name',
              errorText: nameError,
              isDense: true,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primaryPink),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: numberController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: '10-digit mobile number',
              counterText: '',
              isDense: true,
              errorText: numberError,
              prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );
  }
}
