import 'package:go_router/go_router.dart';

import '../data/models/txn.dart';
import '../features/advances/advances_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/events/events_screen.dart';
import '../features/home/home_screen.dart';
import '../features/inventory/consumption_entry_screen.dart';
import '../features/inventory/inventory_report_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/inventory/item_detail_screen.dart';
import '../features/inventory/opening_stock_screen.dart';
import '../features/inventory/wastage_screen.dart';
import '../features/reports/health_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/salary/salary_screen.dart';
import '../features/screenshot/screenshot_import_screen.dart';
import '../features/settings/members_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transaction/add_transaction_screen.dart';
import '../features/transaction/bulk_add_screen.dart';
import '../features/transaction/transactions_list_screen.dart';
import '../features/vendors/vendors_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/add',
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Txn) {
          return AddTransactionScreen(initialType: extra.type, editing: extra);
        }
        final prefill = extra is AddPrefill ? extra : null;
        final type = prefill?.type ??
            (state.uri.queryParameters['type'] == 'income'
                ? 'income'
                : 'expense');
        return AddTransactionScreen(
          initialType: type,
          prefill: prefill,
          initialEventId: state.uri.queryParameters['event'],
        );
      },
    ),
    GoRoute(
      path: '/add-bulk',
      builder: (_, state) {
        final extra = state.extra;
        final type = state.uri.queryParameters['type'] == 'income'
            ? 'income'
            : 'expense';
        return BulkAddScreen(
          type: type,
          seed: extra is BulkSeedRow ? extra : null,
        );
      },
    ),
    GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
    GoRoute(
      path: '/events/:id',
      builder: (_, state) =>
          EventDetailScreen(eventId: state.pathParameters['id']!),
    ),
    GoRoute(
        path: '/transactions',
        builder: (_, _) => const TransactionsListScreen()),
    GoRoute(path: '/customers', builder: (_, _) => const CustomersScreen()),
    GoRoute(path: '/vendors', builder: (_, _) => const VendorsScreen()),
    GoRoute(path: '/salary', builder: (_, _) => const SalaryScreen()),
    GoRoute(path: '/advances', builder: (_, _) => const AdvancesScreen()),
    GoRoute(path: '/import', builder: (_, _) => const ScreenshotImportScreen()),
    GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
    GoRoute(path: '/health', builder: (_, _) => const HealthScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
    GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
    GoRoute(
      path: '/inventory/consumption',
      builder: (_, _) => const ConsumptionEntryScreen(),
    ),
    GoRoute(
      path: '/inventory/opening',
      builder: (_, _) => const OpeningStockScreen(),
    ),
    GoRoute(
      path: '/inventory/wastage',
      builder: (_, _) => const WastageScreen(),
    ),
    GoRoute(
      path: '/inventory/report',
      builder: (_, _) => const InventoryReportScreen(),
    ),
    GoRoute(
      path: '/inventory/item/:id',
      builder: (_, state) =>
          ItemDetailScreen(itemId: state.pathParameters['id']!),
    ),
  ],
);
