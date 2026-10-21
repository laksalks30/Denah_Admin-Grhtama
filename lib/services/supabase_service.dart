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
  bool get isAuthenticated => currentUser != null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!isReady || client == null) {
      throw Exception('Supabase belum dikonfigurasi.');
    }
    return await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    if (client != null) await client!.auth.signOut();
  }
}
