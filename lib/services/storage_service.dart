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
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      debugPrint('[StorageService] Gagal memilih gambar: $e');
      rethrow;
    }
  }

  /// Memilih banyak foto sekaligus dari Galeri / Folder
  Future<List<XFile>> pickMultiImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return images;
    } catch (e) {
      debugPrint('[StorageService] Gagal memilih banyak gambar: $e');
      rethrow;
    }
  }

  /// Memilih foto langsung dari Kamera (khusus perangkat dengan kamera)
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      debugPrint('[StorageService] Gagal mengambil foto kamera: $e');
      rethrow;
    }
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

    final ext = originalFileName.contains('.')
        ? originalFileName.split('.').last.toLowerCase()
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = (roomCode != null && roomCode.isNotEmpty)
        ? '${roomCode.replaceAll('.', '_')}_'
        : 'room_';
    final cleanFileName = '$prefix$timestamp.$ext';
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
        throw Exception(
          'BUCKET_NOT_FOUND',
        );
      }
      if (e.statusCode == '403' ||
          e.message.toLowerCase().contains('row-level security') ||
          e.message.toLowerCase().contains('unauthorized')) {
        throw Exception(
          'STORAGE_RLS_RESTRICTED',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('[StorageService] Upload error: $e');
      rethrow;
    }
  }
}
