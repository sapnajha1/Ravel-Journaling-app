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
    defaultValue: 'https://zvdkkwlpjjcqqlyiwnol.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2ZGtrd2xwampjcXFseWl3bm9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4Nzk2NTEsImV4cCI6MjA4NjQ1NTY1MX0.tT5Vvk_hwzZg2TRANMFs9Y5KWDvWVSE4R2XXVPLvMIs',
  );

  /// Deep link used for magic link callback. Must match the redirect URL
  /// configured in Supabase Dashboard (Authentication → URL Configuration).
  static const String authRedirectUrl = 'journalapp://auth/callback';
}
