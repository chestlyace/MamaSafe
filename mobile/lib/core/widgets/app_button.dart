import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool disabled;
  final IconData? iconLeft;
  final IconData? iconRight;
  final double? width;
  final double height;

  const AppButton._(
    this.label, {
    super.key,
    required this.onPressed,
    this.loading = false,
    this.disabled = false,
    this.iconLeft,
    this.iconRight,
    this.width,
    this.height = 48,
    required Color foregroundColor,
    required Color backgroundColor,
    required Color? borderColor,
  })  : _foregroundColor = foregroundColor,
        _backgroundColor = backgroundColor,
        _borderColor = borderColor;

  final Color _foregroundColor;
  final Color _backgroundColor;
  final Color? _borderColor;

  factory AppButton.primary(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool loading = false,
    bool disabled = false,
    IconData? iconLeft,
    IconData? iconRight,
    double? width,
    double height = 48,
  }) {
    return AppButton._(
      label,
      key: key,
      onPressed: onPressed,
      loading: loading,
      disabled: disabled,
      iconLeft: iconLeft,
      iconRight: iconRight,
      width: width,
      height: height,
      foregroundColor: AppColors.textOnPrimary,
      backgroundColor: AppColors.primary,
      borderColor: null,
    );
  }

  factory AppButton.secondary(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool loading = false,
    bool disabled = false,
    IconData? iconLeft,
    IconData? iconRight,
    double? width,
    double height = 48,
  }) {
    return AppButton._(
      label,
      key: key,
      onPressed: onPressed,
      loading: loading,
      disabled: disabled,
      iconLeft: iconLeft,
      iconRight: iconRight,
      width: width,
      height: height,
      foregroundColor: AppColors.textOnPrimary,
      backgroundColor: AppColors.secondary,
      borderColor: null,
    );
  }

  factory AppButton.outline(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool loading = false,
    bool disabled = false,
    IconData? iconLeft,
    IconData? iconRight,
    double? width,
    double height = 48,
  }) {
    return AppButton._(
      label,
      key: key,
      onPressed: onPressed,
      loading: loading,
      disabled: disabled,
      iconLeft: iconLeft,
      iconRight: iconRight,
      width: width,
      height: height,
      foregroundColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      borderColor: AppColors.primary,
    );
  }

  factory AppButton.text(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool loading = false,
    bool disabled = false,
    IconData? iconLeft,
    IconData? iconRight,
    double? width,
    double height = 48,
  }) {
    return AppButton._(
      label,
      key: key,
      onPressed: onPressed,
      loading: loading,
      disabled: disabled,
      iconLeft: iconLeft,
      iconRight: iconRight,
      width: width,
      height: height,
      foregroundColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      borderColor: null,
    );
  }

  bool get _isEffectivelyDisabled => disabled || loading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = _isEffectivelyDisabled ? null : onPressed;
    final foreground = _isEffectivelyDisabled
        ? _foregroundColor.withValues(alpha: 0.4)
        : _foregroundColor;
    final background = _isEffectivelyDisabled
        ? _backgroundColor.withValues(alpha: 0.4)
        : _backgroundColor;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: _borderColor != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: foreground, width: 1.5),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  _LoadingIndicator(color: foreground)
                else ...[
                  if (iconLeft != null) ...[
                    Icon(iconLeft, size: 20, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (iconRight != null) ...[
                    const SizedBox(width: 8),
                    Icon(iconRight, size: 20, color: foreground),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;

  const _LoadingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
