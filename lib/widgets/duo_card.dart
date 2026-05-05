import 'package:flutter/material.dart';
import '../theme/duo_theme.dart';

class DuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double shadowHeight;

  const DuoCard({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.borderWidth = 2,
    this.shadowHeight = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? const Color(0xFF1A1A1A) : Colors.white);
    final borderCol = borderColor ?? (isDark ? DuoColors.duoCardBorderDark : DuoColors.duoCardBorder);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderCol,
            offset: Offset(0, shadowHeight),
          ),
        ],
      ),
      child: child,
    );
  }
}
