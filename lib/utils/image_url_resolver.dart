/// Memformat dan mengubah URL gambar eksternal (Google Drive, Dropbox, dsb.)
/// menjadi URL direct image yang dapat langsung di-render oleh Flutter Web (Image.network).
String resolveImageUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  // Jika berupa path asset lokal atau blob URL
  if (trimmed.startsWith('assets/') || trimmed.startsWith('blob:')) {
    return trimmed;
  }

  // 1. Google Drive Link:
  // - https://drive.google.com/file/d/FILE_ID/view?usp=sharing
  // - https://drive.google.com/open?id=FILE_ID
  // - https://drive.google.com/uc?id=FILE_ID
  // - https://docs.google.com/file/d/FILE_ID
  if (trimmed.contains('drive.google.com') || trimmed.contains('docs.google.com')) {
    // Cari pola /file/d/<id>
    final fileMatch = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (fileMatch != null) {
      final fileId = fileMatch.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }

    // Cari parameter ?id=<id> atau &id=<id>
    final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (idMatch != null) {
      final fileId = idMatch.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
  }

  // 2. Dropbox Link:
  // Ubah dl=0 menjadi raw=1 agar langsung menyajikan binary gambar
  if (trimmed.contains('dropbox.com') && trimmed.contains('dl=0')) {
    return trimmed.replaceAll('dl=0', 'raw=1');
  }

  return trimmed;
}
