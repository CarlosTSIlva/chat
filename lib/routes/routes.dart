import 'package:chat/pages/pages.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String chat = '/chat';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const Login());

      case dashboard:
        return MaterialPageRoute(
            builder: (_) => Dashboard(
                  id: routeSettings.arguments as String,
                ));

      case settings:
        return MaterialPageRoute(builder: (_) => const Settings());

      case chat:
        return MaterialPageRoute(
            builder: (_) => Chat(
                  args: routeSettings.arguments as ChartArgs,
                ));

      default:
        return MaterialPageRoute(builder: (_) => const Login());
    }
  }
}
