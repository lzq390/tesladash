import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/dashboard/dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.dashboard.name,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/pairing',
        name: AppRoute.pairing.name,
        builder: (context, state) =>
            const _PlaceholderRouteScreen(title: '配对页开发中'),
      ),
      GoRoute(
        path: '/controls',
        name: AppRoute.controls.name,
        builder: (context, state) =>
            const _PlaceholderRouteScreen(title: '控制页开发中'),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        builder: (context, state) =>
            const _PlaceholderRouteScreen(title: '设置页开发中'),
      ),
    ],
  );
}

enum AppRoute { dashboard, pairing, controls, settings }

class _PlaceholderRouteScreen extends StatelessWidget {
  const _PlaceholderRouteScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.goNamed(AppRoute.dashboard.name),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('T-Dash'),
      ),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
