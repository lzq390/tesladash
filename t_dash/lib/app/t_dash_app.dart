import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/t_dash_theme.dart';

class TDashApp extends ConsumerWidget {
  const TDashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'T-Dash',
      theme: TDashTheme.dark,
      routerConfig: router,
    );
  }
}
