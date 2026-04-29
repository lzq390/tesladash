import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TDashSpacing.panel),
      decoration: BoxDecoration(
        color: TDashTheme.surface,
        border: Border.all(color: TDashTheme.border),
        borderRadius: BorderRadius.circular(TDashRadius.panel),
      ),
      child: child,
    );
  }
}
