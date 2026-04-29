import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_snapshot.dart';
import 'dashboard_panel.dart';

class StatusGrid extends StatelessWidget {
  const StatusGrid({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatusTile(
            icon: Icons.air,
            label: '空调',
            value: snapshot.climateLabel,
          ),
        ),
        const SizedBox(width: TDashSpacing.lg),
        Expanded(
          child: StatusTile(
            icon: Icons.tire_repair,
            label: '胎压',
            value: snapshot.tirePressureLabel,
          ),
        ),
        const SizedBox(width: TDashSpacing.lg),
        Expanded(
          child: StatusTile(
            icon: Icons.electric_bolt,
            label: '充电',
            value: snapshot.chargingLabel,
          ),
        ),
      ],
    );
  }
}

class StatusTile extends StatelessWidget {
  const StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TDashTheme.secondary),
          const SizedBox(height: TDashSpacing.md),
          Text(
            label,
            style: const TextStyle(
              color: TDashTheme.subtleText,
              fontSize: TDashSizes.labelFont,
            ),
          ),
          const SizedBox(height: TDashSpacing.xs),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
