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
  final String? serverStatus; // PENDING, APPROVED, REJECTED
  final String? rejectionReason;
  final VoidCallback onUpload;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.docKey,
    required this.isRequired,
    required this.uploadedFilePath,
    this.serverStatus,
    this.rejectionReason,
    required this.onUpload,
  });

  bool get isUploadedLocally => uploadedFilePath != null;
  bool get isApproved => serverStatus == 'APPROVED';
  bool get isRejected => serverStatus == 'REJECTED';
  bool get isPending => serverStatus == 'PENDING';
  
  bool get isComplete => isUploadedLocally || isApproved || isPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRejected ? AppColors.errorRed : (isComplete ? AppColors.successGreen : AppColors.borderLight),
          width: isComplete || isRejected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRejected 
                    ? AppColors.errorRed.withValues(alpha: 0.1) 
                    : (isComplete ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.lightPink),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isRejected
                  ? const Icon(Icons.cancel, color: AppColors.errorRed, size: 26)
                  : (isComplete
                      ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 26)
                      : const Icon(Icons.upload_file, color: AppColors.primaryPink, size: 26)),
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
                isRejected ? 'Rejected' : (isComplete ? '✓ Uploaded' : subtitle),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: isRejected ? AppColors.errorRed : (isComplete ? AppColors.successGreen : AppColors.lightGray),
                ),
              ),
            ),
            trailing: isApproved || (isPending && !isUploadedLocally)
                ? null
                : GestureDetector(
                    onTap: onUpload,
                    child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUploadedLocally ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.primaryPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUploadedLocally || isRejected ? 'Change' : 'Upload',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: isUploadedLocally ? AppColors.successGreen : Colors.white,
              ),
            ),
          ),
        ),
      ),
          if (isRejected && rejectionReason != null && rejectionReason!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                border: const Border(top: BorderSide(color: AppColors.errorRed, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.errorRed, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason!,
                      style: const TextStyle(fontSize: 11, color: AppColors.errorRed, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
