/// Supabase connection config. The anon key is a public client key (safe to
/// embed in the app); data is protected by Row-Level Security, not by hiding
/// this key.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://lrxdvyzglfmlrdfggzdj.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxyeGR2eXpnbGZtbHJkZmdnemRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4NDE5MTIsImV4cCI6MjA5ODQxNzkxMn0.rLTVonvViZzE6v-KJKBbt8xViUol3cSTvff4plvdjQo';
}
