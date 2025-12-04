import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:routelog_project/firebase_options.dart';
import 'package:routelog_project/core/theme/app_theme.dart';
import 'package:routelog_project/core/theme/theme_controller.dart';
import 'package:routelog_project/core/navigation/app_router.dart';
import 'package:routelog_project/core/data/repository/repo_registry.dart';
import 'package:routelog_project/core/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ThemeController.instance.load();
  await AuthController.instance.initialize();
  // Firebase Firestore를 백엔드로 사용
  await RepoRegistry.I.init(useFirestore: true);
  runApp(const RouteLogApp());
}

class RouteLogApp extends StatelessWidget {
  const RouteLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (_, __) {
        final authCtrl = AuthController.instance;

        // 로딩 중이면 스플래시 화면
        if (authCtrl.isLoading) {
          return _SplashApp();
        }

        // 인증 상태에 따라 초기 라우트 결정
        final initialRoute = authCtrl.isAuthenticated ? Routes.home : Routes.login;

        return _MainApp(initialRoute: initialRoute);
      },
    );
  }
}

/// 스플래시 화면 (로딩 중)
class _SplashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (_, __) {
        final themeCtrl = ThemeController.instance;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeCtrl.mode,
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

/// 메인 앱 (인증 완료 후)
class _MainApp extends StatelessWidget {
  const _MainApp({required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (_, __) {
        final themeCtrl = ThemeController.instance;
        return MaterialApp(
          title: 'RouteLog',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeCtrl.mode,
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
