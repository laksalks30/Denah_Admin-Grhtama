import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebPickedFile {
  final Uint8List bytes;
  final String name;

  WebPickedFile({required this.bytes, required this.name});
}

/// Helper utilitas Web berkecepatan tinggi untuk pemilih file & kompresi gambar kanvas
class WebImageUtils {
  /// Memilih foto langsung menggunakan HTML5 <input type="file"> resmi browser
  /// Sangat stabil, responsif, dan didukung oleh semua browser (Android Chrome, Edge, Safari, iOS).
  static Future<List<WebPickedFile>> pickImagesWeb({
    bool allowMultiple = true,
    bool isCamera = false,
  }) async {
    final completer = Completer<List<WebPickedFile>>();

    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*'
      ..multiple = allowMultiple;

    if (isCamera) {
      input.setAttribute('capture', 'environment');
    }

    input.style.display = 'none';
    web.document.body?.append(input);

    input.onchange = (web.Event _) {
      () async {
        final fileList = input.files;
        final results = <WebPickedFile>[];

        if (fileList != null && fileList.length > 0) {
          for (int i = 0; i < fileList.length; i++) {
            final file = fileList.item(i);
            if (file != null) {
              final reader = web.FileReader();
              final readCompleter = Completer<Uint8List>();

              reader.onload = (web.Event _) {
                try {
                  final arrayBuf = (reader.result as JSArrayBuffer).toDart;
                  readCompleter.complete(arrayBuf.asUint8List());
                } catch (e) {
                  readCompleter.complete(Uint8List(0));
                }
              }.toJS;

              reader.onerror = (web.Event _) {
                readCompleter.complete(Uint8List(0));
              }.toJS;

              reader.readAsArrayBuffer(file);
              final rawBytes = await readCompleter.future;

              if (rawBytes.isNotEmpty) {
                // Otomatis kompresi langsung ke JPEG resolusi optimal
                final compressed = await compressToJpeg(rawBytes);
                results.add(WebPickedFile(bytes: compressed, name: file.name));
              }
            }
          }
        }

        input.remove();
        if (!completer.isCompleted) completer.complete(results);
      }();
    }.toJS;

    input.oncancel = (web.Event _) {
      input.remove();
      if (!completer.isCompleted) completer.complete([]);
    }.toJS;

    // Trigger klik langsung
    input.click();

    return completer.future;
  }

  /// Mengompresi gambar apapun menjadi format JPEG efisien (~50KB - 90KB)
  /// menggunakan akselerasi grafis HTML5 Canvas di browser.
  static Future<Uint8List> compressToJpeg(
    Uint8List rawBytes, {
    int maxDimension = 1000,
    double quality = 0.72,
  }) async {
    if (!kIsWeb) return rawBytes;

    try {
      final blob = web.Blob(
        [rawBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'image/jpeg'),
      );
      final blobUrl = web.URL.createObjectURL(blob);

      final img = web.HTMLImageElement();
      final completer = Completer<void>();

      img.onload = (web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }.toJS;

      img.onerror = (web.Event _) {
        if (!completer.isCompleted) completer.completeError('Failed to load image');
      }.toJS;

      img.src = blobUrl;
      await completer.future;

      int width = img.naturalWidth;
      int height = img.naturalHeight;

      if (width <= 0 || height <= 0) {
        web.URL.revokeObjectURL(blobUrl);
        return rawBytes;
      }

      // Hitung skala rasio agar tidak melebihi batas resolusi
      if (width > maxDimension || height > maxDimension) {
        if (width >= height) {
          height = (height * maxDimension / width).round();
          width = maxDimension;
        } else {
          width = (width * maxDimension / height).round();
          height = maxDimension;
        }
      }

      final canvas = web.HTMLCanvasElement()
        ..width = width
        ..height = height;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) {
        web.URL.revokeObjectURL(blobUrl);
        return rawBytes;
      }

      ctx.drawImage(img, 0, 0, width.toDouble(), height.toDouble());
      web.URL.revokeObjectURL(blobUrl);

      // Konversi ke format JPEG dengan kualitas 72%
      final dataUrl = canvas.toDataURL('image/jpeg', quality.toJS);
      final commaIndex = dataUrl.indexOf(',');
      final base64Str = commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;

      return base64Decode(base64Str);
    } catch (e) {
      debugPrint('[WebImageUtils] Kompresi Canvas gagal ($e), gunakan bytes asli');
      return rawBytes;
    }
  }
}
