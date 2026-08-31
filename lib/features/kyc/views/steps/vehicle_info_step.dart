import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_colors.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../../../shared/widgets/woosh_text_field.dart';
import '../../view_models/kyc_view_model.dart';
import 'personal_info_step.dart' show stepHeader;

class VehicleInfoStep extends ConsumerStatefulWidget {
  const VehicleInfoStep({super.key});

  @override
  ConsumerState<VehicleInfoStep> createState() => _VehicleInfoStepState();
}

class _VehicleInfoStepState extends ConsumerState<VehicleInfoStep> {
  final _numberCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    final state = ref.read(kycViewModelProvider);
    _numberCtrl.text = state.vehicleNumber;
    _modelCtrl.text = state.vehicleModel;
    _colorCtrl.text = state.vehicleColor;
  }

  @override
  void dispose() {
    _numberCtrl.dispose(); _modelCtrl.dispose(); _colorCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    if (_numberCtrl.text.trim().length < 6) { _errors['number'] = 'Enter valid vehicle number'; ok = false; }
    else _errors['number'] = null;
    if (_modelCtrl.text.trim().isEmpty) { _errors['model'] = 'Enter vehicle model'; ok = false; }
    else _errors['model'] = null;
    setState(() {});
    return ok;
  }

  Future<void> _next() async {
    if (!_validate()) return;
    ref.read(kycViewModelProvider.notifier).updateVehicleInfo(
      number: _numberCtrl.text.trim().toUpperCase(),
      model: _modelCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
    );
    try {
      await ref.read(kycViewModelProvider.notifier).saveVehicleInfo();
      ref.read(kycViewModelProvider.notifier).nextStep();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(kycViewModelProvider).isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        stepHeader(icon: Icons.electric_bike, title: 'Vehicle Information', subtitle: 'Details about your scooty/bike'),
        const SizedBox(height: 24),

        // Bike/Scooty notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.infoBlue, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Woosh accepts only two-wheelers: scooty and bikes.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.bodyText))),
          ]),
        ),

        const SizedBox(height: 24),

        WooshTextField(
          label: 'Vehicle Registration Number',
          hint: 'e.g. MH01AB1234',
          icon: Icons.confirmation_number_outlined,
          controller: _numberCtrl,
          errorText: _errors['number'],
        ),
        const SizedBox(height: 16),
        WooshTextField(
          label: 'Vehicle Model',
          hint: 'e.g. Honda Activa 6G',
          icon: Icons.two_wheeler,
          controller: _modelCtrl,
          errorText: _errors['model'],
        ),
        const SizedBox(height: 16),
        WooshTextField(
          label: 'Vehicle Color',
          hint: 'e.g. Black, White, Red',
          icon: Icons.palette_outlined,
          controller: _colorCtrl,
        ),

        const SizedBox(height: 40),
        WooshGradientButton(text: 'Continue to Documents', isLoading: isLoading, onPressed: _next),
      ]),
    );
  }
}
