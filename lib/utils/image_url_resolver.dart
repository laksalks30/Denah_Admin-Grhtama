/// Mengubah URL gambar eksternal menjadi URL direct yang bisa di-render Flutter Web.
String resolveImageUrl(String rawUrl) {
  final url = rawUrl.trim();
  if (url.isEmpty) return url;

  // Base64 data URI atau blob — langsung pakai
  if (url.startsWith('data:image') || url.startsWith('blob:')) return url;

  // Sudah melalui proxy wsrv.nl
  if (url.startsWith('https://wsrv.nl/')) {
    final m = RegExp(r'googleusercontent\.com/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (m != null) return 'https://lh3.googleusercontent.com/d/${m.group(1)}';
    return url;
  }

  // Google Drive / Docs / GoogleUserContent
  if (url.contains('drive.google.com') ||
      url.contains('docs.google.com') ||
      url.contains('googleusercontent.com')) {
    String? fileId;
    fileId ??= RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
    fileId ??= RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
    fileId ??= RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
  }

  // Dropbox: dl=0 → raw=1
  if (url.contains('dropbox.com') && url.contains('dl=0')) {
    return url.replaceAll('dl=0', 'raw=1');
  }

  // Supabase Storage — proxy via wsrv.nl untuk CORS + konversi HEIC
  if (url.contains('supabase.co/storage/v1/object/public/room-images/')) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&output=jpg';
  }

  // URL HEIC/HEIF lainnya
  final lower = url.toLowerCase();
  if (lower.contains('.heic') || lower.contains('.heif')) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&output=jpg';
  }

  return url;
}
