import 'package:flutter/material.dart';

class RouteVisibility extends NavigatorObserver {
  static final tabIndex = ValueNotifier<int>(0);
  static final publicPage = ValueNotifier<bool>(true);
  static const publicRoutes = {
    '/',
    '/login',
    '/register',
    '/forgot',
    '/adminLogin',
    '/adminForgot'
  };
  void update(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final hidden = publicRoutes.contains(route.settings.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      publicPage.value = hidden;
      final tab = ['/home', '/profile', '/history', '/helpSupport']
          .indexOf(route.settings.name ?? '');
      if (tab >= 0) tabIndex.value = tab;
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) => update(route);
  @override
  void didPop(Route route, Route? previousRoute) => update(previousRoute);
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => update(newRoute);
}
