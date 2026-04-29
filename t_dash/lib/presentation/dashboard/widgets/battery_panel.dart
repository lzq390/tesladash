import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_snapshot.dart';
import 'dashboard_panel.dart';

class BatteryPanel extends StatelessWidget {
  const BatteryPanel({required this.snapshot, super.key});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TDashRadius.pill),
            child: LinearProgressIndicator(
              value: snapshot.batteryProgress,
              minHeight: TDashSizes.progressHeight,
              backgroundColor: TDashTheme.progressTrack,
              color: TDashTheme.primary,
            ),
          ),
          const SizedBox(height: TDashSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    snapshot.batteryLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: TDashSizes.bodyStrongFont,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(' 电量'),
                ],
              ),
              Row(
                children: [
                  Text(
                    snapshot.rangeKm.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: TDashSizes.bodyStrongFont,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(' km 续航'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
