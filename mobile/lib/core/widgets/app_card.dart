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
        elevation = 6;
        borderColor = Colors.transparent;
      case AppCardVariant.outlined:
        elevation = 0;
        borderColor = AppColors.divider;
      case AppCardVariant.normal:
        elevation = 2;
        borderColor = Colors.transparent;
    }

    final card = Material(
      color: AppColors.surface,
      elevation: elevation,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: variant == AppCardVariant.outlined ? 1.0 : 0.0,
          ),
        ),
        child: IntrinsicHeight(
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
