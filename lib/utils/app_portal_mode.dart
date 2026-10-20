import 'package:flutter/foundation.dart';

/// Utilitas pendeteksi mode Portal Admin
/// Memungkinkan aplikasi berjalan dalam 2 mode:
/// 1. Denah Publik (domain utama): Tampilan bersih tanpa tombol admin.
/// 2. Portal Admin Mandiri: Diakses lewat domain/subdomain khusus
///    (misal: admin-grhatama.vercel.app, admin.domain.com) atau via URL rahasia (/#/admin, /admin, ?admin).
class AppPortalMode {
  /// Memeriksa apakah saat ini sedang dibuka sebagai Portal Admin
  static bool get isAdminPortal {
    if (!kIsWeb) return false;

    try {
      final uri = Uri.base;

      // 1. Deteksi Host / Domain / Subdomain:
      // Mendukung domain terpisah di Vercel/Netlify/Custom Domain:
      // Contoh: admin-grhatama.vercel.app, admin.perpustakaan.go.id,
      //         portal-grhatama.vercel.app, admin-portal.com, dsb.
      final host = uri.host.toLowerCase();
      if (host.startsWith('admin.') ||
          host.startsWith('portal.') ||
          host.startsWith('admin-') ||
          host.startsWith('portal-') ||
          host.contains('-admin') ||
          host.contains('admin-portal') ||
          host.contains('portal-admin')) {
        return true;
      }

      // 2. Deteksi Hash Fragment (#/admin, #/portal, #admin)
      final fragment = uri.fragment.toLowerCase();
      if (fragment == 'admin' ||
          fragment == '/admin' ||
          fragment == 'portal' ||
          fragment == '/portal' ||
          fragment.startsWith('/admin') ||
          fragment.startsWith('/portal')) {
        return true;
      }

      // 3. Deteksi Path URL (/admin, /portal)
      final path = uri.path.toLowerCase();
      if (path == '/admin' ||
          path == '/portal' ||
          path.startsWith('/admin/') ||
          path.startsWith('/portal/')) {
        return true;
      }

      // 4. Deteksi Query Parameter (?admin=true, ?portal=1)
      if (uri.queryParameters.containsKey('admin') ||
          uri.queryParameters.containsKey('portal')) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
