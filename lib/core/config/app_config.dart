abstract final class AppConfig {
  static const appUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'https://agile-knowledge.vercel.app',
  );
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasSupabaseCredentials =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.trim().isNotEmpty;

  static String get emailConfirmationRedirectUrl =>
      Uri.parse(appUrl).resolve('/').toString();
}
