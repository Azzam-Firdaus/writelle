/// Supabase public configuration constants.
/// Ref: docs/DATABASE_AND_API.md and docs/IMPLEMENTATION_AND_TESTING.md (SEC-04)
abstract class SupabaseConstants {
  /// Base project URL (without /rest/v1/ suffix for SDK compatibility)
  static const String supabaseUrl = 'https://wjnnfumpdlllzurjbgza.supabase.co';

  /// Public publishable key (safe to include in client builds)
  /// NEVER place service_role secret here.
  static const String supabasePublishableKey = 'sb_publishable_myIyUeEbSYzF72j1Fwge-w_AKR0TQlz';
}
