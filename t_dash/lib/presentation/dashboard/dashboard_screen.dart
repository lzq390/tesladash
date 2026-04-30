import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/t_dash_theme.dart';
import '../../application/dashboard/dashboard_providers.dart';
import '../../application/dashboard/dashboard_view_model.dart';
import 'widgets/battery_panel.dart';
import 'widgets/control_bar.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/speed_panel.dart';
import 'widgets/status_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final compact = constraints.maxHeight < 620 || textScale > 1.2;
            final content = Column(
              children: _buildSections(
                context: context,
                ref: ref,
                viewModel: viewModel,
                compact: compact,
                availableHeight: constraints.maxHeight,
              ),
            );

            if (compact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(TDashSpacing.screen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(TDashSpacing.screen),
              child: content,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSections({
    required BuildContext context,
    required WidgetRef ref,
    required DashboardViewModel viewModel,
    required bool compact,
    required double availableHeight,
  }) {
    void menuFeedback() {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置页开发中')));
    }

    Future<void> handleControl(QuickControlButtonModel control) async {
      final messenger = ScaffoldMessenger.of(context);
      final controller = ref.read(dashboardControllerProvider);

      if (control.action == QuickControlAction.toggleSimulatedDriving) {
        await controller.toggleSimulatedDriving();
        return;
      }

      final commandType = control.commandType;
      if (commandType == null) {
        return;
      }

      final result = await controller.sendCommand(commandType);
      messenger.showSnackBar(SnackBar(content: Text(result.userMessage)));
    }

    final speedPanel = SpeedPanel(viewModel: viewModel);

    return [
      DashboardTopBar(viewModel: viewModel, onMenuTap: menuFeedback),
      SizedBox(height: compact ? TDashSpacing.xl : TDashSpacing.hero),
      if (compact)
        SizedBox(
          height: _compactSpeedHeight(availableHeight),
          child: speedPanel,
        )
      else
        Expanded(child: speedPanel),
      SizedBox(height: compact ? TDashSpacing.xl : TDashSpacing.section),
      BatteryPanel(viewModel: viewModel),
      SizedBox(height: compact ? TDashSpacing.lg : TDashSpacing.panel),
      StatusGrid(viewModel: viewModel),
      SizedBox(height: compact ? TDashSpacing.lg : TDashSpacing.panel),
      ControlBar(
        controls: viewModel.quickControls,
        onControlTap: handleControl,
      ),
    ];
  }

  double _compactSpeedHeight(double availableHeight) {
    return (availableHeight * 0.38).clamp(150.0, 240.0).toDouble();
  }
}
