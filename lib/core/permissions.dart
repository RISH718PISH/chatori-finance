/// Role-based permissions.
///
/// The real boundary is Row-Level Security in Postgres, not this file. A
/// chef's queries against the finance tables return zero rows regardless of
/// what the UI does — everything here exists so the app doesn't render
/// buttons that would fail, and so a chef never sees a screen shaped like
/// something they cannot use.
///
/// Never treat a check in this file as a security control on its own.
library;

/// Keyed by enum rather than by the raw `business_members.role` string on
/// purpose: an unrecognised role must land on [Role.unknown] and fail
/// closed, not silently produce an empty permission set and a locked-out
/// user with no explanation.
enum Role {
  owner,
  chef,
  unknown;

  /// Parses the DB string. Anything unexpected — a typo, a role added by a
  /// newer build, a null — becomes [Role.unknown].
  static Role fromDb(String? raw) => switch (raw?.trim().toLowerCase()) {
        'owner' => Role.owner,
        'chef' => Role.chef,
        _ => Role.unknown,
      };

  String get dbValue => switch (this) {
        Role.owner => 'owner',
        Role.chef => 'chef',
        Role.unknown => 'unknown',
      };

  String get label => switch (this) {
        Role.owner => 'Owner',
        Role.chef => 'Head Chef',
        Role.unknown => 'No access',
      };

  String get description => switch (this) {
        Role.owner => 'Full access to everything, including money and members',
        Role.chef => 'Stock only — no money, reports or settings',
        Role.unknown => 'Not a member of this business',
      };
}

/// Roles an owner may assign. [Role.unknown] is deliberately absent.
const List<Role> kAssignableRoles = [Role.owner, Role.chef];

enum Permission {
  /// Income, expenses, transaction list, the money on Home.
  viewFinance,
  addTransaction,

  /// Reports, P&L, charts, exports.
  viewReports,

  /// Events, salary, advances, customers, vendors.
  viewOperations,

  /// Scan a bill. Writes both an expense and (later) stock.
  scanInvoice,

  /// Stock quantities, movement history, low-stock list.
  viewInventory,

  /// Record consumption, wastage, stock takes; create items.
  recordConsumption,

  /// Stock VALUE in rupees, and average cost. Owner only — and enforced in
  /// the database as well, since the valuation views read the owner-only
  /// purchase tables.
  viewInventoryValue,

  /// Invite people, change roles, remove members.
  manageMembers,

  /// Everything on the Settings screen beyond display name and app lock.
  manageSettings,
}

const Map<Role, Set<Permission>> kRolePermissions = {
  Role.owner: {
    Permission.viewFinance,
    Permission.addTransaction,
    Permission.viewReports,
    Permission.viewOperations,
    Permission.scanInvoice,
    Permission.viewInventory,
    Permission.recordConsumption,
    Permission.viewInventoryValue,
    Permission.manageMembers,
    Permission.manageSettings,
  },
  // The chef runs the store, including its cost: stock value, average cost,
  // and entering prices when counting or adding stock. Still no access to
  // the finance side — income, P&L, reports, salaries, events.
  Role.chef: {
    Permission.viewInventory,
    Permission.recordConsumption,
    Permission.viewInventoryValue,
    // The chef can scan purchase bills. That books an expense the chef
    // still cannot see (finance stays hidden) — the save RPC is
    // SECURITY DEFINER so it writes the finance rows on their behalf.
    Permission.scanInvoice,
  },
  // Fails closed.
  Role.unknown: {},
};

extension RolePermissions on Role {
  Set<Permission> get permissions => kRolePermissions[this] ?? const {};
  bool can(Permission p) => permissions.contains(p);
}
