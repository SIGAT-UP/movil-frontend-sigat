import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Indicador MTD (moscas / trampa / día).
/// * Grande: cifra + unidad + badge de umbral (hoja del lote en el mapa).
/// * Compacto: "Último MTD: 0,35" + aclaración (inicio del productor).
/// No calcula nada: muestra el valor y el texto de umbral que vengan de los datos.
class MtdIndicator extends StatelessWidget {
  const MtdIndicator({
    super.key,
    required this.value,
    this.thresholdLabel,
    this.thresholdTone = StatusTone.success,
    this.compact = false,
    this.note,
  });

  /// null = no existe un cálculo válido.
  final double? value;

  /// Texto del umbral tal como lo entrega el servidor (ej. "Cumple umbral").
  final String? thresholdLabel;
  final StatusTone thresholdTone;
  final bool compact;

  /// Aclaración pequeña (ej. "si existe un cálculo válido").
  final String? note;

  static const unit = 'moscas / trampa / día';

  String get _text => value == null ? 'Sin cálculo válido' : Fmt.fixed(value!, 2);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Último MTD: $_text', style: AppText.bodySmStrong, textAlign: TextAlign.right),
          if (note != null) Text(note!, style: AppText.micro, textAlign: TextAlign.right),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_text, style: AppText.display),
              const Text(unit, style: AppText.micro),
            ],
          ),
        ),
        if (thresholdLabel != null) StatusBadge(thresholdLabel!, tone: thresholdTone, icon: Icons.check),
      ],
    );
  }
}
