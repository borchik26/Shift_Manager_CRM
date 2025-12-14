import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/core/ui/constants/border_radius.dart';
import 'package:my_app/core/ui/constants/breakpoints.dart';
import 'package:my_app/core/ui/constants/durations.dart';
import 'package:my_app/core/ui/constants/kit_colors.dart';
import 'package:my_app/core/ui/constants/shadows.dart';
import 'package:my_app/core/ui/constants/spacing.dart';
import 'package:my_app/core/ui/constants/text_styles.dart';

class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseTheme = isLight ? ThemeData.light() : ThemeData.dark();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0088CC), // Updated Blue
        brightness: brightness,
        background: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF121212),
        surface: isLight ? Colors.white : const Color(0xFF1E1E1E),
        primary: const Color(0xFF0088CC), // Explicit primary
        onPrimary: Colors.white,
        surfaceVariant: isLight ? const Color(0xFFF9FAFB) : const Color(0xFF2C2C2C), // Для headers
        onSurface: isLight ? const Color(0xFF1F2937) : Colors.white, // Для текста
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: isLight ? const Color(0xFF333333) : Colors.white,
        displayColor: isLight ? const Color(0xFF333333) : Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Flat style
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // More rounded
        ),
        color: isLight ? Colors.white : const Color(0xFF1E1E1E),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // Rounded search bar style
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF0088CC)),
        ),
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0088CC),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Rounded buttons
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      extensions: [
        const CustomSpacing(),
        const CustomTextStyles(),
        const KitColorsExtension(),
        const CustomShadows(),
        const CustomBorderRadius(),
        const CustomDurations(),
        const CustomBreakpoints(),
      ],
    );
  }
}

extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  CustomSpacing get spacing => theme.extension<CustomSpacing>() ?? const CustomSpacing();
  CustomTextStyles get textStyles => theme.extension<CustomTextStyles>() ?? const CustomTextStyles();
  KitColorsExtension get kitColors => theme.extension<KitColorsExtension>() ?? const KitColorsExtension();
  CustomShadows get shadows => theme.extension<CustomShadows>() ?? const CustomShadows();
  CustomBorderRadius get borderRadius => theme.extension<CustomBorderRadius>() ?? const CustomBorderRadius();
  CustomDurations get durations => theme.extension<CustomDurations>() ?? const CustomDurations();
  CustomBreakpoints get breakpoints => theme.extension<CustomBreakpoints>() ?? const CustomBreakpoints();
}