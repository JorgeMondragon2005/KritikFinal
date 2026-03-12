// lib/theme/app_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundOffWhite = Color(0xFFF9F9FA);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF808080);
  static const Color successGreen = Color(0xFF2ECA7F);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color errorRed = Color(0xFFFF4C4C);
  static const Color techChipBg = Color(0xFFF3F4F6);
  static const Color inactiveSlider = Color(0xFFEEEEEE);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.backgroundOffWhite,
      primaryColor: AppColors.primaryYellow,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryYellow,
        surface: AppColors.backgroundOffWhite,
        error: AppColors.errorRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontSize: 42,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: 2.0,
          ),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size.fromHeight(50),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryYellow,
        inactiveTrackColor: AppColors.inactiveSlider,
        trackHeight: 12.0,
        thumbColor: AppColors.primaryYellow,
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: CustomSliderThumbCircle(
          thumbRadius: 14.0,
          borderThickness: 3.0,
        ),
      ),
    );
  }
}

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CustomSliderThumbCircle extends SliderComponentShape {
  final double thumbRadius;
  final double borderThickness;

  const CustomSliderThumbCircle({
    required this.thumbRadius,
    this.borderThickness = 3.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? AppColors.primaryYellow
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = borderThickness
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, thumbRadius, paint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
