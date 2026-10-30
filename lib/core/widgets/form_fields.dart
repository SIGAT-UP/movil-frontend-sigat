import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'app_text_field.dart';

/// Etiqueta pequeña sobre un campo.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: AppText.secondary));
}

/// Texto de error bajo un campo que no es TextFormField (fecha, selección).
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Text(text, style: AppText.caption.copyWith(color: AppColors.error)),
      );
}

/// Campo numérico. `decimals: 0` = enteros. Acepta coma o punto decimal.
/// Usa [AppNumberField.parse] para convertir el texto a número.
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.decimals = 0,
    this.required = true,
    this.min,
    this.max,
    this.unit,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int decimals;
  final bool required;
  final double? min;
  final double? max;

  /// Sufijo visible (kg, ha, ml/L).
  final String? unit;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  static double? parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validate(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return required ? 'Campo obligatorio' : null;
    final n = parse(text);
    if (n == null) return 'Número no válido';
    if (min != null && n < min!) return 'Debe ser mayor o igual a ${Fmt.decimal(min!)}';
    if (max != null && n > max!) return 'Debe ser menor o igual a ${Fmt.decimal(max!)}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hint: hint,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [_NumberFormatter(decimals)],
      validator: _validate,
      suffix: unit == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Align(widthFactor: 1, child: Text(unit!, style: AppText.secondary)),
            ),
    );
  }
}

class _NumberFormatter extends TextInputFormatter {
  _NumberFormatter(this.decimals);
  final int decimals;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final re = decimals == 0 ? RegExp(r'^\d*$') : RegExp('^\\d*([.,]\\d{0,$decimals})?\$');
    return re.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

/// Buscador con lupa ("Buscar lote, productor o código").
class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, required this.hint, required this.onChanged, this.controller});

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: AppIconSize.md, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Campo de fecha (dd / mm / aaaa) con selector nativo.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
    this.firstDate,
    this.lastDate,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool optional;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Mensaje de validación (la fecha no es un TextFormField).
  final String? errorText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 2);
    final last = lastDate ?? DateTime(now.year + 1);
    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(optional ? '$label (opcional)' : label),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              enabled: enabled,
              errorText: errorText,
              errorStyle: AppText.caption.copyWith(color: AppColors.error),
              suffixIcon: value != null && optional && enabled
                  ? IconButton(
                      tooltip: 'Borrar fecha',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            ),
            child: Text(
              value == null ? 'dd / mm / aaaa' : Fmt.dateNumeric(value!),
              style: AppText.body.copyWith(color: value == null ? AppColors.textHint : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de solo lectura gris (ej. "Hora (automática)").
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        InputDecorator(
          decoration: const InputDecoration(fillColor: AppColors.surface),
          child: Text(value, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

/// Lista desplegable con etiqueta (ej. "Estado de la trampa").
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: AppText.body,
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(itemLabel(i)))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// Casilla con texto (ej. "Recordar usuario"). Toda la fila es pulsable.
class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;

  /// null = deshabilitada.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false)),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppText.bodySm),
          ],
        ),
      ),
    );
  }
}
