import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Sunshine Palette - Lekker Kids
  static const Color primary = Color(0xFFFF8000);    // Vibrant Tangerine
  static const Color primaryDark = Color(0xFFC2410C);
  static const Color primaryLight = Color(0xFFFFB74D);
  
  static const Color secondary = Color(0xFFFFD166);  // Sunny Yellow
  static const Color secondaryDark = Color(0xFFE6A300);
  static const Color secondaryLight = Color(0xFFFFECB3);

  static const Color accent = Color(0xFFEF476F);     // Warm Rose (Complementary)
  
  // Background Colors - Warm Tones
  static const Color background = Color(0xFFFFF8F0); // Warm Cream/Beige
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFFDF0E0); // Light Orange Tint
  
  // Text Colors - Warm Neutrals
  static const Color textPrimary = Color(0xFF4A403A); // Warm Dark Brown
  static const Color textSecondary = Color(0xFF7D726D); // Warm Grey/Brown
  static const Color textHint = Color(0xFFA89F99);
  static const Color textWhite = Colors.white;
  static const Color textOnPrimary = Colors.white;
  
  // Status Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorBorder = Color(0xFFFFCDD2); // Restored
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  
  // Attendance Colors
  static const Color attendancePresent = Color(0xFF4CAF50); // Green
  static const Color attendanceAbsent = Color(0xFFE57373);  // Soft Red
  static const Color attendanceLate = Color(0xFFFFB74D);    // Soft Orange
  
  // Icon Colors
  static const Color iconPrimary = Color(0xFFFF8000);
  static const Color iconSecondary = Color(0xFF7D726D);
  
  // Disabled
  static const Color disabledBackground = Color(0xFFE0E0E0);
  static const Color disabledText = Color(0xFFBDBDBD);
}

class AppSpacing {
  // Padding
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 24.0;
  static const double paddingXXLarge = 32.0;
  static const double paddingHuge = 48.0;
  
  // Margins
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 100.0;
  
  // Icon Sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHuge = 80.0;
  
  // Emoji Size
  static const double emojiLarge = 40.0;
  
  // Loading
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorStroke = 2.0; // Restored
}

class AppTextStyles {
  // Using Nunito for a friendly, approachable look
  
  static TextStyle get headlineLarge => GoogleFonts.nunito(
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.nunito(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get titleMedium => GoogleFonts.nunito(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16.0,
    fontWeight: FontWeight.w600, // Slightly bolder for readability on cream
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get button => GoogleFonts.nunito(
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
  
  static TextStyle get error => GoogleFonts.nunito(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
  );
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration snackBar = Duration(seconds: 4);
  static const Duration snackBarDuration = snackBar; // Restored alias
}

class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppDecorations {
  static final BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
    boxShadow: AppShadows.card,
  );
  
  static final BoxDecoration cardInteractive = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
    boxShadow: AppShadows.card,
    border: Border.all(color: AppColors.surfaceVariant, width: 1),
  );
  
  static final BoxDecoration activeCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
    border: Border.all(color: AppColors.primaryLight, width: 2),
  );
}
