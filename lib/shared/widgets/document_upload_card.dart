import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';

/// A card that shows upload state for each KYC document
class DocumentUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String docKey; // e.g. 'aadhaar', 'driving_license'
  final bool isRequired;
  final String? uploadedFilePath;
  final VoidCallback onUpload;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.docKey,
    required this.isRequired,
    required this.uploadedFilePath,
    required this.onUpload,
  });

  bool get isUploaded => uploadedFilePath != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? AppColors.successGreen : AppColors.borderLight,
          width: isUploaded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUploaded ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.lightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isUploaded
              ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 26)
              : const Icon(Icons.upload_file, color: AppColors.primaryPink, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppColors.darkText),
              ),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Required', style: TextStyle(fontSize: 10, color: AppColors.errorRed, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.infoBlue, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isUploaded ? '✓ Uploaded successfully' : subtitle,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: isUploaded ? AppColors.successGreen : AppColors.lightGray,
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: onUpload,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.primaryPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUploaded ? 'Change' : 'Upload',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: isUploaded ? AppColors.successGreen : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a preview thumbnail of the uploaded image
class UploadedImagePreview extends StatelessWidget {
  final String filePath;
  final VoidCallback onRemove;

  const UploadedImagePreview({super.key, required this.filePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(filePath), height: 100, width: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper to pick image from camera or gallery
Future<String?> pickImage({bool fromCamera = false}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1200,
  );
  return picked?.path;
}
