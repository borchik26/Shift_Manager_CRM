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
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: brightness,
        background: isLight ? const Color(0xFFF5F7FA) : const Color(0xFF121212),
        surface: isLight ? Colors.white : const Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isLight ? Colors.white : const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF2C2C2C),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  CustomSpacing get spacing => theme.extension<CustomSpacing>()!;
  CustomTextStyles get textStyles => theme.extension<CustomTextStyles>()!;
  KitColorsExtension get kitColors => theme.extension<KitColorsExtension>()!;
  CustomShadows get shadows => theme.extension<CustomShadows>()!;
  CustomBorderRadius get borderRadius => theme.extension<CustomBorderRadius>()!;
  CustomDurations get durations => theme.extension<CustomDurations>()!;
  CustomBreakpoints get breakpoints => theme.extension<CustomBreakpoints>()!;
}