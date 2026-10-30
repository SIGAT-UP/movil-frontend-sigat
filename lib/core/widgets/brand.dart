import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'asset_or_fallback.dart';
import 'status_chip.dart';

/// LOGO OFICIAL de la app: el mismo de la web SIGAT (isotipo de la mosca en el visor).
/// Es el único lugar donde se referencian los archivos del logo:
///   * [assetPath]: logotipo vertical (isotipo + «SIGAT» + «MONITOREO / AGTECH»).
///     Se usa en tamaños grandes: bienvenida (splash) y login.
///   * [isotipoPath]: solo el isotipo. Se usa en tamaños pequeños (menú, contexto de
///     acceso, visor de documentos), donde el texto del logotipo no se alcanza a leer.
/// Los PNG salen de `src/assets/brand/*.svg` del front web.
/// Si el archivo falta, se dibuja [BrandIcon] para que la app no falle.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56, this.semanticLabel = 'Logo SIGAT · Vigilancia del durazno'});

  /// Alto del logo en píxeles lógicos. El ancho se ajusta solo.
  final double size;
  final String semanticLabel;

  static const assetPath = 'assets/images/sigat_logo_vertical.png';
  static const isotipoPath = 'assets/images/sigat_isotipo.png';

  /// Desde este alto se muestra el logotipo completo; por debajo, solo el isotipo.
  static const tamanoMinimoLogotipo = 96.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      size >= tamanoMinimoLogotipo ? assetPath : isotipoPath,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => BrandIcon(size: size),
    );
  }
}

/// Respaldo del logo: cuadro verde con ícono de hoja.
/// Se usa solo cuando el PNG del logo no está disponible.
class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 56, this.icon = Icons.eco_outlined});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * .25),
        boxShadow: AppShadows.brand,
      ),
      child: Icon(icon, color: Colors.white, size: size * .55),
    );
  }
}

/// Círculo suave con ícono (ej. sobre de "Recuperar acceso").
class SoftIconCircle extends StatelessWidget {
  const SoftIconCircle({super.key, required this.icon, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
      child: Icon(icon, size: size * .45, color: AppColors.primary),
    );
  }
}

/// Cabecera con foto del cultivo, logo, nombre de la app y etiqueta.
/// Se usa en las 3 variantes de login (normal, cargando, error).
class BrandHeroHeader extends StatelessWidget {
  const BrandHeroHeader({
    super.key,
    this.height = 310,
    this.logoSize = 132,
    this.title = 'Vigilancia Durazno',
    this.subtitle = 'Monitoreo fitosanitario',
    this.tag = 'Vigilancia fitosanitaria · Cultivo de durazno',
    this.imagePath = 'assets/images/login_hero.jpg',
  });

  final double height;

  /// Alto del logo dentro de la cabecera.
  final double logoSize;
  final String title;
  final String subtitle;
  final String tag;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetOrFallback(imagePath),
          // Velo blanco arriba para que el texto se lea + fundido abajo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .55, 1],
                colors: [AppColors.heroVeilTop, AppColors.heroVeilMid, Colors.white],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrandLogo(size: logoSize),
                  const SizedBox(height: 6),
                  Text(title, style: AppText.h1, textAlign: TextAlign.center),
                  Text(subtitle, style: AppText.bodySm, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TagPill(tag),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie "Conectado · también funciona sin conexión".
class ConnectionFooter extends StatelessWidget {
  const ConnectionFooter({super.key, required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOnline ? Icons.wifi : Icons.wifi_off, size: 13,
                color: isOnline ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            // Flexible: en pantallas angostas o con letra grande, el texto pasa
            // a una segunda línea en lugar de desbordarse.
            Flexible(
              child: Text(
                isOnline ? 'Conectado · también funciona sin conexión' : 'Sin conexión · modo offline activo',
                style: AppText.micro,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Avatar del usuario (Perfil, menú lateral web).
/// Muestra la fotografía cuando existe y, si no, las iniciales del nombre.
/// Con [onEdit] añade el botón de cámara para cambiarla.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 30,
    this.photoBytes,
    this.onEdit,
    this.isBusy = false,
  });

  final String name;
  final double radius;

  /// Fotografía del usuario. Null = se dibujan las iniciales.
  final Uint8List? photoBytes;

  /// Si se indica, se muestra el botón para cambiar la fotografía.
  final VoidCallback? onEdit;
  final bool isBusy;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryDark,
      foregroundImage: photoBytes == null ? null : MemoryImage(photoBytes!),
      child: photoBytes != null
          ? null
          : Text(initials(name), style: AppText.h1.copyWith(color: Colors.white, fontSize: radius * .66)),
    );

    if (onEdit == null && !isBusy) return avatar;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: avatar),
          if (isBusy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (onEdit != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isBusy ? null : onEdit,
                  child: Tooltip(
                    message: 'Cambiar fotografía',
                    child: Padding(
                      padding: EdgeInsets.all(radius * .18),
                      child: Icon(Icons.photo_camera_outlined, size: radius * .4, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
