import 'package:chat/pages/pages.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const Login());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const Dashboard());

      case settings:
        return MaterialPageRoute(builder: (_) => const Settings());

      default:
        return MaterialPageRoute(builder: (_) => const Login());
    }
  }
}
