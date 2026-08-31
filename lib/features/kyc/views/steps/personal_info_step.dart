import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../../../shared/widgets/woosh_text_field.dart';
import '../../view_models/kyc_view_model.dart';

class PersonalInfoStep extends ConsumerStatefulWidget {
  const PersonalInfoStep({super.key});

  @override
  ConsumerState<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends ConsumerState<PersonalInfoStep> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _nameError;
  String? _cityError;
  String? _selectedDob;

  @override
  void initState() {
    super.initState();
    final state = ref.read(kycViewModelProvider);
    _nameCtrl.text = state.name;
    _cityCtrl.text = state.city;
    _selectedDob = state.dateOfBirth.isEmpty ? null : state.dateOfBirth;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // Must be 18+
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryPink)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  bool _validate() {
    bool valid = true;
    if (_nameCtrl.text.trim().length < 3) { setState(() => _nameError = 'Please enter your full name'); valid = false; }
    else setState(() => _nameError = null);
    if (_cityCtrl.text.trim().isEmpty) { setState(() => _cityError = 'Please enter your city'); valid = false; }
    else setState(() => _cityError = null);
    return valid;
  }

  Future<void> _next() async {
    if (!_validate()) return;
    ref.read(kycViewModelProvider.notifier).updatePersonalInfo(
      name: _nameCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      dob: _selectedDob,
    );
    try {
      await ref.read(kycViewModelProvider.notifier).savePersonalInfo();
      ref.read(kycViewModelProvider.notifier).nextStep();
    } catch (e) {
      // error shown in state
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(kycViewModelProvider).isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        stepHeader(
          icon: Icons.person_outlined,
          title: 'Personal Information',
          subtitle: 'Tell us about yourself',
        ),
        const SizedBox(height: 28),

        WooshTextField(label: 'Full Name', hint: 'As per Aadhaar', icon: Icons.badge_outlined, controller: _nameCtrl, errorText: _nameError),
        const SizedBox(height: 16),
        WooshTextField(label: 'City of Operation', hint: 'City where you will drive', icon: Icons.location_city_outlined, controller: _cityCtrl, errorText: _cityError),
        const SizedBox(height: 16),

        // DOB picker
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Date of Birth', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selectedDob != null ? AppColors.successGreen : AppColors.borderLight),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.primaryPink, size: 20),
                const SizedBox(width: 12),
                Text(_selectedDob ?? 'Select your date of birth', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: _selectedDob != null ? AppColors.darkText : AppColors.hintGray)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.hintGray),
              ]),
            ),
          ),
        ]),

        const SizedBox(height: 40),
        WooshGradientButton(text: 'Continue', isLoading: isLoading, onPressed: _next),
      ]),
    );
  }
}

Widget stepHeader({required IconData icon, required String title, required String subtitle}) {
  return Row(children: [
    Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.lightPink, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: AppColors.primaryPink, size: 26),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.heading3),
      Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.lightGray)),
    ]),
  ]);
}
