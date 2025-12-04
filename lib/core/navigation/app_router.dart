import 'package:flutter/material.dart';
import 'package:routelog_project/features/home/home_screen.dart';
import 'package:routelog_project/features/settings/settings_screen.dart';
import 'package:routelog_project/features/auth/login_screen.dart';

import 'package:routelog_project/features/onboarding/onboarding_screen.dart';
import 'package:routelog_project/features/routes/routes_bindings.dart';
import 'package:routelog_project/features/routes/route_detail_bindings.dart';
import 'package:routelog_project/features/search/search_bindings.dart';
import 'package:routelog_project/features/stats/stats_bindings.dart';
import 'package:routelog_project/features/record/record_bindings.dart';

class Routes {
  static const login = '/login';
  static const home = '/';
  static const search = '/search';
  static const routes = '/routes';
  static const stats = '/stats';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const record = '/record';

  /// /route/<id> 형태의 상세 경로
  static String routeDetail(String id) => '/route/$id';

  static final RegExp _routeDetailRegex = RegExp(r'^/route/([^/]+)$');
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? Routes.home;

    // /route/<id> 패턴 처리
    final match = Routes._routeDetailRegex.firstMatch(name);
    if (match != null) {
      final id = match.group(1)!;
      return _fade(RouteDetailBindings(routeId: id));
    }

    switch (name) {
      case Routes.login:
        return _fade(const LoginScreen());
      case Routes.home:
        return _fade(const HomeScreen());
      case Routes.search:
        return _fade(const SearchBindings());
      case Routes.routes:
        return _fade(const RoutesBindings());
      case Routes.stats:
        return _fade(const StatsBindings());
      case Routes.settings:
        return _fade(const SettingsScreen());
      case Routes.onboarding:
        return _fade(const OnboardingScreen());
      case Routes.record:
        return _fade(const RecordBindings());
      default:
        return _fade(const _PlaceholderScaffold(title: '404', subtitle: 'Not Found'));
    }
  }
}

PageRoute _fade(Widget child) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => child,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);

PageRoute _slide(Widget child) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => child,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: child,
  ),
);

class _PlaceholderScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PlaceholderScaffold({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = subtitle == null ? title : '$title\n$subtitle';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
