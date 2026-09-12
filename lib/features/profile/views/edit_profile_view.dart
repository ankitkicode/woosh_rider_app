import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_text_field.dart';
import '../view_models/profile_view_model.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  static Future<void> showAsBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EditProfileView(),
    );
  }

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleColorController;

  String _selectedGender = 'female';
  String _selectedDob = '';
  String? _nameError;
  String? _emailError;
  String? _cityError;
  String? _vehicleNumberError;
  String? _vehicleModelError;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(profileViewModelProvider);

    _nameController = TextEditingController(text: profileState.name);
    _emailController = TextEditingController(text: profileState.email);
    _phoneController = TextEditingController(text: profileState.phone);
    _cityController = TextEditingController(text: profileState.city);
    _vehicleNumberController = TextEditingController(text: profileState.vehicleNumber);
    _vehicleModelController = TextEditingController(text: profileState.vehicleModel);
    _vehicleColorController = TextEditingController(text: profileState.vehicleColor);

    _selectedGender = profileState.gender.isNotEmpty ? profileState.gender.toLowerCase() : 'female';
    _selectedDob = profileState.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initialDate = DateTime.tryParse(_selectedDob) ?? DateTime(1995, 8, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryPink,
            onPrimary: Colors.white,
            onSurface: AppColors.darkText,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDob =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  bool _validateInputs() {
    bool isValid = true;

    if (_nameController.text.trim().length < 2) {
      setState(() => _nameError = 'Please enter your full name');
      isValid = false;
    } else {
      setState(() => _nameError = null);
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      isValid = false;
    } else {
      setState(() => _emailError = null);
    }

    if (_cityController.text.trim().isEmpty) {
      setState(() => _cityError = 'City is required');
      isValid = false;
    } else {
      setState(() => _cityError = null);
    }

    if (_vehicleNumberController.text.trim().isEmpty) {
      setState(() => _vehicleNumberError = 'Vehicle registration number is required');
      isValid = false;
    } else {
      setState(() => _vehicleNumberError = null);
    }

    if (_vehicleModelController.text.trim().isEmpty) {
      setState(() => _vehicleModelError = 'Vehicle model is required');
      isValid = false;
    } else {
      setState(() => _vehicleModelError = null);
    }

    return isValid;
  }

  Future<void> _saveProfile() async {
    if (!_validateInputs()) return;

    final success = await ref.read(profileViewModelProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender,
          dateOfBirth: _selectedDob,
          city: _cityController.text.trim(),
          vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
          vehicleModel: _vehicleModelController.text.trim(),
          vehicleColor: _vehicleColorController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Profile updated successfully!', style: TextStyle(fontFamily: 'Poppins')),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/profile');
      }
    } else {
      final errorMsg = ref.read(profileViewModelProvider).error ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final isUpdating = profileState.isUpdating;

    return SafeArea(
      top: true,
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Notice Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightPink,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderPink.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.primaryPink, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Keep your details accurate for seamless ride requests and payout processing.',
                                style: TextStyle(
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

                      // SECTION 1: Personal Details
                      _buildSectionHeader(Icons.person_outline_rounded, 'Personal Details'),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.badge_outlined,
                        controller: _nameController,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Email Address',
                        hint: 'rider@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Mobile Number',
                        hint: 'Phone number',
                        icon: Icons.phone_android_outlined,
                        controller: _phoneController,
                        readOnly: true,
                        suffixWidget: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.hintGray),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender Selection
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildGenderChip('female', 'Female', Icons.female_rounded),
                          const SizedBox(width: 10),
                          _buildGenderChip('male', 'Male', Icons.male_rounded),
                          const SizedBox(width: 10),
                          _buildGenderChip('other', 'Other', Icons.transgender_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth Picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDateOfBirth,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedDob.isNotEmpty ? AppColors.primaryPink.withValues(alpha: 0.5) : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: AppColors.primaryPink, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDob.isNotEmpty ? _selectedDob : 'Select Date of Birth',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      color: _selectedDob.isNotEmpty ? AppColors.darkText : AppColors.hintGray,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down, color: AppColors.lightGray),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'City of Operation',
                        hint: 'e.g. Indore',
                        icon: Icons.location_city_outlined,
                        controller: _cityController,
                        errorText: _cityError,
                      ),

                      const SizedBox(height: 28),

                      // SECTION 2: Vehicle Information
                      _buildSectionHeader(Icons.two_wheeler_rounded, 'Vehicle Details'),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Vehicle Model',
                        hint: 'e.g. Honda Activa 6G',
                        icon: Icons.electric_bike_outlined,
                        controller: _vehicleModelController,
                        errorText: _vehicleModelError,
                      ),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Vehicle Registration Number',
                        hint: 'e.g. MP09AB1234',
                        icon: Icons.confirmation_number_outlined,
                        controller: _vehicleNumberController,
                        errorText: _vehicleNumberError,
                      ),
                      const SizedBox(height: 16),

                      WooshTextField(
                        label: 'Vehicle Color',
                        hint: 'e.g. Black, Red, White',
                        icon: Icons.palette_outlined,
                        controller: _vehicleColorController,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Save Button Fixed Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: WooshGradientButton(
                text: 'Save Changes',
                isLoading: isUpdating,
                icon: Icons.check_circle_rounded,
                onPressed: isUpdating ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.dividerColor, height: 1)),
      ],
    );
  }

  Widget _buildGenderChip(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPink.withValues(alpha: 0.1) : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.borderLight,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryPink : AppColors.lightGray,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryPink : AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
