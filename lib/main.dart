// ╔══════════════════════════════════════════════════════════════════╗
// ║  PEPPER CLINICAL INFINITY V6 — Flutter Mobile App               ║
// ║  © 2026 Lamya Fadlulmola Hamed Ali — All Rights Reserved        ║
// ║  Android · iOS — High Performance · Offline AI                  ║
// ╚══════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/database.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/trial_screen.dart';
import 'screens/session/session_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/child/children_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance: lock orientation, set status bar style
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Keep screen on during therapy sessions
  await WakelockPlus.enable();

  // Init local database
  await AppDatabase.instance.init();

  runApp(const ProviderScope(child: PepperApp()));
}

class PepperApp extends ConsumerWidget {
  const PepperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final isAr = lang == 'ar';

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/',         builder: (c, s) => const LandingScreen()),
        GoRoute(path: '/login',    builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/trial',    builder: (c, s) => const TrialScreen()),
        GoRoute(path: '/children', builder: (c, s) => const ChildrenScreen()),
        GoRoute(
          path: '/session/:childId',
          builder: (c, s) => SessionScreen(
            childId: s.pathParameters['childId']!,
          ),
        ),
        GoRoute(
          path: '/dashboard/:childId',
          builder: (c, s) => DashboardScreen(
            childId: s.pathParameters['childId']!,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Pepper Clinical V6',
      debugShowCheckedModeBanner: false,
      theme: PepperTheme.light(),
      routerConfig: router,
      locale: Locale(isAr ? 'ar' : 'en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}

// Language provider
final langProvider = Provider<String>((ref) => 'ar');
