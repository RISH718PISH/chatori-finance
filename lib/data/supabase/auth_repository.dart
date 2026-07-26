import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/permissions.dart';

/// The signed-in user's membership: which business, in what role, under
/// what name. Fetched as ONE row so the three can never disagree — two
/// independent queries could return a role from business X alongside data
/// from business Y.
class Membership {
  final String businessId;
  final Role role;
  final String? displayName;

  const Membership({
    required this.businessId,
    required this.role,
    this.displayName,
  });

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        businessId: j['business_id'] as String,
        role: Role.fromDb(j['role'] as String?),
        displayName: j['display_name'] as String?,
      );
}

/// One member of a business, for the owner's Members screen.
class BusinessMember {
  final String userId;
  final String? displayName;
  final Role role;

  const BusinessMember({
    required this.userId,
    required this.role,
    this.displayName,
  });

  factory BusinessMember.fromJson(Map<String, dynamic> j) => BusinessMember(
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String?,
        role: Role.fromDb(j['role'] as String?),
      );
}

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

  /// The signed-in user's membership — business, role and display name in a
  /// single row. Everything else derives from this, so the role can never
  /// belong to a different business than the data.
  ///
  /// `order by created_at` makes the pick deterministic for a user who ends
  /// up in two businesses; the previous bare `.limit(1)` returned whichever
  /// row Postgres felt like.
  Future<Membership?> currentMembership() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final rows = await _client
        .from('business_members')
        .select('business_id, role, display_name')
        .eq('user_id', uid)
        .order('created_at')
        .limit(1);
    if (rows.isEmpty) return null;
    return Membership.fromJson(rows.first);
  }

  /// The business id the signed-in user belongs to (created automatically on
  /// first sign-up by the `handle_new_user` trigger).
  Future<String?> currentBusinessId() async =>
      (await currentMembership())?.businessId;

  /// Everyone in the business, for the owner's Members screen.
  Future<List<BusinessMember>> fetchMembers(String businessId) async {
    final rows = await _client
        .from('business_members')
        .select('user_id, display_name, role')
        .eq('business_id', businessId)
        .order('created_at');
    return rows.map(BusinessMember.fromJson).toList();
  }

  /// Changes someone's role. Goes through an RPC rather than a direct
  /// UPDATE because a table-level update policy would also let an owner
  /// move the row to another business or rewrite `user_id`. The RPC asserts
  /// caller-is-owner and refuses self-demotion.
  Future<void> setMemberRole({
    required String targetUserId,
    required Role role,
  }) async {
    await _client.rpc('set_member_role', params: {
      'p_user_id': targetUserId,
      'p_role': role.dbValue,
    });
  }

  Future<void> removeMember(String targetUserId) async {
    await _client.rpc('remove_member', params: {'p_user_id': targetUserId});
  }

  /// Adds someone who ALREADY has an account to this business.
  ///
  /// Without this, a role picker on the invite dialog silently does nothing
  /// for anyone who has signed up before: `business_invites.role` is only
  /// read by the `handle_new_user` trigger at signup time.
  ///
  /// Returns a status string the UI can act on: `added` | `updated` |
  /// `invited` (no such account yet, so an invite row was written instead).
  Future<String> addOrInviteMember({
    required String email,
    required Role role,
  }) async {
    final res = await _client.rpc('add_member_by_email', params: {
      'p_email': email.trim().toLowerCase(),
      'p_role': role.dbValue,
    });
    return res as String? ?? 'invited';
  }

  /// Map of every member's user_id → display_name for the given business.
  /// Used to render "added by X" on transaction tiles.
  Future<Map<String, String>> fetchMembersMap(String businessId) async {
    final rows = await _client
        .from('business_members')
        .select('user_id, display_name')
        .eq('business_id', businessId);
    return {
      for (final r in rows)
        r['user_id'] as String: ((r['display_name'] as String?) ?? '').trim(),
    };
  }

  /// Updates the current user's display name for every business they're a
  /// member of. Simple case: both owners share one business, so this updates
  /// exactly one row.
  Future<void> updateMyDisplayName(String name) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client
        .from('business_members')
        .update({'display_name': name.trim()})
        .eq('user_id', uid);
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
