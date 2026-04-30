import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_view_model.dart';
import 'dashboard_panel.dart';

class BatteryPanel extends StatelessWidget {
  const BatteryPanel({required this.viewModel, super.key});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TDashRadius.pill),
            child: LinearProgressIndicator(
              value: viewModel.batteryProgress,
              minHeight: TDashSizes.progressHeight,
              backgroundColor: TDashTheme.progressTrack,
              color: TDashTheme.primary,
            ),
          ),
          const SizedBox(height: TDashSpacing.lg),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: TDashSpacing.xs,
            spacing: TDashSpacing.xl,
            children: [
              _BatteryMetric(value: viewModel.batteryLabel, unit: '电量'),
              _BatteryMetric(value: viewModel.rangeLabel, unit: 'km 续航'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryMetric extends StatelessWidget {
  const _BatteryMetric({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: TDashSizes.bodyStrongFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: ' $unit'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
