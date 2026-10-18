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

@JS('convertHeicIfNeeded')
external JSPromise<web.File> _convertHeicIfNeeded(web.File file);

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
      ..accept = 'image/jpeg,image/png,image/webp,image/jpg,.heic,.heif,image/heic,image/heif'
      ..multiple = allowMultiple;

    if (isCamera) {
      input.setAttribute('capture', 'environment');
    }

    // Gunakan offscreen positioning, BUKAN display:none agar kompatibel dengan Safari iOS & Android
    input.style
      ..position = 'fixed'
      ..top = '-1000px'
      ..left = '-1000px'
      ..opacity = '0'
      ..width = '1px'
      ..height = '1px'
      ..pointerEvents = 'none';

    web.document.body?.append(input);

    input.onchange = (web.Event _) {
      () async {
        final fileList = input.files;
        final results = <WebPickedFile>[];

        if (fileList != null && fileList.length > 0) {
          for (int i = 0; i < fileList.length; i++) {
            final rawItem = fileList.item(i);
            if (rawItem != null) {
              web.File file = rawItem;
              // Jika format HEIC/HEIF, konversi otomatis ke JPEG lewat heic2any
              try {
                file = await _convertHeicIfNeeded(rawItem).toDart;
              } catch (e) {
                debugPrint('[WebImageUtils] Konversi HEIC dilewati: $e');
              }

              final reader = web.FileReader();
              final readCompleter = Completer<Uint8List>();

              reader.onload = (web.Event _) {
                try {
                  final dataUrl = (reader.result as JSString).toDart;
                  final commaIdx = dataUrl.indexOf(',');
                  final base64Str = commaIdx != -1 ? dataUrl.substring(commaIdx + 1) : dataUrl;
                  readCompleter.complete(base64Decode(base64Str));
                } catch (e) {
                  debugPrint('[WebImageUtils] Reader parse error: $e');
                  readCompleter.complete(Uint8List(0));
                }
              }.toJS;

              reader.onerror = (web.Event _) {
                readCompleter.complete(Uint8List(0));
              }.toJS;

              reader.readAsDataURL(file);
              final rawBytes = await readCompleter.future;

              if (rawBytes.isNotEmpty) {
                // Otomatis kompresi langsung ke JPEG resolusi optimal
                final compressed = await compressToJpeg(rawBytes);
                String cleanName = file.name;
                if (cleanName.toLowerCase().endsWith('.heic') || cleanName.toLowerCase().endsWith('.heif')) {
                  cleanName = cleanName.replaceAll(RegExp(r'\.(heic|heif)$', caseSensitive: false), '.jpg');
                }
                results.add(WebPickedFile(bytes: compressed, name: cleanName));
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
      final base64Str = base64Encode(rawBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      final img = web.HTMLImageElement();
      final completer = Completer<void>();

      img.onload = (web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }.toJS;

      img.onerror = (web.Event _) {
        if (!completer.isCompleted) completer.completeError('Failed to load image');
      }.toJS;

      img.src = dataUri;
      await completer.future;

      int width = img.naturalWidth;
      int height = img.naturalHeight;

      if (width <= 0 || height <= 0) {
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
        return rawBytes;
      }

      ctx.drawImage(img, 0, 0, width.toDouble(), height.toDouble());

      // Konversi ke format JPEG dengan kualitas 72%
      final dataUrl = canvas.toDataURL('image/jpeg', quality.toJS);
      final commaIndex = dataUrl.indexOf(',');
      final cleanBase64 = commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;

      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('[WebImageUtils] Kompresi Canvas gagal ($e), gunakan bytes asli');
      return rawBytes;
    }
  }
}
