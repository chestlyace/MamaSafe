import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpIcon extends StatelessWidget {
  final String message;

  const HelpIcon({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: const Icon(
        Icons.info_outline,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }
}
