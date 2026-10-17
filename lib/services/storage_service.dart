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

  /// Memilih foto dari Galeri HP atau Folder PC/Web menggunakan FilePicker
  /// (bekerja native 100% di semua browser desktop & mobile) dengan fallback ke ImagePicker.
  Future<List<PickedImageData>> pickImagesFromStorage({bool allowMultiple = true}) async {
    // 1. Coba FilePicker (paling stabil & native di Web CanvasKit & Browser)
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
    } catch (e) {
      debugPrint('[StorageService] FilePicker error: $e, mencoba fallback ImagePicker...');
    }

    // 2. Fallback ke ImagePicker jika FilePicker tidak menghasilkan berkas
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

      final list = <PickedImageData>[];
      for (final xf in xfiles) {
        final bytes = await xf.readAsBytes();
        list.add(PickedImageData(bytes: bytes, name: xf.name));
      }
      return list;
    } catch (e2) {
      debugPrint('[StorageService] ImagePicker fallback error: $e2');
    }

    return [];
  }

  /// Memilih foto langsung dari Kamera (di HP membuka kamera langsung, di PC/Web membuka file dialog)
  Future<PickedImageData?> pickImageFromCamera() async {
    // 1. Coba ImagePicker Kamera
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        return PickedImageData(bytes: bytes, name: image.name);
      }
    } catch (e) {
      debugPrint('[StorageService] ImagePicker kamera gagal ($e), mencoba fallback...');
    }

    // 2. Fallback: Di browser PC/desktop yang tidak punya kamera langsung, buka pemilih berkas
    try {
      final PlatformFile? f = await FilePicker.pickFile(type: FileType.image);
      if (f != null) {
        final bytes = await f.readAsBytes();
        return PickedImageData(bytes: bytes, name: f.name);
      }
    } catch (e2) {
      debugPrint('[StorageService] Camera fallback error: $e2');
    }

    return null;
  }

  /// Mengunggah file gambar ke Supabase Storage dan mengembalikan URL publiknya
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String originalFileName,
    String? roomCode,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      throw Exception('Supabase belum terhubung. Pastikan internet aktif.');
    }

    // Ekstrak dan bersihkan ekstensi file (default: jpg)
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
    final cleanFileName = '${prefix}${timestamp}_$rand.$ext';
    final storagePath = 'photos/$cleanFileName';

    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';
    if (ext == 'gif') contentType = 'image/gif';

    try {
      await client.storage.from(bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('[StorageService] StorageException: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode == '404' || e.message.toLowerCase().contains('not found')) {
        throw Exception('BUCKET_NOT_FOUND');
      }
      if (e.statusCode == '403' ||
          e.message.toLowerCase().contains('row-level security') ||
          e.message.toLowerCase().contains('unauthorized')) {
        throw Exception('STORAGE_RLS_RESTRICTED');
      }
      rethrow;
    } catch (e) {
      debugPrint('[StorageService] Upload error: $e');
      rethrow;
    }
  }
}
