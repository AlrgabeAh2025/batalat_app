/// Batalat — Main Entry Point
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'features/auth/providers/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // إعداد شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // تهيئة Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // تهيئة Dio API Client
  ApiClient().initialize();

  runApp(
    const ProviderScope(
      child: BatalatApp(),
    ),
  );
}

class BatalatApp extends ConsumerStatefulWidget {
  const BatalatApp({super.key});

  @override
  ConsumerState<BatalatApp> createState() => _BatalatAppState();
}

class _BatalatAppState extends ConsumerState<BatalatApp> {
  @override
  void initState() {
    super.initState();
    // عند فشل تجديد التوكن: تحديث حالة المصادقة → التوجيه لشاشة الدخول
    ApiClient().onSessionExpired = () {
      ref.read(authProvider.notifier).markSessionExpired();
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Batalat | باتلات',
      debugShowCheckedModeBanner: false,

      // الثيم
      theme: AppTheme.lightTheme,

      // دعم اللغة العربية RTL
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [
        Locale('ar', 'LY'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Router
      routerConfig: router,
    );
  }
}
