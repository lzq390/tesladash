import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_view_model.dart';
import 'dashboard_panel.dart';

class StatusGrid extends StatelessWidget {
  const StatusGrid({required this.viewModel, super.key});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final tiles = [
          StatusTile(
            icon: Icons.air,
            label: '空调',
            value: viewModel.climateLabel,
          ),
          StatusTile(
            icon: Icons.tire_repair,
            label: '胎压',
            value: viewModel.tirePressureLabel,
          ),
        ];

        if (!maxWidth.isFinite) {
          return Row(
            children: [
              for (final tile in tiles) ...[
                Expanded(child: tile),
                if (tile != tiles.last) const SizedBox(width: TDashSpacing.lg),
              ],
            ],
          );
        }

        final columnCount = maxWidth < 430 ? 1 : 2;
        final spacing = TDashSpacing.lg;
        final tileWidth =
            (maxWidth - (spacing * (columnCount - 1))) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TDashTheme.subtleText,
              fontSize: TDashSizes.labelFont,
            ),
          ),
          const SizedBox(height: TDashSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
