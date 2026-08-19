/// Batalat — App Router (go_router)
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/screens/products_list_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/catalog_list_screen.dart';
import '../../features/equipment/screens/equipment_detail_screen.dart';
import '../../features/equipment/screens/rental_booking_screen.dart';
import '../../features/equipment/screens/my_rentals_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/screens/addresses_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import 'package:batalat_app/features/orders/screens/order_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/cms/screens/faq_screen.dart';
import '../../features/cms/screens/contact_screen.dart';
import '../../features/cms/screens/terms_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/payment_methods_screen.dart';
import '../../features/products/screens/custom_requests_screen.dart';
import 'package:batalat_app/shared/widgets/main_shell.dart';

// ============================================================
// Route Names
// ============================================================
class AppRoutes {
  AppRoutes._();
  static const splash        = '/';
  static const onboarding    = '/onboarding';
  static const login         = '/login';
  static const register      = '/register';
  static const otp           = '/otp';
  static const home          = '/home';
  static const catalog       = '/catalog/:slug';
  static const packages      = '/packages'; // legacy redirect
  static const products      = '/products';
  static const productDetail = '/products/:slug';
  static const equipment     = '/equipment'; // legacy redirect
  static const equipmentDetail = '/equipment/:slug';
  static const rentalBook    = '/equipment/:slug/rent';
  static const cart          = '/cart';
  static const checkout      = '/checkout';
  static const orders        = '/orders';
  static const orderDetail   = '/orders/:id';
  static const profile       = '/profile';
  static const addresses     = '/addresses';
  static const notifications = '/notifications';
  static const faq           = '/faq';
  static const contact       = '/contact';
  static const terms         = '/terms';
  static const wallet        = '/wallet';
  static const paymentMethods = '/payment-methods';
  static const customRequests = '/custom-requests';
  static const myRentals = '/my-rentals';

  static String catalogPath(String slug) => '/catalog/$slug';
  static String equipmentDetailPath(String slug) => '/equipment/$slug';
}

class _GoRouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

// ============================================================
// Router Provider
// ============================================================
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefresh();
  ref.listen<AuthState>(authProvider, (_, __) => refresh.ping());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      if (!auth.isRestored) return null;

      // انتهت صلاحية المصادقة → شاشة الدخول
      if (auth.sessionExpired && loc != AppRoutes.login) {
        return AppRoutes.login;
      }

      // مسارات محمية
      final needsAuth = loc.startsWith('/checkout') ||
          loc.startsWith('/addresses') ||
          loc.startsWith('/orders') ||
          loc.startsWith('/profile') ||
          loc.startsWith('/notifications') ||
          loc.startsWith('/wallet') ||
          loc.startsWith('/payment-methods') ||
          loc.startsWith('/custom-requests') ||
          loc.startsWith('/my-rentals') ||
          loc.contains('/rent');

      if (!auth.isAuthenticated && needsAuth) {
        return AppRoutes.login;
      }

      if (auth.isAuthenticated &&
          (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OTPScreen(
            phone: extra['phone'],
            purpose: extra['purpose'] ?? 'login',
            fullName: extra['full_name'],
          );
        },
      ),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              final title = state.uri.queryParameters['title'];
              return CatalogListScreen(rootSlug: slug, title: title);
            },
          ),
          GoRoute(
            path: AppRoutes.packages,
            redirect: (_, __) => AppRoutes.catalogPath('packages'),
          ),
          GoRoute(
            path: AppRoutes.products,
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              final search = state.uri.queryParameters['search'];
              return ProductsListScreen(
                initialCategorySlug: category,
                initialSearch: search,
              );
            },
            routes: [
              GoRoute(
                path: ':slug',
                builder: (context, state) => ProductDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.equipment,
            redirect: (_, __) => AppRoutes.catalogPath('equipment'),
          ),
          GoRoute(
            path: '/equipment/:slug',
            builder: (context, state) => EquipmentDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
            routes: [
              GoRoute(
                path: 'rent',
                builder: (context, state) => RentalBookingScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, __) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailScreen(
                  orderId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (_, __) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (_, __) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (_, __) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customRequests,
        builder: (_, __) => const CustomRequestsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => CustomRequestDetailScreen(
              requestId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myRentals,
        builder: (_, __) => const MyRentalsScreen(),
      ),
    ],
  );
});
