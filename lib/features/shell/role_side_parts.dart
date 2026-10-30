import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../auth/logout.dart';
import '../profile/profile_controller.dart';

/// Cabecera del menú lateral (web): marca de la app. Común a todos los roles.
/// Va sobre el verde profundo del menú: el logo se apoya en una placa blanca
/// para que sus colores se lean igual que en el resto de la app.
class RoleSideHeader extends StatelessWidget {
  const RoleSideHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const BrandLogo(size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGAT', style: AppText.title.copyWith(color: AppColors.navOnInk, fontSize: 15)),
                Text('Vigilancia del durazno', style: AppText.caption.copyWith(color: AppColors.navOnInkMuted)),
              ],
            ),
          ),
        ],
      );
}

/// Pie del menú lateral (web): usuario, rol, conexión real y cerrar sesión.
class RoleSideFooter extends StatelessWidget {
  const RoleSideFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppServices.session.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ListenableBuilder(
              listenable: ProfileController.instance,
              builder: (_, __) => UserAvatar(
                name: s?.displayName ?? '',
                radius: 18,
                photoBytes: ProfileController.instance.profile?.photoBytes,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s?.shortName ?? '',
                      style: AppText.label.copyWith(color: AppColors.navOnInk),
                      overflow: TextOverflow.ellipsis),
                  Text(s?.role.label ?? '', style: AppText.caption.copyWith(color: AppColors.navOnInkMuted)),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.logout,
              tooltip: 'Cerrar sesión',
              color: AppColors.navOnInkMuted,
              onPressed: () => confirmAndLogout(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ValueListenableBuilder<bool>(
          valueListenable: AppServices.isOnline,
          builder: (_, online, __) => ConnectionChip(isOnline: online),
        ),
      ],
    );
  }
}
