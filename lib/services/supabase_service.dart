import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _initialized = false;
  bool get isReady => _initialized && SupabaseConfig.isConfigured;

  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inisialisasi Supabase SDK saat aplikasi dibuka
  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Kredensial Supabase belum diisi. Menjalankan mode offline/lokal.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Terhubung ke Supabase dengan sukses!');
    } catch (e) {
      debugPrint('[SupabaseService] Gagal inisialisasi Supabase: $e');
    }
  }

  /// Cek apakah ada admin yang sedang login
  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Stream perubahan status autentikasi
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Login admin dengan email dan password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!isReady || client == null) {
      throw Exception('Supabase belum dikonfigurasi. Harap isi URL dan Anon Key di lib/services/supabase_config.dart');
    }
    return await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Logout admin
  Future<void> signOut() async {
    if (client != null) {
      await client!.auth.signOut();
    }
  }
}
