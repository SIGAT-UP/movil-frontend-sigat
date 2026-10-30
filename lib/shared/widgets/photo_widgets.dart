import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/photo_file.dart';

/// Hoja inferior para elegir el origen de una foto: cámara o galería.
/// La usan el perfil (M13-T) y las evidencias de lectura (M05-T).
/// Devuelve null si la persona cierra la hoja sin elegir.
Future<PhotoSourceChoice?> showPhotoSourceSheet(
  BuildContext context, {
  String title = 'Adjuntar evidencia',
  String? message,
  bool allowRemove = false,
  bool isWeb = false,
}) {
  return showModalBottomSheet<PhotoSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.h3),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: AppText.secondary),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SourceOption(
              icon: Icons.photo_camera_outlined,
              title: 'Tomar fotografía',
              subtitle: isWeb ? 'En web el navegador puede pedir un archivo' : 'Abre la cámara del dispositivo',
              onTap: () => Navigator.pop(ctx, PhotoSourceChoice.camara),
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceOption(
              icon: Icons.photo_library_outlined,
              title: 'Elegir de la galería',
              subtitle: 'Selecciona una fotografía existente',
              onTap: () => Navigator.pop(ctx, PhotoSourceChoice.galeria),
            ),
            if (allowRemove) ...[
              const SizedBox(height: AppSpacing.md),
              DestructiveButton(
                label: 'Quitar fotografía actual',
                icon: Icons.delete_outline,
                onPressed: () => Navigator.pop(ctx, PhotoSourceChoice.quitar),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Formatos ${PhotoRules.allowedLabel} · máximo ${PhotoRules.sizeLabel(PhotoRules.maxBytes)}',
              textAlign: TextAlign.center,
              style: AppText.micro,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Opción elegida en la hoja de origen.
enum PhotoSourceChoice { camara, galeria, quitar }

/// Hoja inferior para adjuntar las instrucciones de una planeación.
/// Solo DOS orígenes: un documento del dispositivo o una imagen de la
/// galería. No ofrece la cámara a propósito.
Future<DocumentSourceChoice?> showDocumentSourceSheet(
  BuildContext context, {
  bool allowRemove = false,
}) {
  return showModalBottomSheet<DocumentSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Adjuntar instrucciones', style: AppText.h3),
            const SizedBox(height: AppSpacing.xs),
            const Text('Elige un documento o una imagen guardada en el dispositivo.',
                style: AppText.secondary),
            const SizedBox(height: AppSpacing.lg),
            _SourceOption(
              icon: Icons.description_outlined,
              title: 'Documento',
              subtitle: 'Archivo PDF o Word del dispositivo',
              onTap: () => Navigator.pop(ctx, DocumentSourceChoice.documento),
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceOption(
              icon: Icons.image_outlined,
              title: 'Imagen',
              subtitle: 'Elegir de la galería',
              onTap: () => Navigator.pop(ctx, DocumentSourceChoice.imagen),
            ),
            if (allowRemove) ...[
              const SizedBox(height: AppSpacing.md),
              DestructiveButton(
                label: 'Quitar archivo adjunto',
                icon: Icons.delete_outline,
                onPressed: () => Navigator.pop(ctx, DocumentSourceChoice.quitar),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'PDF o Word hasta 10 MB · imágenes JPG, PNG o WebP hasta 8 MB',
              textAlign: TextAlign.center,
              style: AppText.micro,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Opción elegida en la hoja de instrucciones.
enum DocumentSourceChoice { documento, imagen, quitar }

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryDark, size: AppIconSize.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// Vista previa de una foto ya validada, con su peso y formato.
/// Compartida por la confirmación de evidencia y la de foto de perfil.
class PhotoPreview extends StatelessWidget {
  const PhotoPreview({super.key, required this.photo, this.aspectRatio = 3 / 4, this.circular = false});

  final PhotoFile photo;
  final double aspectRatio;

  /// true = recorte circular (foto de perfil).
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(photo.bytes, fit: BoxFit.cover, gaplessPlayback: true);
    if (circular) {
      return ClipOval(child: SizedBox(width: 180, height: 180, child: image));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AspectRatio(aspectRatio: aspectRatio, child: image),
    );
  }
}

/// Línea con el formato y el peso de la imagen.
class PhotoMetaLine extends StatelessWidget {
  const PhotoMetaLine(this.photo, {super.key});
  final PhotoFile photo;

  @override
  Widget build(BuildContext context) => Text(
        '${photo.mimeType.split('/').last.toUpperCase()} · ${photo.sizeLabel}',
        textAlign: TextAlign.center,
        style: AppText.micro,
      );
}
