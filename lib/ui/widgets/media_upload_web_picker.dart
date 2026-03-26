import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/domain/use_cases/post_upload_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:sint/sint.dart';

import '../media_upload_web_controller.dart';

/// Web file picker widget — replaces MediaUploadGrid on web.
///
/// Shows a drag-target area with a file picker button.
/// Displays preview of selected image or file info for other types.
class MediaUploadWebPicker extends StatelessWidget {
  final MediaUploadWebController controller;

  const MediaUploadWebPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MediaUploadWebController>(
      builder: (_) {
        final hasMedia = controller.mediaFileExists();
        final bytes = controller.mediaBytes;
        final type = controller.mediaType;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: hasMedia && bytes != null
                    ? _buildPreview(type, bytes, controller)
                    : _buildPickerArea(context),
              ),
              const SizedBox(height: 16),
              if (hasMedia)
                _buildActionBar(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerArea(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => controller.pickMedia(),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColor.bondiBlue.withValues(alpha: 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: AppColor.bondiBlue.withValues(alpha: 0.05),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColor.bondiBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Arrastra tu archivo aqui o haz clic para seleccionar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Imagenes, videos, audio o documentos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.bondiBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Seleccionar archivo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildPreview(MediaType type, dynamic bytes, MediaUploadWebController ctrl) {
    if (type == MediaType.image && bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      );
    }

    // Non-image files — show icon + info
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColor.surfaceCard.withValues(alpha: 0.3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForType(type),
              size: 72,
              color: AppColor.surfaceElevated,
            ),
            const SizedBox(height: 16),
            Text(
              ctrl.getReleaseFilePath(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _formatBytes(bytes?.length ?? 0),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => controller.clearMedia(),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Eliminar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => controller.pickMedia(),
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Cambiar'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _proceedToPost(),
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Siguiente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.bondiBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _proceedToPost() {
    final type = controller.mediaType;
    if (Sint.isRegistered<PostUploadService>()) {
      final postType = type == MediaType.video ? PostType.video : PostType.image;
      Sint.find<PostUploadService>().setPostType(postType);
    }
    Sint.toNamed(AppRouteConstants.postUploadDescription);
  }

  IconData _iconForType(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.videocam_outlined;
      case MediaType.audio:
        return Icons.audiotrack_outlined;
      case MediaType.document:
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

}
