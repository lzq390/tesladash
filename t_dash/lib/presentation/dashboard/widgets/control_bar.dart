import 'package:flutter/material.dart';

import '../../../app/theme/t_dash_theme.dart';
import '../../../application/dashboard/dashboard_view_model.dart';
import '../../../domain/domain.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    required this.controls,
    required this.onControlTap,
    super.key,
  });

  final List<QuickControlButtonModel> controls;
  final ValueChanged<QuickControlButtonModel> onControlTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final control in controls) ...[
          Expanded(
            child: ControlButton(
              control: control,
              onTap: () => onControlTap(control),
            ),
          ),
          if (control != controls.last) const SizedBox(width: TDashSpacing.lg),
        ],
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  const ControlButton({required this.control, required this.onTap, super.key});

  final QuickControlButtonModel control;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = control.enabled ? null : TDashTheme.subtleText;

    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: TDashSpacing.panel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TDashRadius.control),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(control)),
          const SizedBox(height: TDashSpacing.sm),
          Text(
            control.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: TDashSizes.labelFont),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(QuickControlButtonModel control) {
    if (control.action == QuickControlAction.toggleSimulatedDriving) {
      return Icons.directions_car;
    }

    return switch (control.commandType) {
      ControlCommandType.lock => Icons.lock,
      ControlCommandType.unlock => Icons.lock_open,
      ControlCommandType.startClimate => Icons.air,
      ControlCommandType.stopClimate => Icons.air,
      ControlCommandType.setClimateTemperature => Icons.thermostat,
      ControlCommandType.flashLights => Icons.flash_on,
      ControlCommandType.honk => Icons.campaign,
      ControlCommandType.openFrunk => Icons.inventory_2,
      ControlCommandType.openTrunk => Icons.business_center,
      ControlCommandType.enableSentry => Icons.shield,
      ControlCommandType.disableSentry => Icons.shield_outlined,
      null => Icons.touch_app,
    };
  }
}
