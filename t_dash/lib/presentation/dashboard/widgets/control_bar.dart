import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({required this.onPlaceholderTap, super.key});

  final VoidCallback onPlaceholderTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ControlButton(
            icon: Icons.directions_car,
            label: '模拟行驶',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: TDashSpacing.lg),
        Expanded(
          child: ControlButton(
            icon: Icons.lock_open,
            label: '解锁',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: TDashSpacing.lg),
        Expanded(
          child: ControlButton(
            icon: Icons.air,
            label: '空调',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: TDashSpacing.lg),
        Expanded(
          child: ControlButton(
            icon: Icons.flash_on,
            label: '闪灯',
            onTap: onPlaceholderTap,
          ),
        ),
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  const ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: TDashSpacing.panel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TDashRadius.control),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: TDashSpacing.sm),
          Text(label, style: const TextStyle(fontSize: TDashSizes.labelFont)),
        ],
      ),
    );
  }
}
