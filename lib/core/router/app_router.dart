import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/crm/presentation/crm_detail_screen.dart';
import '../../features/crm/presentation/crm_list_screen.dart';
import '../../features/crm/presentation/crm_statement_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dues/presentation/due_detail_screen.dart';
import '../../features/dues/presentation/dues_list_screen.dart';
import '../../features/gsm_orders/presentation/gsm_order_detail_screen.dart';
import '../../features/gsm_orders/presentation/gsm_orders_list_screen.dart';
import '../../features/pos/presentation/pos_sales_screen.dart';
import '../../features/pos/presentation/pos_terminal_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/products_list_screen.dart';
import '../../features/purchases/presentation/purchase_create_screen.dart';
import '../../features/purchases/presentation/purchase_detail_screen.dart';
import '../../features/purchases/presentation/purchases_list_screen.dart';
import '../../features/accounts_expenses/presentation/accounts_screen.dart';
import '../../features/accounts_expenses/presentation/expenses_screen.dart';
import '../../features/repair_jobs/presentation/repair_job_create_screen.dart';
import '../../features/repair_jobs/presentation/repair_job_detail_screen.dart';
import '../../features/repair_jobs/presentation/repair_jobs_list_screen.dart';
import '../../features/online_orders/presentation/online_order_detail_screen.dart';
import '../../features/online_orders/presentation/online_orders_screen.dart';
import '../../features/service_waitlist/presentation/waitlist_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/staff/presentation/staff_detail_screen.dart';
import '../../features/staff/presentation/staff_list_screen.dart';
import '../../features/support_tickets/presentation/support_list_screen.dart';
import '../../features/support_tickets/presentation/ticket_detail_screen.dart';
import '../../features/tech_panel/presentation/tech_panel_screen.dart';

/// Lets non-widget code (push notification tap handlers) navigate without a
/// BuildContext of their own — GoRouter owns/populates this Navigator's key.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod's authControllerProvider (rebuild-on-state-change) to
/// go_router's ChangeNotifier-based refreshListenable, so every navigation
/// re-evaluates `redirect` against the latest auth state.
class _RouterRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen(authControllerProvider, (_, _) => notifier.ping());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      final goingTo = state.matchedLocation;

      if (auth.isLoading) {
        return goingTo == '/' ? null : '/';
      }
      if (!auth.isAuthenticated) {
        return goingTo == '/login' ? null : '/login';
      }
      // Authenticated: bounce away from splash/login to the role-appropriate home.
      if (goingTo == '/' || goingTo == '/login') {
        return auth.user!.defaultLanding == 'tech_panel' ? '/tech-panel' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/tech-panel',
        builder: (context, state) =>
            TechPanelScreen(initialTab: state.extra is int ? state.extra as int : 0),
      ),
      GoRoute(path: '/repair-jobs', builder: (context, state) => const RepairJobsListScreen()),
      GoRoute(path: '/repair-jobs/new', builder: (context, state) => const RepairJobCreateScreen()),
      GoRoute(
        path: '/repair-jobs/:id',
        builder: (context, state) =>
            RepairJobDetailScreen(jobId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/pos', builder: (context, state) => const PosTerminalScreen()),
      GoRoute(path: '/pos/sales', builder: (context, state) => const PosSalesScreen()),
      GoRoute(path: '/crm', builder: (context, state) => const CrmListScreen()),
      GoRoute(
        path: '/crm/:id',
        builder: (context, state) => CrmDetailScreen(customerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/crm/:id/statement',
        builder: (context, state) => CrmStatementScreen(customerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/products', builder: (context, state) => const ProductsListScreen()),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/orders', builder: (context, state) => const GsmOrdersListScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => GsmOrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/dues', builder: (context, state) => const DuesListScreen()),
      GoRoute(
        path: '/dues/:id',
        builder: (context, state) => DueDetailScreen(customerId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/purchases', builder: (context, state) => const PurchasesListScreen()),
      GoRoute(path: '/purchases/new', builder: (context, state) => const PurchaseCreateScreen()),
      GoRoute(
        path: '/purchases/:id',
        builder: (context, state) => PurchaseDetailScreen(poId: int.parse(state.pathParameters['id']!)),
      ),
      // Phase 5 — Accounts / Expenses
      GoRoute(path: '/accounts', builder: (context, state) => const AccountsScreen()),
      GoRoute(path: '/expenses', builder: (context, state) => const ExpensesScreen()),
      // Phase 5 — Support Tickets
      GoRoute(path: '/support', builder: (context, state) => const SupportListScreen()),
      GoRoute(
        path: '/support/:id',
        builder: (context, state) =>
            TicketDetailScreen(ticketId: int.parse(state.pathParameters['id']!)),
      ),
      // Phase 5 — Service Waitlist
      GoRoute(path: '/service-waitlist', builder: (context, state) => const ServiceWaitlistScreen()),
      // Phase 6 — Settings
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      // Phase 6 — Staff (static before dynamic)
      GoRoute(path: '/staff', builder: (context, state) => const StaffListScreen()),
      GoRoute(path: '/staff/new', builder: (context, state) => const StaffDetailScreen(staffId: 0, isNew: true)),
      GoRoute(
        path: '/staff/:id',
        builder: (context, state) =>
            StaffDetailScreen(staffId: int.parse(state.pathParameters['id']!)),
      ),
      // Phase 6 — Online Orders (static before dynamic)
      GoRoute(path: '/online-orders', builder: (context, state) => const OnlineOrdersScreen()),
      GoRoute(
        path: '/online-orders/:id',
        builder: (context, state) =>
            OnlineOrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
