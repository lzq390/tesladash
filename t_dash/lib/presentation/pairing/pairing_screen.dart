import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/t_dash_theme.dart';
import '../../application/pairing/pairing_providers.dart';
import '../../application/pairing/pairing_view_model.dart';
import '../../domain/domain.dart';
import '../dashboard/widgets/dashboard_panel.dart';

class PairingScreen extends ConsumerWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncViewModel = ref.watch(pairingViewModelProvider);
    final viewModel = asyncViewModel.value ?? PairingViewModel.initial();
    final controller = ref.read(pairingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.goNamed(AppRoute.dashboard.name),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('车辆配对'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TDashSpacing.screen),
          children: [
            _PairingStatusPanel(
              viewModel: viewModel,
              onPrimaryAction: () async {
                await controller.startScan();
              },
              onCancel: () async {
                await controller.cancel();
              },
            ),
            const SizedBox(height: TDashSpacing.panel),
            for (final device in viewModel.devices) ...[
              _BleDeviceTile(
                device: device,
                selected: device.id == viewModel.selectedDeviceId,
                busy: viewModel.isBusy,
                onConnect: () async {
                  await controller.connect(device);
                },
              ),
              const SizedBox(height: TDashSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _PairingStatusPanel extends StatelessWidget {
  const _PairingStatusPanel({
    required this.viewModel,
    required this.onPrimaryAction,
    required this.onCancel,
  });

  final PairingViewModel viewModel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PhaseIcon(phase: viewModel.phase),
              const SizedBox(width: TDashSpacing.md),
              Expanded(
                child: Text(
                  viewModel.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: TDashSpacing.md),
          Text(
            viewModel.detail,
            style: const TextStyle(color: TDashTheme.subtleText, height: 1.35),
          ),
          const SizedBox(height: TDashSpacing.panel),
          Row(
            children: [
              FilledButton.icon(
                onPressed: viewModel.primaryActionEnabled
                    ? onPrimaryAction
                    : null,
                icon: viewModel.isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(viewModel.primaryActionLabel),
              ),
              const SizedBox(width: TDashSpacing.md),
              if (viewModel.isBusy)
                TextButton(onPressed: onCancel, child: const Text('取消')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BleDeviceTile extends StatelessWidget {
  const _BleDeviceTile({
    required this.device,
    required this.selected,
    required this.busy,
    required this.onConnect,
  });

  final BleDevice device;
  final bool selected;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Row(
        children: [
          Icon(
            selected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: selected ? TDashTheme.primary : TDashTheme.secondary,
          ),
          const SizedBox(width: TDashSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: TDashSpacing.xs),
                Text(
                  '${device.id} · RSSI ${device.rssi}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TDashTheme.subtleText,
                    fontSize: TDashSizes.labelFont,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TDashSpacing.md),
          FilledButton(
            onPressed: busy ? null : onConnect,
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});

  final PairingPhase phase;

  @override
  Widget build(BuildContext context) {
    final icon = switch (phase) {
      PairingPhase.idle => Icons.bluetooth,
      PairingPhase.permissionRequired => Icons.lock,
      PairingPhase.scanning => Icons.bluetooth_searching,
      PairingPhase.devicesFound => Icons.list_alt,
      PairingPhase.connecting => Icons.sync,
      PairingPhase.waitingForVehicle => Icons.check_circle,
      PairingPhase.failed => Icons.error,
    };

    final color = switch (phase) {
      PairingPhase.failed => TDashTheme.danger,
      PairingPhase.permissionRequired => TDashTheme.warning,
      PairingPhase.waitingForVehicle => TDashTheme.primary,
      _ => TDashTheme.secondary,
    };

    return Icon(icon, color: color);
  }
}
