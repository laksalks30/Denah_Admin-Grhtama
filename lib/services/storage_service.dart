import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const String bucketName = 'room-images';
  final ImagePicker _picker = ImagePicker();

  /// Memilih satu foto dari Galeri (HP) atau File Explorer Folder (PC/Web)
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      return image;
    } catch (e) {
      debugPrint('[StorageService] Gagal memilih gambar dari galeri: $e');
      return null;
    }
  }

  /// Memilih banyak foto sekaligus dari Galeri / Folder (otomatis fallback ke single jika multi-pilih tidak didukung browser)
  Future<List<XFile>> pickMultiImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) return images;
    } catch (e) {
      debugPrint('[StorageService] pickMultiImage gagal atau tidak didukung browser ($e), mencoba fallback...');
    }

    try {
      final single = await _picker.pickImage(source: ImageSource.gallery);
      if (single != null) return [single];
    } catch (e2) {
      debugPrint('[StorageService] Fallback pickImage juga gagal: $e2');
    }
    return [];
  }

  /// Memilih foto langsung dari Kamera (di HP membuka kamera langsung, di PC/Web membuka file dialog)
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) return image;
    } catch (e) {
      debugPrint('[StorageService] Kamera tidak didukung/gagal ($e), mencoba fallback galeri...');
      try {
        final fallback = await _picker.pickImage(source: ImageSource.gallery);
        return fallback;
      } catch (_) {}
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
