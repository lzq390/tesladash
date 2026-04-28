import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:t_dash/app/routing/app_router.dart';
import 'package:t_dash/app/t_dash_app.dart';

Widget _buildApp({String initialLocation = '/'}) {
  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(
        createAppRouter(initialLocation: initialLocation),
      ),
    ],
    child: const TDashApp(),
  );
}

void main() {
  testWidgets('renders the dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('Model 3'), findsOneWidget);
    expect(find.text('BLE 已连接'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(find.text('86%'), findsNWidgets(2));
    expect(find.text('412'), findsOneWidget);
    expect(find.text('模拟行驶'), findsOneWidget);
    expect(find.text('解锁'), findsOneWidget);
    expect(find.text('空调'), findsWidgets);
    expect(find.text('闪灯'), findsOneWidget);
  });

  testWidgets('menu shows placeholder feedback', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.byTooltip('菜单'));
    await tester.pump();

    expect(find.text('设置页开发中'), findsOneWidget);
  });

  testWidgets('settings placeholder route is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialLocation: '/settings'));

    expect(find.text('设置页开发中'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
  });

  testWidgets('control buttons show placeholder feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('模拟行驶'));
    await tester.pump();

    expect(find.text('控制功能开发中'), findsOneWidget);
  });
}
