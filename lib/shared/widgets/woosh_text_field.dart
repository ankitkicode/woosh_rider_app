import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class WooshTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final Widget? suffixWidget;

  const WooshTextField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 15, fontFamily: 'Poppins', color: AppColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.primaryPink, size: 20)
                : null,
            suffixIcon: suffixWidget,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
