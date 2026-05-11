import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:t_dash/app/routing/app_router.dart';
import 'package:t_dash/app/t_dash_app.dart';
import 'package:t_dash/application/ble/ble_providers.dart';
import 'package:t_dash/application/dashboard/dashboard_providers.dart';
import 'package:t_dash/application/dashboard/dashboard_view_model.dart';
import 'package:t_dash/application/pairing/pairing_controller.dart';
import 'package:t_dash/application/pairing/pairing_key_repository.dart';
import 'package:t_dash/application/pairing/pairing_providers.dart';
import 'package:t_dash/domain/domain.dart';
import 'package:t_dash/infrastructure/mock/in_memory_secure_key_value_store.dart';
import 'package:t_dash/infrastructure/mock/mock_ble_gateway.dart';
import 'package:t_dash/infrastructure/mock/mock_control_command_service.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_data_provider.dart';
import 'package:t_dash/infrastructure/mock/mock_vehicle_pairing_service.dart';
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
    if (viewModel == null) ...[
      vehicleDataSourceProvider.overrideWithValue(
        MockVehicleDataProvider.initial(now: DateTime(2026)),
      ),
      velocitySourceProvider.overrideWithValue(
        MockVelocityProvider.initial(now: DateTime(2026)),
      ),
    ],
    if (viewModel != null)
      dashboardViewModelProvider.overrideWithValue(viewModel),
  ];

  return ProviderScope(overrides: overrides, child: const TDashApp());
}

Widget _buildPairingApp({
  required MockBleGateway mockBleGateway,
  required PairingController pairingController,
}) {
  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(
        createAppRouter(initialLocation: '/pairing'),
      ),
      bleGatewayProvider.overrideWithValue(mockBleGateway),
      pairingControllerProvider.overrideWithValue(pairingController),
    ],
    child: const TDashApp(),
  );
}

Widget _buildDashboardAppWithPairingMocks(WidgetTester tester) {
  final mockBleGateway = MockBleGateway();
  final pairingController = PairingController(
    bleGateway: mockBleGateway,
    pairingKeyRepository: _pairingKeyRepository(),
    vehiclePairingService: _vehiclePairingService(),
    scanDuration: Duration.zero,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pairingController.dispose();
    mockBleGateway.dispose();
  });

  return ProviderScope(
    overrides: [
      appRouterProvider.overrideWithValue(
        createAppRouter(initialLocation: '/'),
      ),
      vehicleDataSourceProvider.overrideWithValue(
        MockVehicleDataProvider.initial(now: DateTime(2026)),
      ),
      velocitySourceProvider.overrideWithValue(
        MockVelocityProvider.initial(now: DateTime(2026)),
      ),
      bleGatewayProvider.overrideWithValue(mockBleGateway),
      pairingControllerProvider.overrideWithValue(pairingController),
    ],
    child: const TDashApp(),
  );
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

  testWidgets('menu opens pairing route', (WidgetTester tester) async {
    await tester.pumpWidget(_buildDashboardAppWithPairingMocks(tester));

    await tester.tap(find.byTooltip('菜单'));
    await tester.pumpAndSettle();

    expect(find.text('车辆配对'), findsOneWidget);
    expect(find.text('扫描车辆'), findsOneWidget);
  });

  testWidgets('settings placeholder route is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialLocation: '/settings'));

    expect(find.text('设置页开发中'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
  });

  testWidgets('pairing page scans and connects mock BLE devices', (
    WidgetTester tester,
  ) async {
    final mockBleGateway = MockBleGateway();
    final pairingController = PairingController(
      bleGateway: mockBleGateway,
      pairingKeyRepository: _pairingKeyRepository(),
      vehiclePairingService: _vehiclePairingService(),
      scanDuration: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pairingController.dispose();
      mockBleGateway.dispose();
    });

    await tester.pumpWidget(
      _buildPairingApp(
        mockBleGateway: mockBleGateway,
        pairingController: pairingController,
      ),
    );

    expect(find.text('扫描车辆'), findsOneWidget);

    await tester.tap(find.text('扫描车辆'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    expect(find.text('Tesla Model 3'), findsOneWidget);
    expect(find.text('Nearby BLE Device'), findsOneWidget);

    final connectButton = find.widgetWithText(FilledButton, '连接').first;
    await tester.ensureVisible(connectButton);
    await tester.pump();
    await tester.tap(connectButton);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    expect(pairingController.currentState.title, '配对成功');
    expect(find.text('配对成功'), findsOneWidget);
    expect(find.textContaining('本机公钥已被车辆接受'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
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

VehiclePairingService _vehiclePairingService() {
  return const MockVehiclePairingService();
}

PairingKeyRepository _pairingKeyRepository() {
  return PairingKeyRepository(
    keyService: _FakePairingKeyService(),
    secureStore: InMemorySecureKeyValueStore(),
  );
}

class _FakePairingKeyService implements PairingKeyService {
  int generatedCount = 0;

  @override
  Future<PairingKeyMaterial> generateKeyPair() async {
    generatedCount += 1;
    return PairingKeyMaterial(
      id: 'fake-$generatedCount',
      privateKeyBase64: base64Encode(List.filled(32, generatedCount)),
      publicKeySec1Base64: base64Encode([
        0x04,
        ...List.filled(64, generatedCount),
      ]),
      createdAt: DateTime(2026, 5, generatedCount),
    );
  }
}
