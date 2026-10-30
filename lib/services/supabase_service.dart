import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _initialized = false;
  bool get isReady => _initialized && SupabaseConfig.isConfigured;

  /// Mode autentikasi lokal (fallback bila Supabase tidak tersedia/gagal).
  /// Digunakan saat proyek dipindahkan tanpa akses ke akun Supabase yang sama.
  bool _localAuth = false;

  // Kredensial admin default untuk mode lokal
  static const String _localAdminUser = 'admin';
  static const String _localAdminPass = 'admin123';

  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Kredensial belum diisi, mode offline.');
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Terhubung ke Supabase.');
    } catch (e) {
      debugPrint('[SupabaseService] Gagal inisialisasi: $e');
    }
  }

  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null || _localAuth;

  /// Coba login via Supabase. Jika gagal atau belum dikonfigurasi,
  /// fallback ke autentikasi lokal dengan kredensial admin/admin123.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // 1. Coba Supabase bila terkonfigurasi
    if (isReady && client != null) {
      try {
        await client!.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        return; // Berhasil via Supabase
      } catch (e) {
        debugPrint('[SupabaseService] Supabase login gagal, cek lokal: $e');
        // Lanjut ke fallback lokal
      }
    }

    // 2. Fallback: autentikasi lokal
    //    Ekstrak username dari email (admin@grhatama.id → admin)
    final username = email.split('@').first.trim().toLowerCase();
    if (username == _localAdminUser && password == _localAdminPass) {
      _localAuth = true;
      debugPrint('[SupabaseService] Login lokal berhasil (admin).');
      return;
    }

    throw Exception('Username atau Password salah.');
  }

  Future<void> signOut() async {
    _localAuth = false;
    if (client != null) await client!.auth.signOut();
  }
}
