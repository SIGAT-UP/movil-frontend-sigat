import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/lot_summary.dart';

/// Tendencia del MTD con la línea de referencia del escenario.
///
/// Decisiones de lectura:
///  * UNA sola serie, así que no lleva caja de leyenda: el título la nombra.
///  * El umbral es una línea de REFERENCIA discontinua, no una segunda serie.
///  * Un solo eje. Rejilla y ejes discretos para que la curva mande.
///  * Solo se rotula el último valor, no todos los puntos.
///  * El texto va en los colores de tinta del sistema, nunca en el color de la serie.
class MtdChart extends StatelessWidget {
  const MtdChart({
    super.key,
    required this.series,
    required this.limit,
    this.limitLabel = 'Límite de escenario',
    this.height = 150,
  });

  final List<MtdPoint> series;

  /// Valor del umbral del escenario vigente.
  final double limit;
  final String limitLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Todavía no hay suficientes lecturas para dibujar la tendencia.',
              textAlign: TextAlign.center, style: AppText.caption),
        ),
      );
    }

    final ultimo = series.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Referencia del umbral, descrita con texto y no solo con color.
        Row(
          children: [
            Container(width: 14, height: 2, color: AppColors.warningStrong),
            const SizedBox(width: 6),
            Text('$limitLabel ${Fmt.decimal(limit)}', style: AppText.micro),
            const Spacer(),
            Text('MTD actual ${Fmt.fixed(ultimo.value, 2)}',
                style: AppText.micro.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Tendencia del MTD. Último valor ${Fmt.fixed(ultimo.value, 2)} '
              'moscas por trampa y día, con un límite de escenario de ${Fmt.decimal(limit)}.',
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: _MtdPainter(series: series, limit: limit)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Fmt.dayMonth(series.first.date), style: AppText.micro),
            Text(Fmt.dayMonth(ultimo.date), style: AppText.micro),
          ],
        ),
      ],
    );
  }
}

class _MtdPainter extends CustomPainter {
  _MtdPainter({required this.series, required this.limit});

  final List<MtdPoint> series;
  final double limit;

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 14.0;
    const padBottom = 6.0;
    const padRight = 44.0; // espacio para el rótulo del último valor

    final maxY = [
      for (final p in series) p.value,
      limit,
    ].reduce((a, b) => a > b ? a : b);
    final techo = maxY <= 0 ? 1.0 : maxY * 1.25;
    final ancho = size.width - padRight;
    final alto = size.height - padTop - padBottom;

    double x(int i) => ancho * (i / (series.length - 1));
    double y(double v) => padTop + alto - (alto * (v / techo));

    // --- Rejilla discreta: 3 líneas horizontales ---
    final rejilla = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final yy = padTop + alto * (i / 2);
      canvas.drawLine(Offset(0, yy), Offset(ancho, yy), rejilla);
    }

    // --- Área bajo la curva, muy tenue ---
    final area = Path()..moveTo(0, padTop + alto);
    for (var i = 0; i < series.length; i++) {
      area.lineTo(x(i), y(series[i].value));
    }
    area
      ..lineTo(ancho, padTop + alto)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.primary.withValues(alpha: .10));

    // --- Línea de referencia del umbral (discontinua) ---
    final yLimite = y(limit);
    final trazo = Paint()
      ..color = AppColors.warningStrong
      ..strokeWidth = 1.5;
    for (double dx = 0; dx < ancho; dx += 8) {
      canvas.drawLine(Offset(dx, yLimite), Offset((dx + 4).clamp(0, ancho), yLimite), trazo);
    }

    // --- La serie: línea de 2 px ---
    final linea = Path()..moveTo(0, y(series.first.value));
    for (var i = 1; i < series.length; i++) {
      linea.lineTo(x(i), y(series[i].value));
    }
    canvas.drawPath(
      linea,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // --- Último punto: marcador con anillo blanco para que se separe del área ---
    final ultimo = Offset(x(series.length - 1), y(series.last.value));
    canvas.drawCircle(ultimo, 6, Paint()..color = Colors.white);
    canvas.drawCircle(ultimo, 4.5, Paint()..color = AppColors.primary);

    // --- Rótulo solo del último valor ---
    final texto = TextPainter(
      text: TextSpan(
        text: series.last.value.toStringAsFixed(2).replaceAll('.', ','),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    texto.paint(canvas, Offset(ultimo.dx + 9, ultimo.dy - texto.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MtdPainter old) => old.series != series || old.limit != limit;
}
