import 'dart:typed_data';

/// Quita los metadatos de una foto SIN recodificarla (no pierde calidad ni cambia los píxeles).
///
/// Por qué: las fotos del teléfono suelen traer EXIF con la ubicación GPS exacta, el modelo del
/// equipo y la fecha. Esa información no debe viajar ni guardarse con la evidencia.
///
/// * **JPEG:** elimina APP1 (EXIF/XMP), APP3–APP13 y APP15 (datos del fabricante, IPTC) y los
///   comentarios (COM). Conserva APP0 (JFIF), APP2 (perfil de color ICC) y APP14 (Adobe), que
///   afectan cómo se ven los colores. Si la foto tenía **orientación** EXIF, la vuelve a escribir
///   en un EXIF mínimo que contiene SOLO ese dato, para que la imagen no aparezca girada.
/// * **PNG:** elimina los fragmentos de texto y metadatos (`tEXt`, `zTXt`, `iTXt`, `eXIf`, `tIME`).
/// * **WebP:** elimina los fragmentos `EXIF` y `XMP ` y apaga sus banderas en `VP8X`.
///
/// Devuelve `null` si el archivo no tiene una estructura válida del formato indicado; quien llama
/// debe rechazar la imagen en ese caso (puede estar dañada o manipulada).
class ImageMetadata {
  ImageMetadata._();

  static Uint8List? strip(Uint8List bytes, String mimeType) => switch (mimeType) {
        'image/jpeg' => _jpeg(bytes),
        'image/png' => _png(bytes),
        'image/webp' => _webp(bytes),
        _ => null,
      };

  // ------------------------------------------------------------------ JPEG

  static Uint8List? _jpeg(Uint8List b) {
    if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
    final segmentos = BytesBuilder(copy: false);
    int? orientacion;
    Uint8List? app0;
    var i = 2;
    while (true) {
      if (i + 2 > b.length) return null;
      if (b[i] != 0xFF) return null;
      final marcador = b[i + 1];
      if (marcador == 0xFF) {
        i++; // byte de relleno permitido entre segmentos
        continue;
      }
      if (marcador == 0xD9) {
        // Fin de imagen sin datos de escaneo: no es una foto válida.
        return null;
      }
      if (marcador == 0x01 || (marcador >= 0xD0 && marcador <= 0xD7)) {
        segmentos.add(Uint8List.sublistView(b, i, i + 2));
        i += 2;
        continue;
      }
      if (i + 4 > b.length) return null;
      final largo = (b[i + 2] << 8) | b[i + 3];
      if (largo < 2 || i + 2 + largo > b.length) return null;
      final segmento = Uint8List.sublistView(b, i, i + 2 + largo);
      if (marcador == 0xDA) {
        // SOS: desde aquí van los datos comprimidos de la imagen; se copian tal cual hasta el final.
        final salida = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
        if (app0 != null) salida.add(app0);
        if (orientacion != null) salida.add(_exifSoloOrientacion(orientacion));
        salida.add(segmentos.takeBytes());
        salida.add(Uint8List.sublistView(b, i));
        return salida.takeBytes();
      }
      if (marcador == 0xE0 && app0 == null) {
        app0 = segmento; // JFIF va primero
      } else if (marcador == 0xE1) {
        orientacion ??= _orientacionExif(segmento);
      } else if (_esMetadatoJpeg(marcador)) {
        // se descarta
      } else {
        segmentos.add(segmento);
      }
      i += 2 + largo;
    }
  }

  static bool _esMetadatoJpeg(int marcador) =>
      marcador == 0xFE || // COM
      (marcador >= 0xE3 && marcador <= 0xED) || // APP3–APP13 (fabricante, IPTC)
      marcador == 0xEF; // APP15

  /// Lee la etiqueta Orientation (0x0112) del IFD0 de un segmento APP1 «Exif». Null si no hay.
  static int? _orientacionExif(Uint8List app1) {
    // FF E1 LL LL 'E' 'x' 'i' 'f' 00 00 | TIFF...
    const cab = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
    if (app1.length < 4 + 6 + 8) return null;
    for (var k = 0; k < cab.length; k++) {
      if (app1[4 + k] != cab[k]) return null;
    }
    final tiff = Uint8List.sublistView(app1, 10);
    final Endian orden;
    if (tiff[0] == 0x49 && tiff[1] == 0x49) {
      orden = Endian.little;
    } else if (tiff[0] == 0x4D && tiff[1] == 0x4D) {
      orden = Endian.big;
    } else {
      return null;
    }
    final d = ByteData.sublistView(tiff);
    if (d.getUint16(2, orden) != 42) return null;
    final ifd0 = d.getUint32(4, orden);
    if (ifd0 + 2 > tiff.length) return null;
    final entradas = d.getUint16(ifd0, orden);
    for (var n = 0; n < entradas; n++) {
      final p = ifd0 + 2 + n * 12;
      if (p + 12 > tiff.length) return null;
      if (d.getUint16(p, orden) == 0x0112 && d.getUint16(p + 2, orden) == 3) {
        final valor = d.getUint16(p + 8, orden);
        return (valor >= 1 && valor <= 8) ? valor : null;
      }
    }
    return null;
  }

  /// APP1 «Exif» mínimo (little endian) con una sola etiqueta: Orientation.
  static Uint8List _exifSoloOrientacion(int orientacion) {
    final d = ByteData(36);
    d.setUint8(0, 0xFF);
    d.setUint8(1, 0xE1);
    d.setUint16(2, 34); // largo del segmento sin el marcador
    const exif = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
    for (var k = 0; k < exif.length; k++) {
      d.setUint8(4 + k, exif[k]);
    }
    // Encabezado TIFF: "II", 42, IFD0 en el byte 8.
    d.setUint8(10, 0x49);
    d.setUint8(11, 0x49);
    d.setUint16(12, 42, Endian.little);
    d.setUint32(14, 8, Endian.little);
    // IFD0: 1 entrada.
    d.setUint16(18, 1, Endian.little);
    d.setUint16(20, 0x0112, Endian.little); // Orientation
    d.setUint16(22, 3, Endian.little); // SHORT
    d.setUint32(24, 1, Endian.little); // cantidad
    d.setUint16(28, orientacion, Endian.little);
    d.setUint16(30, 0, Endian.little);
    d.setUint32(32, 0, Endian.little); // no hay más IFD
    return d.buffer.asUint8List();
  }

  // ------------------------------------------------------------------ PNG

  static const _firmaPng = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  static const _metadatosPng = {'tEXt', 'zTXt', 'iTXt', 'eXIf', 'tIME'};

  static Uint8List? _png(Uint8List b) {
    if (b.length < 8) return null;
    for (var k = 0; k < 8; k++) {
      if (b[k] != _firmaPng[k]) return null;
    }
    final salida = BytesBuilder(copy: false)..add(Uint8List.sublistView(b, 0, 8));
    final d = ByteData.sublistView(b);
    var i = 8;
    var vioFin = false;
    while (i + 12 <= b.length) {
      final largo = d.getUint32(i);
      if (i + 12 + largo > b.length) return null;
      final tipo = String.fromCharCodes(b, i + 4, i + 8);
      if (!_metadatosPng.contains(tipo)) {
        salida.add(Uint8List.sublistView(b, i, i + 12 + largo));
      }
      i += 12 + largo;
      if (tipo == 'IEND') {
        vioFin = true;
        break;
      }
    }
    return vioFin ? salida.takeBytes() : null;
  }

  // ------------------------------------------------------------------ WebP

  static Uint8List? _webp(Uint8List b) {
    if (b.length < 12) return null;
    if (String.fromCharCodes(b, 0, 4) != 'RIFF' || String.fromCharCodes(b, 8, 12) != 'WEBP') return null;
    final d = ByteData.sublistView(b);
    final finRiff = 8 + d.getUint32(4, Endian.little);
    if (finRiff > b.length) return null;
    final cuerpo = BytesBuilder(copy: false)..add(const [0x57, 0x45, 0x42, 0x50]); // 'WEBP'
    var i = 12;
    while (i + 8 <= finRiff) {
      final tipo = String.fromCharCodes(b, i, i + 4);
      final largo = d.getUint32(i + 4, Endian.little);
      final total = 8 + largo + (largo.isOdd ? 1 : 0);
      if (i + 8 + largo > finRiff) return null;
      final fin = i + total > finRiff ? finRiff : i + total;
      if (tipo == 'EXIF' || tipo == 'XMP ') {
        // se descarta
      } else if (tipo == 'VP8X' && largo >= 1) {
        final copia = Uint8List.fromList(b.sublist(i, fin));
        copia[8] = copia[8] & ~0x0C; // apaga las banderas EXIF (0x08) y XMP (0x04)
        cuerpo.add(copia);
      } else {
        cuerpo.add(Uint8List.sublistView(b, i, fin));
      }
      i += total;
    }
    final datos = cuerpo.takeBytes();
    final cab = ByteData(8);
    cab.setUint8(0, 0x52);
    cab.setUint8(1, 0x49);
    cab.setUint8(2, 0x46);
    cab.setUint8(3, 0x46); // 'RIFF'
    cab.setUint32(4, datos.length, Endian.little);
    return (BytesBuilder(copy: false)
          ..add(cab.buffer.asUint8List())
          ..add(datos))
        .takeBytes();
  }
}
