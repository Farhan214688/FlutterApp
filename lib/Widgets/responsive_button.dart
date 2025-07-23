import 'package:flutter/material.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isFullWidth;
  final double? minWidth;
  final double? height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isFullWidth = false,
    this.minWidth,
    this.height,
    this.fontSize = 16,
    this.padding,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width to calculate responsive sizes
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions
    final buttonWidth = isFullWidth ? screenWidth * 0.9 : minWidth ?? screenWidth * 0.4;
    final buttonHeight = height ?? screenWidth * 0.12;
    final buttonPadding = padding ?? EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenWidth * 0.02,
    );
    final buttonFontSize = fontSize * (screenWidth / 375); // Base font size on 375 width

    return Container(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.lightGreen,
          foregroundColor: textColor ?? Colors.white,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight * 0.25),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: buttonHeight * 0.4,
                height: buttonHeight * 0.4,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: buttonFontSize * 1.2),
                    SizedBox(width: buttonWidth * 0.02),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 