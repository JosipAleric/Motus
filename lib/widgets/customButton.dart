import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:iconify_design/iconify_design.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool outlined;
  final String icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final String fontFamily;
  final FontWeight fontWeight;
  final double borderRadius;
  final double iconSize;
  final double? letterSpacing;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.outlined = false,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.fontFamily = 'PlusJakartaSans',
    this.fontWeight = FontWeight.w600,
    this.borderRadius = 5.0,
    this.iconSize = 20.0,
    this.letterSpacing,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: outlined ? Colors.transparent : (color ?? AppColors.primary),
        backgroundColor: outlined ? Colors.white : (color ?? AppColors.primary),
        foregroundColor: outlined ? AppColors.primary : Colors.white,
        elevation: outlined ? 0 : null,
        padding: padding,
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: outlined ? BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
        ),
        minimumSize: const Size(0, 40),
      ),
      child: isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: outlined ? AppColors.primary : Colors.white,
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconifyIcon(
            icon: icon,
            color: outlined ? AppColors.primary : Colors.white,
            size: iconSize,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: fontFamily,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}
