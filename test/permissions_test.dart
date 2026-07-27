import 'package:chatori_finance/core/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Role.fromDb', () {
    test('parses the two roles the database stores', () {
      expect(Role.fromDb('owner'), Role.owner);
      expect(Role.fromDb('chef'), Role.chef);
    });

    test('tolerates case and whitespace', () {
      expect(Role.fromDb('  Owner '), Role.owner);
      expect(Role.fromDb('CHEF'), Role.chef);
    });

    test('fails closed on anything unexpected', () {
      // A typo, a role from a newer build, or a user with no membership row
      // must land on unknown — never on a role with permissions.
      expect(Role.fromDb('cheff'), Role.unknown);
      expect(Role.fromDb('admin'), Role.unknown);
      expect(Role.fromDb(''), Role.unknown);
      expect(Role.fromDb(null), Role.unknown);
    });

    test('dbValue round-trips for assignable roles', () {
      for (final r in kAssignableRoles) {
        expect(Role.fromDb(r.dbValue), r);
      }
    });
  });

  group('permissions', () {
    test('owner can do everything', () {
      for (final p in Permission.values) {
        expect(Role.owner.can(p), isTrue, reason: '$p should be allowed');
      }
    });

    test('chef can view stock, record consumption, and see stock value', () {
      expect(Role.chef.can(Permission.viewInventory), isTrue);
      expect(Role.chef.can(Permission.recordConsumption), isTrue);
      // The chef now runs the store's cost too (opted in by the owner).
      expect(Role.chef.can(Permission.viewInventoryValue), isTrue);
    });

    test('chef still cannot reach finance, reports, members or settings', () {
      // Inventory cost is now allowed; the finance side stays walled off.
      const forbidden = [
        Permission.viewFinance,
        Permission.addTransaction,
        Permission.viewReports,
        Permission.viewOperations,
        Permission.scanInvoice,
        Permission.manageMembers,
        Permission.manageSettings,
      ];
      for (final p in forbidden) {
        expect(Role.chef.can(p), isFalse, reason: '$p must be denied');
      }
    });

    test('unknown has no permissions at all', () {
      expect(Role.unknown.permissions, isEmpty);
      for (final p in Permission.values) {
        expect(Role.unknown.can(p), isFalse);
      }
    });

    test('every role has an explicit entry, so none defaults open', () {
      for (final r in Role.values) {
        expect(kRolePermissions.containsKey(r), isTrue,
            reason: '$r must be declared explicitly');
      }
    });

    test('unknown is not assignable from the UI', () {
      expect(kAssignableRoles, isNot(contains(Role.unknown)));
      expect(kAssignableRoles, containsAll([Role.owner, Role.chef]));
    });
  });
}
