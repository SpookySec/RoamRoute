import 'package:flutter/material.dart';
import '../theme/duo_theme.dart';
import '../services/sound_service.dart';

class DuoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const DuoTextField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: DuoColors.duoGray),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.bold, color: DuoColors.duoTextMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: DuoColors.duoGray),
            prefixIcon: icon != null ? Icon(icon, color: DuoColors.duoGray) : null,
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: DuoColors.duoCardBorder, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: DuoColors.duoBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: DuoColors.duoRed, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: DuoColors.duoRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class DuoButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final Color shadowColor;
  final bool isLoading;
  final double? width;

  const DuoButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.color = DuoColors.duoGreen,
    this.shadowColor = DuoColors.duoGreenDark,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        DuoSoundService.playClick();
        onTap();
      },
      child: Container(
        height: 55,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(
                  text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                ),
        ),
      ),
    );
  }
}
