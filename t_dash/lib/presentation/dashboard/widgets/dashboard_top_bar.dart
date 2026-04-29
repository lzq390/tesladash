import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_snapshot.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    required this.snapshot,
    required this.onMenuTap,
    super.key,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu),
          tooltip: '菜单',
        ),
        const SizedBox(width: TDashSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.vehicleName,
                style: const TextStyle(
                  fontSize: TDashSizes.bodyStrongFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TDashSpacing.xxs),
              Text(
                snapshot.connectionLabel,
                style: const TextStyle(
                  color: TDashTheme.primary,
                  fontSize: TDashSizes.labelFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TDashSpacing.panel,
            vertical: TDashSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: TDashTheme.primaryTint,
            border: Border.all(color: TDashTheme.primaryBorder),
            borderRadius: BorderRadius.circular(TDashRadius.pill),
          ),
          child: Text(
            snapshot.batteryLabel,
            style: const TextStyle(
              color: TDashTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
