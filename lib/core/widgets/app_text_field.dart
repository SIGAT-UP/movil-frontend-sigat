import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo de texto con etiqueta superior. Variantes: normal, contraseña,
/// multilínea (maxLines > 1), solo lectura y con error del servidor (hasError).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.isPassword = false,
    this.hasError = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.inputFormatters,
    this.helper,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final bool isPassword;

  /// Borde rojo aunque el validador pase (error que viene del servidor).
  final bool hasError;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  /// Texto de ayuda debajo del campo.
  final String? helper;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final errorBorder = widget.hasError
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.error),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.secondary),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscure,
          obscuringCharacter: '•',
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.maxLines > 1 ? widget.maxLines : null,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperStyle: AppText.micro,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: AppIconSize.md, color: AppColors.textSecondary),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: AppIconSize.md,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffix,
            enabledBorder: errorBorder,
            focusedBorder: errorBorder,
            disabledBorder: errorBorder,
          ),
        ),
      ],
    );
  }
}
