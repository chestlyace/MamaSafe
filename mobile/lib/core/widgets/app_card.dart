import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppCardVariant { normal, outlined, elevated }

class AppCard extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const AppCard({
    super.key,
    this.header,
    this.footer,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.normal,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    double elevation;
    Color borderColor;

    switch (variant) {
      case AppCardVariant.elevated:
        elevation = 2;
        borderColor = Colors.transparent;
      case AppCardVariant.outlined:
        elevation = 0;
        borderColor = AppColors.border;
      case AppCardVariant.normal:
        elevation = 0;
        borderColor = AppColors.border;
    }

    final card = Material(
      color: AppColors.surface,
      elevation: elevation,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? 0,
          minHeight: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Padding(
              padding: padding,
              child: child,
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
