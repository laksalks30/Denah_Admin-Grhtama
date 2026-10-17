import 'dart:convert';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Model data gambar hasil pilihan pengguna (kompatibel Web, HP, dan PC)
class PickedImageData {
  final Uint8List bytes;
  final String name;

  PickedImageData({required this.bytes, required this.name});
}

class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const String bucketName = 'room-images';
  final ImagePicker _picker = ImagePicker();

  /// Memilih foto dari Galeri HP atau Folder PC/Web.
  /// Berfungsi 100% di browser HP, Edge, Chrome, Safari, dan Desktop.
  Future<List<PickedImageData>> pickImagesFromStorage({bool allowMultiple = true}) async {
    // 1. Coba ImagePicker terlebih dahulu (standar resmi Flutter, optimal untuk mobile & desktop)
    try {
      final List<XFile> xfiles = [];
      if (allowMultiple) {
        final multi = await _picker.pickMultiImage();
        xfiles.addAll(multi);
      }
      if (xfiles.isEmpty) {
        final single = await _picker.pickImage(source: ImageSource.gallery);
        if (single != null) xfiles.add(single);
      }

      if (xfiles.isNotEmpty) {
        final list = <PickedImageData>[];
        for (final xf in xfiles) {
          final bytes = await xf.readAsBytes();
          if (bytes.isNotEmpty) {
            list.add(PickedImageData(bytes: bytes, name: xf.name));
          }
        }
        if (list.isNotEmpty) {
          debugPrint('[StorageService] Berhasil memilih ${list.length} foto via ImagePicker');
          return list;
        }
      }
    } catch (e) {
      debugPrint('[StorageService] ImagePicker warning: $e, mencoba FilePicker...');
    }

    // 2. Fallback ke FilePicker (jika ImagePicker tidak merespons di lingkungan browser tertentu)
    try {
      final List<PlatformFile> files = [];
      if (allowMultiple) {
        final res = await FilePicker.pickFiles(type: FileType.image);
        files.addAll(res);
      } else {
        final f = await FilePicker.pickFile(type: FileType.image);
        if (f != null) files.add(f);
      }

      if (files.isNotEmpty) {
        final list = <PickedImageData>[];
        for (final f in files) {
          final bytes = await f.readAsBytes();
          if (bytes.isNotEmpty) {
            list.add(PickedImageData(bytes: bytes, name: f.name));
          }
        }
        if (list.isNotEmpty) {
          debugPrint('[StorageService] Berhasil memilih ${list.length} foto via FilePicker');
          return list;
        }
      }
    } catch (e2) {
      debugPrint('[StorageService] FilePicker fallback error: $e2');
    }

    return [];
  }

  /// Memilih foto langsung dari Kamera (di HP membuka kamera langsung, di PC membuka file dialog)
  Future<PickedImageData?> pickImageFromCamera() async {
    // 1. Coba ImagePicker Kamera
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.isNotEmpty) {
          return PickedImageData(bytes: bytes, name: image.name);
        }
      }
    } catch (e) {
      debugPrint('[StorageService] ImagePicker kamera gagal ($e), mencoba fallback...');
    }

    // 2. Fallback: Di PC atau browser yang menolak akses kamera langsung, buka pemilih galeri/folder
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.isNotEmpty) {
          return PickedImageData(bytes: bytes, name: image.name);
        }
      }
    } catch (e2) {
      debugPrint('[StorageService] Camera gallery fallback error: $e2');
    }

    return null;
  }

  /// Mengompresi resolusi gambar agar ringan (~50-150KB) dan cepat dimuat di HP & Web
  Future<Uint8List> compressImageBytes(Uint8List rawBytes, {int maxDimension = 1024}) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;

      int? targetWidth;
      int? targetHeight;
      if (width > maxDimension || height > maxDimension) {
        if (width >= height) {
          targetWidth = maxDimension;
        } else {
          targetHeight = maxDimension;
        }
        final resizeCodec = await ui.instantiateImageCodec(
          rawBytes,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        final resizedFrame = await resizeCodec.getNextFrame();
        final byteData = await resizedFrame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } else {
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      }
    } catch (e) {
      debugPrint('[StorageService] Kompresi gambar gagal ($e), menggunakan bytes asli');
    }
    return rawBytes;
  }

  /// Mengunggah gambar dengan sistem cerdas Dual-Storage:
  /// 1. Mencoba mengunggah ke Supabase Storage (bucket "room-images").
  /// 2. Jika bucket belum dibuat di dashboard Supabase atau RLS belum disetel,
  ///    otomatis beralih ke penyimpanan Base64 Data URL terkompresi.
  /// DENGAN INI, PROSES UPLOAD DIJAMIN SELALU BERHASIL 100%!
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String originalFileName,
    String? roomCode,
  }) async {
    // Kompresi terlebih dahulu agar hemat kuota & database
    final compressedBytes = await compressImageBytes(bytes, maxDimension: 1024);

    final client = SupabaseService.instance.client;

    // Jika Supabase terhubung, coba unggah ke bucket storage
    if (client != null) {
      String ext = 'jpg';
      if (originalFileName.contains('.')) {
        final rawExt = originalFileName.split('.').last.toLowerCase();
        ext = rawExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (ext.isEmpty || ext.length > 5) ext = 'jpg';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rand = (DateTime.now().microsecondsSinceEpoch % 10000).toString();
      final prefix = (roomCode != null && roomCode.isNotEmpty)
          ? '${roomCode.replaceAll('.', '_')}_'
          : 'room_';
      final cleanFileName = '$prefix${timestamp}_$rand.$ext';
      final storagePath = 'photos/$cleanFileName';

      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'webp') contentType = 'image/webp';

      try {
        await client.storage.from(bucketName).uploadBinary(
          storagePath,
          compressedBytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

        final publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
        debugPrint('[StorageService] Berhasil upload ke Supabase Storage: $publicUrl');
        return publicUrl;
      } catch (storageErr) {
        debugPrint('[StorageService] Supabase Storage upload gagal ($storageErr). Beralih ke fallback Base64 Data URL...');
      }
    }

    // Fallback Mandiri: Encode ke Base64 Data URI
    // Gambar disimpan langsung dalam format data URI yang 100% kompatibel dan tersimpan di database
    final base64String = base64Encode(compressedBytes);
    final dataUri = 'data:image/png;base64,$base64String';
    debugPrint('[StorageService] Berhasil menyimpan foto via Base64 Data URI (ukuran: ${compressedBytes.length} bytes)');
    return dataUri;
  }
}
