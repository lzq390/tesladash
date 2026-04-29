import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';

class PillLabel extends StatelessWidget {
  const PillLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TDashSpacing.lg,
        vertical: TDashSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: TDashTheme.border),
        borderRadius: BorderRadius.circular(TDashRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: TDashTheme.mutedText,
          fontSize: TDashSizes.labelFont,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
