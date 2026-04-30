import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:t_dash/app/routing/app_router.dart';
import 'package:t_dash/app/t_dash_app.dart';
import 'package:t_dash/application/dashboard/dashboard_providers.dart';
import 'package:t_dash/application/dashboard/dashboard_view_model.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/mock_control_command_service.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_data_provider.dart';
import 'package:t_dash/infrastructure/mock/mock_velocity_provider.dart';

DashboardViewModel _viewModel({
  VehicleState? vehicle,
  VelocitySample? velocity,
}) {
  return DashboardViewModel.fromDomain(
    vehicle: vehicle ?? mockVehicleState(now: DateTime(2026)),
    velocity: velocity ?? mockVelocitySample(now: DateTime(2026)),
    commandService: MockControlCommandService(),
  );
}

DashboardViewModel _stressViewModel() {
  return _viewModel(
    vehicle: mockVehicleState(now: DateTime(2026), drivingModeActive: true)
        .copyWith(
          battery: const BatteryState(
            stateOfChargePercent: 100,
            ratedRangeKm: 512,
            estimatedRangeKm: 500,
            health: ProviderHealth.healthy,
          ),
          climate: const ClimateState(
            isOn: true,
            insideTempC: 22,
            outsideTempC: 18,
            setTempC: 18,
            health: ProviderHealth.healthy,
          ),
        ),
    velocity: mockVelocitySample(now: DateTime(2026), kmh: 188),
  );
}

DashboardViewModel _longStatusViewModel() {
  return _viewModel(
    vehicle: mockVehicleState(now: DateTime(2026), drivingModeActive: true)
        .copyWith(
          displayName: 'Model 3 Performance',
          battery: const BatteryState(
            stateOfChargePercent: 100,
            ratedRangeKm: 512,
            estimatedRangeKm: 500,
            health: ProviderHealth.healthy,
          ),
          climate: const ClimateState(
            isOn: true,
            insideTempC: 22,
            outsideTempC: 18,
            setTempC: 18,
            health: ProviderHealth.healthy,
          ),
          tirePressure: const TirePressureState(
            frontLeftBar: null,
            frontRightBar: null,
            rearLeftBar: null,
            rearRightBar: null,
            health: ProviderHealth.unavailable,
          ),
        ),
    velocity: mockVelocitySample(now: DateTime(2026), kmh: 188),
  );
}

Widget _buildApp({
  String initialLocation = '/',
  DashboardViewModel? viewModel,
}) {
  final overrides = [
    appRouterProvider.overrideWithValue(
      createAppRouter(initialLocation: initialLocation),
    ),
    if (viewModel != null)
      dashboardViewModelProvider.overrideWithValue(viewModel),
  ];

  return ProviderScope(overrides: overrides, child: const TDashApp());
}

Finder _richTextContaining(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(value),
  );
}

Future<void> _pumpDashboardAtSize(
  WidgetTester tester,
  Size size, {
  DashboardViewModel? viewModel,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    _buildApp(viewModel: viewModel ?? _stressViewModel()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('Model 3'), findsOneWidget);
    expect(find.text('BLE 已连接'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(find.text('Mock'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(_richTextContaining('电量'), findsOneWidget);
    expect(_richTextContaining('412'), findsOneWidget);
    expect(find.text('模拟行驶'), findsOneWidget);
    expect(find.text('解锁'), findsOneWidget);
    expect(find.text('空调'), findsWidgets);
    expect(find.text('闪灯'), findsOneWidget);
    expect(find.text('充电'), findsNothing);
    expect(find.text('未连接'), findsNothing);
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

  testWidgets('control buttons update mock state and show command feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('模拟行驶'));
    await tester.pumpAndSettle();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('停止模拟'), findsOneWidget);

    await tester.tap(find.text('解锁'));
    await tester.pump();

    expect(find.text('请停车后再操作'), findsOneWidget);
  });

  testWidgets('dashboard fits compact portrait without layout exceptions', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardAtSize(tester, const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('188'), findsOneWidget);
    expect(find.text('Mock'), findsOneWidget);
  });

  testWidgets('dashboard remains usable in landscape phone layout', (
    WidgetTester tester,
  ) async {
    await _pumpDashboardAtSize(tester, const Size(640, 360));

    expect(tester.takeException(), isNull);
    expect(find.text('188'), findsOneWidget);
    expect(find.text('停止模拟'), findsOneWidget);
  });

  testWidgets('status cards tolerate long text with larger font scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpDashboardAtSize(
      tester,
      const Size(360, 640),
      viewModel: _longStatusViewModel(),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('运行 18°C'), findsOneWidget);
    expect(find.text('胎压数据暂不可用'), findsOneWidget);
  });
}
