import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/core/utils/formatters.dart';
import 'package:vigilancia_durazno/data/document_service.dart';
import 'package:vigilancia_durazno/data/models/planning.dart';

/// Documentos de instrucciones: el tipo se deduce del CONTENIDO del archivo,
/// nunca de la extensión del nombre.
void main() {
  Uint8List bytes(List<int> head, [String rest = '']) =>
      Uint8List.fromList([...head, ...ascii.encode(rest), ...List.filled(16, 0)]);

  const pdf = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
  const zip = [0x50, 0x4B, 0x03, 0x04]; // PK..
  const ole = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
  const jpeg = [0xFF, 0xD8, 0xFF, 0xE0];

  group('DocumentRules.sniff', () {
    test('reconoce un PDF', () {
      expect(DocumentRules.sniff(bytes(pdf, '1.7 ...'), 'instrucciones.pdf'), DocKind.pdf);
    });

    test('reconoce un .docx (ZIP con la carpeta word/)', () {
      expect(DocumentRules.sniff(bytes(zip, '....word/document.xml'), 'plan.docx'), DocKind.word);
    });

    test('rechaza un ZIP que no es Word aunque se llame .docx', () {
      expect(DocumentRules.sniff(bytes(zip, '....xl/workbook.xml'), 'plan.docx'), isNull);
    });

    test('acepta un .doc antiguo solo si la extensión es .doc', () {
      expect(DocumentRules.sniff(bytes(ole), 'plan.doc'), DocKind.word);
      // El mismo contenedor lo usan Excel y PowerPoint antiguos.
      expect(DocumentRules.sniff(bytes(ole), 'tabla.xls'), isNull);
    });

    test('rechaza una imagen renombrada como .pdf', () {
      expect(DocumentRules.sniff(bytes(jpeg), 'trampa.pdf'), isNull);
    });

    test('rechaza archivos demasiado cortos o vacíos', () {
      expect(DocumentRules.sniff(Uint8List(0), 'vacio.pdf'), isNull);
      expect(DocumentRules.sniff(Uint8List.fromList([0x25, 0x50]), 'corto.pdf'), isNull);
    });
  });

  group('DocumentRules.countPdfPages', () {
    test('cuenta los objetos /Type /Page y no el árbol /Pages', () {
      const contenido = '%PDF-1.4\n'
          '1 0 obj << /Type /Pages /Count 3 >> endobj\n'
          '2 0 obj << /Type /Page >> endobj\n'
          '3 0 obj << /Type/Page >> endobj\n'
          '4 0 obj << /Type /Page /Parent 1 0 R >> endobj\n';
      expect(DocumentRules.countPdfPages(Uint8List.fromList(latin1.encode(contenido))), 3);
    });

    test('devuelve null si no puede contarlas', () {
      expect(DocumentRules.countPdfPages(bytes(pdf, 'comprimido')), isNull);
    });
  });

  group('PlanningDoc', () {
    test('el contenido del archivo NO viaja en el JSON', () {
      final doc = PlanningDoc(
        id: 'd',
        fileName: 'x.pdf',
        sizeBytes: 10,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(doc.hasLocalFile, isTrue);
      expect(doc.toJson().containsKey('bytes'), isFalse);
      expect(doc.toJson()['kind'], 'pdf');
    });

    test('desde el servidor sin "kind", el tipo se deduce de la extensión', () {
      final doc = PlanningDoc.fromJson({'id': 1, 'file_name': 'Plan.DOCX', 'size_bytes': 2048});
      expect(doc.kind, DocKind.word);
      expect(doc.hasLocalFile, isFalse);
    });

    test('rótulo en singular y plural', () {
      const una = PlanningDoc(id: 'a', fileName: 'a.pdf', sizeBytes: 2048, pages: 1);
      const tres = PlanningDoc(id: 'b', fileName: 'b.pdf', sizeBytes: 2048, pages: 3);
      expect(una.detailLabel, startsWith('1 página ·'));
      expect(tres.detailLabel, startsWith('3 páginas ·'));
    });
  });

  group('Fechas de "Mis planificaciones"', () {
    test('día de la semana completo', () {
      expect(Fmt.weekdayDate(DateTime(2026, 11, 16)), 'Lunes, 16 nov. 2026');
      expect(Fmt.weekdayDate(DateTime(2026, 11, 18)), 'Miércoles, 18 nov. 2026');
    });

    test('fecha y hora de la respuesta', () {
      expect(Fmt.dateTime24(DateTime(2026, 11, 13, 14, 32)), '13 nov. 2026 – 14:32');
    });
  });
}
