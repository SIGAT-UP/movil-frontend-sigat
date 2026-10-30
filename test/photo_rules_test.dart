import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/models/photo_file.dart';

/// El tipo de imagen se deduce del CONTENIDO, no de la extensión del archivo.
void main() {
  Uint8List bytesOf(List<int> head, {int padding = 32}) =>
      Uint8List.fromList([...head, ...List.filled(padding, 0)]);

  group('PhotoRules.sniffMimeType', () {
    test('reconoce JPEG', () {
      expect(PhotoRules.sniffMimeType(bytesOf([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    });

    test('reconoce PNG', () {
      expect(
        PhotoRules.sniffMimeType(bytesOf([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])),
        'image/png',
      );
    });

    test('reconoce WebP', () {
      final webp = bytesOf([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00, // tamaño
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(PhotoRules.sniffMimeType(webp), 'image/webp');
    });

    test('rechaza un archivo de texto aunque se llame .jpg', () {
      final texto = Uint8List.fromList('esto no es una imagen'.codeUnits);
      expect(PhotoRules.sniffMimeType(texto), isNull);
    });

    test('rechaza un archivo demasiado corto', () {
      expect(PhotoRules.sniffMimeType(Uint8List.fromList([0xFF, 0xD8])), isNull);
    });
  });

  group('PhotoRules.sizeLabel', () {
    test('muestra kilobytes bajo 1 MB', () {
      expect(PhotoRules.sizeLabel(2048), '2 KB');
    });

    test('muestra megabytes con coma decimal', () {
      expect(PhotoRules.sizeLabel(2 * 1024 * 1024), '2,0 MB');
      expect(PhotoRules.sizeLabel(PhotoRules.maxBytes), '8,0 MB');
    });
  });
}
