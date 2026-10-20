/// Memformat dan mengubah URL gambar eksternal (Google Drive, Dropbox, dsb.)
/// menjadi URL direct image yang dapat langsung di-render oleh Flutter Web (CanvasKit/HTML).
String resolveImageUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  // Jika berupa path asset lokal, blob, atau Base64 data URL
  if (trimmed.startsWith('assets/') ||
      trimmed.startsWith('blob:') ||
      trimmed.startsWith('data:image')) {
    return trimmed;
  }

  // Jika sudah melalui proxy wsrv.nl
  if (trimmed.startsWith('https://wsrv.nl/')) {
    final driveMatch = RegExp(r'googleusercontent\.com/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (driveMatch != null) {
      return 'https://lh3.googleusercontent.com/d/${driveMatch.group(1)}';
    }
    return trimmed;
  }

  // 1. Google Drive Link / Google User Content:
  // - https://drive.google.com/file/d/FILE_ID/view?usp=sharing
  // - https://drive.google.com/open?id=FILE_ID
  // - https://drive.google.com/uc?id=FILE_ID
  // - https://docs.google.com/file/d/FILE_ID
  // - https://lh3.googleusercontent.com/d/FILE_ID
  if (trimmed.contains('drive.google.com') ||
      trimmed.contains('docs.google.com') ||
      trimmed.contains('googleusercontent.com')) {
    String? fileId;

    // Pola 1: /file/d/<id>
    final fileMatch = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (fileMatch != null) {
      fileId = fileMatch.group(1);
    }

    // Pola 2: parameter ?id=<id> atau &id=<id>
    if (fileId == null) {
      final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (idMatch != null) {
        fileId = idMatch.group(1);
      }
    }

    // Pola 3: /d/<id> (misal googleusercontent.com/d/<id>)
    if (fileId == null) {
      final dMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (dMatch != null) {
        fileId = dMatch.group(1);
      }
    }

    if (fileId != null && fileId.isNotEmpty) {
      // Direct CDN endpoint Google User Content (lh3.googleusercontent.com/d/<id>)
      // Menyajikan gambar secara instan sebagai JPEG dengan header Access-Control-Allow-Origin: *
      // sehingga bebas dari blokir 403 proxy dan kompatibel 100% dengan CanvasKit Flutter Web.
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
  }

  // 2. Dropbox Link:
  // Ubah dl=0 menjadi raw=1 agar langsung menyajikan binary gambar
  if (trimmed.contains('dropbox.com') && trimmed.contains('dl=0')) {
    return trimmed.replaceAll('dl=0', 'raw=1');
  }

  // 3. Foto Supabase Storage (room-images):
  // Diproses melalui Cloudflare Edge image proxy wsrv.nl agar:
  // - Foto format apapun (termasuk foto iPhone HEIC yang terunggah dengan nama .jpg)
  //   selalu didecode di server edge dan disajikan sebagai JPEG standar universal.
  // - Header CORS (Access-Control-Allow-Origin: *) terjamin 100% untuk CanvasKit Skia.
  // - Caching CDN global agar foto tampil seketika tanpa jeda.
  if (trimmed.contains('supabase.co/storage/v1/object/public/room-images/')) {
    final encoded = Uri.encodeComponent(trimmed);
    return 'https://wsrv.nl/?url=$encoded&output=jpg';
  }

  // 4. URL gambar lainnya yang berformat HEIC/HEIF
  final lowerUrl = trimmed.toLowerCase();
  if (lowerUrl.contains('.heic') || lowerUrl.contains('.heif')) {
    final encoded = Uri.encodeComponent(trimmed);
    return 'https://wsrv.nl/?url=$encoded&output=jpg';
  }

  return trimmed;
}
