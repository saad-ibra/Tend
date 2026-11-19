import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Headlines - Newsreader
  static TextStyle headlineXl({Color color = AppColors.onSurface}) {
    return GoogleFonts.newsreader(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.2,
      letterSpacing: -0.8,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.newsreader(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.newsreader(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.27,
      letterSpacing: -0.3,
      color: color,
    );
  }

  static TextStyle quote({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.newsreader(
      fontSize: 18,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  // Functional & Body - Manrope
  static TextStyle headlineSm({Color color = AppColors.onSurface}) {
    return GoogleFonts.manrope(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.2,
      color: color,
    );
  }

  static TextStyle bodyLg({Color color = AppColors.onSurface}) {
    return GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = AppColors.onSurface}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = AppColors.outline}) {
    return GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle labelMd({Color color = AppColors.onSurfaceVariant}) {
    return GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.2,
      color: color,
    );
  }

  static TextStyle labelSm({Color color = AppColors.outline}) {
    return GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.3,
      color: color,
    );
  }
}
