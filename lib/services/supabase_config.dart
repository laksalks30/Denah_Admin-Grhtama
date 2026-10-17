// Konfigurasi Supabase untuk Peta Interaktif Grhatama Pustaka
//
// CARA MENGISI:
// 1. Buka dashboard Supabase (https://supabase.com/dashboard)
// 2. Pilih Project Anda -> Settings (ikon gerigi) -> API
// 3. Salin "Project URL" dan "Project API Keys (anon public)" ke variabel di bawah.

class SupabaseConfig {
  // Project URL Supabase Anda
  static const String supabaseUrl = 'https://wxxltmmqkdyidtgvibow.supabase.co';

  // anon public API key Supabase Anda
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind4eGx0bW1xa2R5aWR0Z3ZpYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMjgwMTMsImV4cCI6MjEwNzgwNDAxM30.JZ3FDw-QOkc4eNElDhf5a6VpaWn05yHhz8luaSlldmg';

  /// Memeriksa apakah kredensial Supabase sudah diisi dengan benar
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('YOUR_PROJECT_ID') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_ANON_PUBLIC_KEY');
  }
}
