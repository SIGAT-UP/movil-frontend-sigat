import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'models/lot_summary.dart';
import 'models/planning.dart';

/// Genera los PDF de la app y abre el diálogo del sistema para guardarlos,
/// compartirlos o imprimirlos.
///
/// Es trabajo del dispositivo: NO hay servidor de por medio. El contenido sale
/// de los datos que ya tiene la app en pantalla.
class PdfService {
  PdfService._();
  static final instance = PdfService._();

  static const _verde = PdfColor.fromInt(0xFF0B8A4E);
  static const _verdeOscuro = PdfColor.fromInt(0xFF1E5E3B);
  static const _gris = PdfColor.fromInt(0xFF6B7370);
  static const _borde = PdfColor.fromInt(0xFFDADFDC);

  /// Resumen fitosanitario del lote.
  Future<void> exportLotSummary(LotSummary s) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _encabezado('Resumen fitosanitario', s.lotName),
          pw.SizedBox(height: 18),
          _bloque('Estado actual', [
            ['Escenario', s.scenario],
            ['MTD (último periodo cerrado)', s.mtd == null ? 'Sin cálculo válido' : _dec(s.mtd!)],
            ['Umbral de exportación', s.exportThreshold],
            ['Concepto de aptitud', s.aptitudeConcept],
          ]),
          pw.SizedBox(height: 14),
          _bloque('Vigilancia', [
            ['Trampas configuradas', '${s.trapsTotal}'],
            ['Última visita', s.lastVisit == null ? 'Sin visitas' : _fecha(s.lastVisit!)],
            ['Inspecciones este mes', '${s.inspectionsThisMonth}'],
            ['Lecturas totales', '${s.readingsTotal}'],
            ['Especímenes detectados', '${s.specimensDetected}'],
            ['Trampas con hallazgos', '${s.trapsWithFindings}'],
            ['Hallazgos vigentes', '${s.activeFindings}'],
          ]),
          pw.SizedBox(height: 14),
          _bloque('Cultivo', [
            ['Etapa fenológica', s.phenologicalStage],
            ['Aplicaciones registradas', '${s.applications}'],
            ['Última aplicación', s.lastApplication == null ? 'Sin aplicaciones' : _fecha(s.lastApplication!)],
            ['Buenas prácticas', s.goodPracticesLabel],
            ['Producción estimada', s.estimatedYieldKg == null ? 'Sin registrar' : '${_dec(s.estimatedYieldKg!)} kg'],
            ['Producción real', s.actualYieldKg == null ? 'Sin registrar' : '${_dec(s.actualYieldKg!)} kg'],
            ['Cosecha esperada', s.expectedHarvest == null ? 'Sin registrar' : _fecha(s.expectedHarvest!)],
          ]),
          if (s.series.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _bloqueTexto(
              'Tendencia del MTD',
              s.series.map((p) => '${_fechaCorta(p.date)}: ${_dec(p.value)}').join('   ·   '),
            ),
          ],
          pw.SizedBox(height: 22),
          _pie(),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'resumen_${s.lotName.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
  }

  /// Documento de instrucciones de una planificación.
  /// Es un documento GENERADO por la app con los datos de la planificación, no el
  /// archivo original (el servidor todavía no entrega los documentos: falta `/archivos`).
  Future<void> exportInstructions(Planning p) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _encabezado('Instrucciones', p.activity),
          pw.SizedBox(height: 18),
          _bloque('Datos de la planificación', [
            ['Dirigida a', p.recipientName],
            ['Tipo', p.target.label],
            ['Fecha de inicio', _fecha(p.startDate)],
            if (p.endDate != null) ['Fecha de finalización', _fecha(p.endDate!)],
            if (p.scheduleFrom != null) ['Horario', '${p.scheduleFrom} – ${p.scheduleTo ?? ''}'],
            if (p.lotNames.isNotEmpty) ['Lotes', p.lotNames.join(', ')],
            ['Creada por', p.createdByName],
            ['Estado', p.status.label],
          ]),
          if (p.observations != null && p.observations!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _bloqueTexto('Observaciones del agrónomo', p.observations!),
          ],
          if (p.rejectionReason != null) ...[
            pw.SizedBox(height: 14),
            _bloqueTexto('Motivo del rechazo', p.rejectionReason!),
          ],
          pw.SizedBox(height: 22),
          _pie(),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: p.doc?.fileName ?? 'instrucciones.pdf',
    );
  }

  /// ¿Se puede descargar el documento de esta planificación desde la app?
  /// Un Word no: la app no puede convertirlo ni mostrarlo.
  bool canDownloadInstructions(Planning p) => p.doc?.kind != DocKind.word;

  /// Descarga o comparte el documento de instrucciones:
  ///  * PDF elegido en el dispositivo → el archivo ORIGINAL, sin tocarlo.
  ///  * Imagen elegida en el dispositivo → un PDF con esa imagen.
  ///  * Sin archivo en el dispositivo (archivo del servidor sin descargar) →
  ///    un PDF generado con los datos de la planificación.
  Future<void> downloadInstructions(Planning p) async {
    final d = p.doc;
    final bytes = d?.bytes;
    if (d != null && bytes != null) {
      if (d.kind == DocKind.pdf) {
        await Printing.sharePdf(bytes: bytes, filename: d.fileName);
        return;
      }
      if (d.kind == DocKind.imagen) {
        final doc = pw.Document();
        final imagen = pw.MemoryImage(bytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (_) => pw.Center(child: pw.Image(imagen, fit: pw.BoxFit.contain)),
          ),
        );
        await Printing.sharePdf(bytes: await doc.save(), filename: _comoPdf(d.fileName));
        return;
      }
      throw UnsupportedError('Los documentos Word no se pueden descargar desde la app.');
    }
    await exportInstructions(p);
  }

  String _comoPdf(String nombre) {
    final punto = nombre.lastIndexOf('.');
    return '${punto > 0 ? nombre.substring(0, punto) : nombre}.pdf';
  }

  // ---------------- piezas del documento ----------------

  pw.Widget _encabezado(String titulo, String subtitulo) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VIGILANCIA DURAZNO',
            style: const pw.TextStyle(
              fontSize: 10,
              color: _verde,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            titulo,
            style: const pw.TextStyle(
              fontSize: 22,
              color: _verdeOscuro,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            subtitulo,
            style: const pw.TextStyle(fontSize: 13, color: _gris),
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 2, color: _verde),
        ],
      );

  pw.Widget _bloque(String titulo, List<List<String>> filas) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 9,
              color: _verde,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: .8,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _borde, width: .5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(4),
            },
            children: [
              for (final f in filas)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(
                        f[0],
                        style: const pw.TextStyle(fontSize: 10, color: _gris),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text(
                        f[1],
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );

  pw.Widget _bloqueTexto(String titulo, String texto) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 9,
              color: _verde,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: .8,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borde, width: .5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              texto,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      );

  pw.Widget _pie() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        color: const PdfColor.fromInt(0xFFF7F8F7),
        child: pw.Text(
          'Documento generado por la aplicación con los datos que entregó el servidor SIGAT. '
          'Este documento es generado por SIGAT con fines informativos y de seguimiento. No constituye un documento oficial ni reemplaza las certificaciones emitidas por las autoridades competentes.',
          style: const pw.TextStyle(fontSize: 8, color: _gris),
        ),
      );

  // ---------------- formatos ----------------

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]} ${d.year}';

  String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]}';

  String _dec(num v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s.replaceAll('.', ',');
  }
}
