import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/photo_file.dart';
import '../../shared/shared.dart';

/// Resultado de la confirmación de la foto de perfil.
class ProfilePhotoResult {
  const ProfilePhotoResult({this.photo, this.changeSource = false});
  final PhotoFile? photo;
  final bool changeSource;
}

/// M13-T — Vista previa de la nueva foto de perfil antes de aplicarla.
/// Recibe una foto YA validada por `PhotoService`.
class ProfilePhotoScreen extends StatelessWidget {
  const ProfilePhotoScreen({super.key, required this.photo});
  final PhotoFile photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Nueva fotografía'),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(child: PhotoPreview(photo: photo, circular: true)),
            const SizedBox(height: AppSpacing.md),
            PhotoMetaLine(photo),
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: Text(
                'Así se verá tu fotografía en el perfil.',
                textAlign: TextAlign.center,
                style: AppText.secondary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Usar esta fotografía',
          color: AppColors.primaryDark,
          onPressed: () => Navigator.of(context).pop(ProfilePhotoResult(photo: photo)),
        ),
        SecondaryButton(
          label: 'Tomar o elegir otra',
          icon: Icons.refresh,
          onPressed: () => Navigator.of(context).pop(const ProfilePhotoResult(changeSource: true)),
        ),
      ]),
    );
  }
}
