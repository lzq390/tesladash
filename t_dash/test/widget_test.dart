import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:t_dash/app/routing/app_router.dart';
import 'package:t_dash/app/t_dash_app.dart';
import 'package:t_dash/application/dashboard/dashboard_snapshot.dart';

const _stressSnapshot = DashboardSnapshot(
  vehicleName: 'Model 3',
  connectionLabel: 'BLE 已连接',
  batteryPercent: 100,
  rangeKm: 512,
  speedKmh: 188,
  speedSourceLabel: 'GPS+IMU',
  drivingLabel: '行驶中',
  climateLabel: '制冷 18°C',
  tirePressureLabel: '2.8 / 2.8',
  chargingLabel: '未连接',
);

Widget _buildApp({String initialLocation = '/', DashboardSnapshot? snapshot}) {
  final overrides = [
    appRouterProvider.overrideWithValue(
      createAppRouter(initialLocation: initialLocation),
    ),
    if (snapshot != null) dashboardSnapshotProvider.overrideWithValue(snapshot),
  ];

  return ProviderScope(overrides: overrides, child: const TDashApp());
}

Future<void> _pumpDashboardAtSize(
  WidgetTester tester,
  Size size, {
  DashboardSnapshot snapshot = _stressSnapshot,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(_buildApp(snapshot: snapshot));
  await tester.pumpAndSettle();
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

  testWidgets('dashboard fits compact portrait without layout exceptions', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardAtSize(tester, const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('188'), findsOneWidget);
    expect(find.text('GPS+IMU'), findsOneWidget);
  });

  testWidgets('dashboard remains usable in landscape phone layout', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardAtSize(tester, const Size(640, 360));

    expect(tester.takeException(), isNull);
    expect(find.text('188'), findsOneWidget);
    expect(find.text('模拟行驶'), findsOneWidget);
  });
}
