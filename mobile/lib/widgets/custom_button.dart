import 'package:flutter/material.dart';

import '../config/theme.dart';

class CustomButton extends StatelessWidget {

  const CustomButton({
    required this.text, super.key,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height,
    this.fontSize,
    this.padding,
    this.borderRadius,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? height;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(final BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primaryGreen,
            side: BorderSide(
              color: backgroundColor ?? AppColors.primaryGreen,
              width: 1.5,
            ),
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primaryGreen,
            foregroundColor: textColor ?? Colors.white,
            disabledBackgroundColor: AppColors.grey300,
            disabledForegroundColor: AppColors.grey500,
            elevation: 0,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
          );

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? AppColors.primaryGreen : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Widget button;
    if (isOutlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height ?? 52,
        child: button,
      );
    }

    return SizedBox(
      height: height ?? 52,
      child: button,
    );
  }
}

class CustomIconButton extends StatelessWidget {

  const CustomIconButton({
    required this.icon, super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
    this.tooltip,
    this.isLoading = false,
    this.badge,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool isLoading;
  final Widget? badge;

  @override
  Widget build(final BuildContext context) {
    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        iconColor ?? AppColors.grey700,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? AppColors.grey700,
                  ),
          ),
        ),
      ),
    );

    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -4,
            right: -4,
            child: badge!,
          ),
        ],
      );
    }

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

class CustomTextButton extends StatelessWidget {

  const CustomTextButton({
    required this.text, super.key,
    this.onPressed,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.fontSize,
  });
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final double? fontSize;

  @override
  Widget build(final BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? AppColors.primaryGreen,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: textColor ?? AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? AppColors.primaryGreen,
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class SocialButton extends StatelessWidget {

  const SocialButton({
    required this.text, required this.iconAsset, super.key,
    this.onPressed,
    this.isLoading = false,
  });
  final String text;
  final String iconAsset;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey700,
          side: const BorderSide(color: AppColors.grey300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 24,
                    height: 24,
                    errorBuilder: (_, final __, final ___) => const Icon(Icons.login),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FloatingActionButtonExtended extends StatelessWidget {

  const FloatingActionButtonExtended({
    required this.text, required this.icon, super.key,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(final BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primaryGreen,
      foregroundColor: foregroundColor ?? Colors.white,
      icon: Icon(icon),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
