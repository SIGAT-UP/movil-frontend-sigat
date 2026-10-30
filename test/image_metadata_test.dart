import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/image_metadata.dart';

/// Privacidad de las fotos: se quitan EXIF/GPS, XMP, comentarios y textos sin tocar la imagen.
/// El algoritmo también se verificó con imágenes reales (ver auditorias/evidencia/verificacion_metadatos).
void main() {
  bool contiene(Uint8List b, List<int> patron) {
    for (var i = 0; i + patron.length <= b.length; i++) {
      var ok = true;
      for (var k = 0; k < patron.length; k++) {
        if (b[i + k] != patron[k]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  List<int> segmento(int marcador, List<int> datos) =>
      [0xFF, marcador, (datos.length + 2) >> 8, (datos.length + 2) & 0xFF, ...datos];

  // EXIF little endian con Orientation=6 y el texto «GPS-SECRETO» en un valor ASCII.
  List<int> exif() {
    final secreto = ascii.encode('GPS-SECRETO\u0000');
    final b = BytesBuilder()
      ..add(ascii.encode('Exif'))
      ..add([0, 0])
      ..add([0x49, 0x49, 42, 0, 8, 0, 0, 0]) // II, 42, IFD0 en 8
      ..add([2, 0]) // 2 entradas
      ..add([0x12, 0x01, 3, 0, 1, 0, 0, 0, 6, 0, 0, 0]) // Orientation = 6
      ..add([0x0F, 0x01, 2, 0, secreto.length, 0, 0, 0, 38, 0, 0, 0]) // Make -> offset 38
      ..add([0, 0, 0, 0])
      ..add(secreto);
    return b.takeBytes();
  }

  final escaneo = [0xFF, 0xDA, 0x00, 0x08, 1, 1, 0, 0, 0x3F, 0, 0x12, 0x34, 0x56, 0xFF, 0xD9];

  Uint8List jpeg({bool conExif = true}) => Uint8List.fromList([
        0xFF, 0xD8,
        ...segmento(0xE0, ascii.encode('JFIF\u0000')),
        if (conExif) ...segmento(0xE1, exif()),
        ...segmento(0xE1, ascii.encode('http://ns.adobe.com/xap/1.0/\u0000<x:xmpmeta>XMP-SECRETO</x:xmpmeta>')),
        ...segmento(0xFE, ascii.encode('COMENTARIO-SECRETO')),
        ...segmento(0xDB, List.filled(65, 1)),
        ...escaneo,
      ]);

  group('JPEG', () {
    test('quita EXIF, XMP y comentarios; conserva JFIF, tablas y datos de la imagen', () {
      final limpio = ImageMetadata.strip(jpeg(), 'image/jpeg')!;
      expect(contiene(limpio, ascii.encode('GPS-SECRETO')), isFalse);
      expect(contiene(limpio, ascii.encode('XMP-SECRETO')), isFalse);
      expect(contiene(limpio, ascii.encode('COMENTARIO-SECRETO')), isFalse);
      expect(contiene(limpio, ascii.encode('JFIF')), isTrue);
      expect(contiene(limpio, escaneo), isTrue);
      expect(limpio.sublist(0, 2), [0xFF, 0xD8]);
    });

    test('vuelve a escribir solo la orientación para que la foto no aparezca girada', () {
      final limpio = ImageMetadata.strip(jpeg(), 'image/jpeg')!;
      // Entrada IFD: tag 0x0112, tipo SHORT, cantidad 1, valor 6 (little endian).
      expect(contiene(limpio, [0x12, 0x01, 3, 0, 1, 0, 0, 0, 6, 0]), isTrue);
    });

    test('sin EXIF original no agrega ninguno', () {
      final limpio = ImageMetadata.strip(jpeg(conExif: false), 'image/jpeg')!;
      expect(contiene(limpio, ascii.encode('Exif')), isFalse);
    });

    test('un JPEG truncado o manipulado se rechaza (null)', () {
      final original = jpeg();
      expect(ImageMetadata.strip(Uint8List.sublistView(original, 0, 30), 'image/jpeg'), isNull);
      expect(ImageMetadata.strip(Uint8List.fromList([0xFF, 0xD8, 0, 0, 0, 0]), 'image/jpeg'), isNull);
    });
  });

  group('PNG', () {
    List<int> trozo(String tipo, List<int> datos) => [
          ...[datos.length >> 24, (datos.length >> 16) & 0xFF, (datos.length >> 8) & 0xFF, datos.length & 0xFF],
          ...ascii.encode(tipo),
          ...datos,
          0, 0, 0, 0, // CRC (no se valida aquí)
        ];
    final firma = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    test('quita tEXt, iTXt y eXIf; conserva IHDR, IDAT e IEND', () {
      final png = Uint8List.fromList([
        ...firma,
        ...trozo('IHDR', List.filled(13, 0)),
        ...trozo('tEXt', ascii.encode('Location\u0000PNG-SECRETO')),
        ...trozo('eXIf', exif()),
        ...trozo('IDAT', [1, 2, 3]),
        ...trozo('IEND', const []),
      ]);
      final limpio = ImageMetadata.strip(png, 'image/png')!;
      expect(contiene(limpio, ascii.encode('PNG-SECRETO')), isFalse);
      expect(contiene(limpio, ascii.encode('eXIf')), isFalse);
      expect(contiene(limpio, ascii.encode('IDAT')), isTrue);
      expect(contiene(limpio, ascii.encode('IEND')), isTrue);
    });

    test('un PNG sin IEND se rechaza', () {
      final png = Uint8List.fromList([...firma, ...trozo('IHDR', List.filled(13, 0))]);
      expect(ImageMetadata.strip(png, 'image/png'), isNull);
    });
  });

  group('WebP', () {
    List<int> trozo(String tipo, List<int> datos) => [
          ...ascii.encode(tipo),
          datos.length & 0xFF, (datos.length >> 8) & 0xFF, 0, 0,
          ...datos,
          if (datos.length.isOdd) 0,
        ];

    test('quita EXIF y XMP, apaga sus banderas en VP8X y corrige el tamaño RIFF', () {
      final cuerpo = [
        ...ascii.encode('WEBP'),
        ...trozo('VP8X', [0x0C, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        ...trozo('VP8L', [1, 2, 3, 4, 5]),
        ...trozo('EXIF', exif()),
        ...trozo('XMP ', ascii.encode('<x:xmpmeta>WEBP-SECRETO</x:xmpmeta>')),
      ];
      final webp = Uint8List.fromList([
        ...ascii.encode('RIFF'),
        cuerpo.length & 0xFF, (cuerpo.length >> 8) & 0xFF, 0, 0,
        ...cuerpo,
      ]);
      final limpio = ImageMetadata.strip(webp, 'image/webp')!;
      expect(contiene(limpio, ascii.encode('EXIF')), isFalse);
      expect(contiene(limpio, ascii.encode('WEBP-SECRETO')), isFalse);
      expect(contiene(limpio, ascii.encode('VP8L')), isTrue);
      final d = ByteData.sublistView(limpio);
      expect(d.getUint32(4, Endian.little) + 8, limpio.length);
      expect(limpio[20] & 0x0C, 0); // banderas EXIF/XMP apagadas (VP8X empieza en el byte 12)
    });
  });
}
