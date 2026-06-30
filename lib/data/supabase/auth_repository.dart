import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase auth + the current user's business.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
    // If email confirmation is disabled, a session is created immediately.
    // Otherwise the user must confirm via email before signing in.
  }

  Future<void> signOut() => _client.auth.signOut();

  /// The business id the signed-in user belongs to (created automatically on
  /// first sign-up by the `handle_new_user` trigger).
  Future<String?> currentBusinessId() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('business_members')
        .select('business_id')
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['business_id'] as String;
  }

  /// Display name for the current user's membership.
  Future<String?> displayName() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('business_members')
        .select('display_name')
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['display_name'] as String?;
  }

  /// Invite another person (by email) into the current user's business so they
  /// share the same books once they sign up.
  Future<void> inviteMember(String email, {String role = 'owner'}) async {
    final biz = await currentBusinessId();
    if (biz == null) return;
    await _client.from('business_invites').upsert({
      'email': email.trim().toLowerCase(),
      'business_id': biz,
      'role': role,
      'invited_by': currentUser?.id,
    });
  }
}
