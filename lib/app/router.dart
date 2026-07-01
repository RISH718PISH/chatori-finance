import 'package:go_router/go_router.dart';

import '../features/advances/advances_screen.dart';
import '../features/home/home_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/salary/salary_screen.dart';
import '../features/screenshot/screenshot_import_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transaction/add_transaction_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/add',
      builder: (_, state) {
        final prefill = state.extra as AddPrefill?;
        final type = prefill?.type ??
            (state.uri.queryParameters['type'] == 'income'
                ? 'income'
                : 'expense');
        return AddTransactionScreen(initialType: type, prefill: prefill);
      },
    ),
    GoRoute(path: '/salary', builder: (_, _) => const SalaryScreen()),
    GoRoute(path: '/advances', builder: (_, _) => const AdvancesScreen()),
    GoRoute(path: '/import', builder: (_, _) => const ScreenshotImportScreen()),
    GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
  ],
);
