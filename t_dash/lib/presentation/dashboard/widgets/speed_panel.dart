import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_view_model.dart';
import 'pill_label.dart';

class SpeedPanel extends StatelessWidget {
  const SpeedPanel({required this.viewModel, super.key});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          final diameter =
              (shortestSide.isFinite
                      ? shortestSide
                      : TDashSizes.speedDiameterMax)
                  .clamp(0.0, TDashSizes.speedDiameterMax);

          return SizedBox.square(
            dimension: diameter,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TDashTheme.speedBorder),
                boxShadow: const [
                  BoxShadow(
                    color: TDashTheme.speedGlow,
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
                gradient: const RadialGradient(
                  colors: [
                    TDashTheme.speedGradientStart,
                    TDashTheme.speedGradientEnd,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(TDashSpacing.speedInner),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PillLabel(text: viewModel.speedSourceLabel),
                          const SizedBox(width: TDashSpacing.md),
                          PillLabel(text: viewModel.drivingLabel),
                        ],
                      ),
                      const SizedBox(height: TDashSpacing.xl),
                      Text(
                        viewModel.speedText,
                        style: const TextStyle(
                          fontSize: TDashSizes.speedFont,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: TDashSpacing.md),
                      Text(
                        viewModel.speedUnitText,
                        style: const TextStyle(
                          color: TDashTheme.mutedText,
                          fontSize: TDashSizes.unitFont,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
