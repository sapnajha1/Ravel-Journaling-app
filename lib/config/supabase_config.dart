/// Supabase project configuration.
///
/// Replace with your project URL and anon key from:
/// Supabase Dashboard → Project Settings → API
/// Also add your app's redirect URL in:
/// Authentication → URL Configuration → Redirect URLs
/// e.g. journalapp://auth/callback
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ipptzbihuzbgriixerld.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwcHR6YmlodXpiZ3JpaXhlcmxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2Nzc2NDEsImV4cCI6MjA4NTI1MzY0MX0.vqZDZmHnOmoQFcd7ezLE7Pkc1nJFzAZYXQMjkMlDayw',
  );

  /// Deep link used for magic link callback. Must match the redirect URL
  /// configured in Supabase Dashboard (Authentication → URL Configuration).
  static const String authRedirectUrl = 'journalapp://auth/callback';
}
