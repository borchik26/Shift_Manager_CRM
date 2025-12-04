import 'package:flutter/material.dart';

@immutable
class KitColorsExtension extends ThemeExtension<KitColorsExtension> {
  // Red Colors
  final Color red50;
  final Color red100;
  final Color red200;
  final Color red300;
  final Color red400;
  final Color red500;
  final Color red600;
  final Color red700;
  final Color red800;
  final Color red900;
  final Color red950;

  // Yellow Colors
  final Color yellow50;
  final Color yellow100;
  final Color yellow200;
  final Color yellow300;
  final Color yellow400;
  final Color yellow500;
  final Color yellow600;
  final Color yellow700;
  final Color yellow800;
  final Color yellow900;
  final Color yellow950;

  // Green Colors
  final Color green50;
  final Color green100;
  final Color green200;
  final Color green300;
  final Color green400;
  final Color green500;
  final Color green600;
  final Color green700;
  final Color green800;
  final Color green900;
  final Color green950;

  // Orange Colors
  final Color orange50;
  final Color orange100;
  final Color orange200;
  final Color orange300;
  final Color orange400;
  final Color orange500;
  final Color orange600;
  final Color orange700;
  final Color orange800;
  final Color orange900;
  final Color orange950;

  // Cyan Colors
  final Color cyan50;
  final Color cyan100;
  final Color cyan200;
  final Color cyan300;
  final Color cyan400;
  final Color cyan500;
  final Color cyan600;
  final Color cyan700;
  final Color cyan800;
  final Color cyan900;
  final Color cyan950;

  // Purple Colors
  final Color purple50;
  final Color purple100;
  final Color purple200;
  final Color purple300;
  final Color purple400;
  final Color purple500;
  final Color purple600;
  final Color purple700;
  final Color purple800;
  final Color purple900;
  final Color purple950;

  // Gray Colors
  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color gray950;

  // Neutral Colors
  final Color neutral50;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;
  final Color neutral950;

  const KitColorsExtension({
    // Red Colors
    this.red50 = KitColors.red50,
    this.red100 = KitColors.red100,
    this.red200 = KitColors.red200,
    this.red300 = KitColors.red300,
    this.red400 = KitColors.red400,
    this.red500 = KitColors.red500,
    this.red600 = KitColors.red600,
    this.red700 = KitColors.red700,
    this.red800 = KitColors.red800,
    this.red900 = KitColors.red900,
    this.red950 = KitColors.red950,
    // Yellow Colors
    this.yellow50 = KitColors.yellow50,
    this.yellow100 = KitColors.yellow100,
    this.yellow200 = KitColors.yellow200,
    this.yellow300 = KitColors.yellow300,
    this.yellow400 = KitColors.yellow400,
    this.yellow500 = KitColors.yellow500,
    this.yellow600 = KitColors.yellow600,
    this.yellow700 = KitColors.yellow700,
    this.yellow800 = KitColors.yellow800,
    this.yellow900 = KitColors.yellow900,
    this.yellow950 = KitColors.yellow950,
    // Green Colors
    this.green50 = KitColors.green50,
    this.green100 = KitColors.green100,
    this.green200 = KitColors.green200,
    this.green300 = KitColors.green300,
    this.green400 = KitColors.green400,
    this.green500 = KitColors.green500,
    this.green600 = KitColors.green600,
    this.green700 = KitColors.green700,
    this.green800 = KitColors.green800,
    this.green900 = KitColors.green900,
    this.green950 = KitColors.green950,
    // Orange Colors
    this.orange50 = KitColors.orange50,
    this.orange100 = KitColors.orange100,
    this.orange200 = KitColors.orange200,
    this.orange300 = KitColors.orange300,
    this.orange400 = KitColors.orange400,
    this.orange500 = KitColors.orange500,
    this.orange600 = KitColors.orange600,
    this.orange700 = KitColors.orange700,
    this.orange800 = KitColors.orange800,
    this.orange900 = KitColors.orange900,
    this.orange950 = KitColors.orange950,
    // Cyan Colors
    this.cyan50 = KitColors.cyan50,
    this.cyan100 = KitColors.cyan100,
    this.cyan200 = KitColors.cyan200,
    this.cyan300 = KitColors.cyan300,
    this.cyan400 = KitColors.cyan400,
    this.cyan500 = KitColors.cyan500,
    this.cyan600 = KitColors.cyan600,
    this.cyan700 = KitColors.cyan700,
    this.cyan800 = KitColors.cyan800,
    this.cyan900 = KitColors.cyan900,
    this.cyan950 = KitColors.cyan950,
    // Purple Colors
    this.purple50 = KitColors.purple50,
    this.purple100 = KitColors.purple100,
    this.purple200 = KitColors.purple200,
    this.purple300 = KitColors.purple300,
    this.purple400 = KitColors.purple400,
    this.purple500 = KitColors.purple500,
    this.purple600 = KitColors.purple600,
    this.purple700 = KitColors.purple700,
    this.purple800 = KitColors.purple800,
    this.purple900 = KitColors.purple900,
    this.purple950 = KitColors.purple950,
    // Gray Colors
    this.gray50 = KitColors.gray50,
    this.gray100 = KitColors.gray100,
    this.gray200 = KitColors.gray200,
    this.gray300 = KitColors.gray300,
    this.gray400 = KitColors.gray400,
    this.gray500 = KitColors.gray500,
    this.gray600 = KitColors.gray600,
    this.gray700 = KitColors.gray700,
    this.gray800 = KitColors.gray800,
    this.gray900 = KitColors.gray900,
    this.gray950 = KitColors.gray950,
    // Neutral Colors
    this.neutral50 = KitColors.neutral50,
    this.neutral100 = KitColors.neutral100,
    this.neutral200 = KitColors.neutral200,
    this.neutral300 = KitColors.neutral300,
    this.neutral400 = KitColors.neutral400,
    this.neutral500 = KitColors.neutral500,
    this.neutral600 = KitColors.neutral600,
    this.neutral700 = KitColors.neutral700,
    this.neutral800 = KitColors.neutral800,
    this.neutral900 = KitColors.neutral900,
    this.neutral950 = KitColors.neutral950,
  });

  @override
  ThemeExtension<KitColorsExtension> copyWith({
    // Red Colors
    Color? red50,
    Color? red100,
    Color? red200,
    Color? red300,
    Color? red400,
    Color? red500,
    Color? red600,
    Color? red700,
    Color? red800,
    Color? red900,
    Color? red950,
    // Yellow Colors
    Color? yellow50,
    Color? yellow100,
    Color? yellow200,
    Color? yellow300,
    Color? yellow400,
    Color? yellow500,
    Color? yellow600,
    Color? yellow700,
    Color? yellow800,
    Color? yellow900,
    Color? yellow950,
    // Green Colors
    Color? green50,
    Color? green100,
    Color? green200,
    Color? green300,
    Color? green400,
    Color? green500,
    Color? green600,
    Color? green700,
    Color? green800,
    Color? green900,
    Color? green950,
    // Orange Colors
    Color? orange50,
    Color? orange100,
    Color? orange200,
    Color? orange300,
    Color? orange400,
    Color? orange500,
    Color? orange600,
    Color? orange700,
    Color? orange800,
    Color? orange900,
    Color? orange950,
    // Cyan Colors
    Color? cyan50,
    Color? cyan100,
    Color? cyan200,
    Color? cyan300,
    Color? cyan400,
    Color? cyan500,
    Color? cyan600,
    Color? cyan700,
    Color? cyan800,
    Color? cyan900,
    Color? cyan950,
    // Purple Colors
    Color? purple50,
    Color? purple100,
    Color? purple200,
    Color? purple300,
    Color? purple400,
    Color? purple500,
    Color? purple600,
    Color? purple700,
    Color? purple800,
    Color? purple900,
    Color? purple950,
    // Gray Colors
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? gray950,
    // Neutral Colors
    Color? neutral50,
    Color? neutral100,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? neutral900,
    Color? neutral950,
  }) {
    return KitColorsExtension(
      // Red Colors
      red50: red50 ?? this.red50,
      red100: red100 ?? this.red100,
      red200: red200 ?? this.red200,
      red300: red300 ?? this.red300,
      red400: red400 ?? this.red400,
      red500: red500 ?? this.red500,
      red600: red600 ?? this.red600,
      red700: red700 ?? this.red700,
      red800: red800 ?? this.red800,
      red900: red900 ?? this.red900,
      red950: red950 ?? this.red950,
      // Yellow Colors
      yellow50: yellow50 ?? this.yellow50,
      yellow100: yellow100 ?? this.yellow100,
      yellow200: yellow200 ?? this.yellow200,
      yellow300: yellow300 ?? this.yellow300,
      yellow400: yellow400 ?? this.yellow400,
      yellow500: yellow500 ?? this.yellow500,
      yellow600: yellow600 ?? this.yellow600,
      yellow700: yellow700 ?? this.yellow700,
      yellow800: yellow800 ?? this.yellow800,
      yellow900: yellow900 ?? this.yellow900,
      yellow950: yellow950 ?? this.yellow950,
      // Green Colors
      green50: green50 ?? this.green50,
      green100: green100 ?? this.green100,
      green200: green200 ?? this.green200,
      green300: green300 ?? this.green300,
      green400: green400 ?? this.green400,
      green500: green500 ?? this.green500,
      green600: green600 ?? this.green600,
      green700: green700 ?? this.green700,
      green800: green800 ?? this.green800,
      green900: green900 ?? this.green900,
      green950: green950 ?? this.green950,
      // Orange Colors
      orange50: orange50 ?? this.orange50,
      orange100: orange100 ?? this.orange100,
      orange200: orange200 ?? this.orange200,
      orange300: orange300 ?? this.orange300,
      orange400: orange400 ?? this.orange400,
      orange500: orange500 ?? this.orange500,
      orange600: orange600 ?? this.orange600,
      orange700: orange700 ?? this.orange700,
      orange800: orange800 ?? this.orange800,
      orange900: orange900 ?? this.orange900,
      orange950: orange950 ?? this.orange950,
      // Cyan Colors
      cyan50: cyan50 ?? this.cyan50,
      cyan100: cyan100 ?? this.cyan100,
      cyan200: cyan200 ?? this.cyan200,
      cyan300: cyan300 ?? this.cyan300,
      cyan400: cyan400 ?? this.cyan400,
      cyan500: cyan500 ?? this.cyan500,
      cyan600: cyan600 ?? this.cyan600,
      cyan700: cyan700 ?? this.cyan700,
      cyan800: cyan800 ?? this.cyan800,
      cyan900: cyan900 ?? this.cyan900,
      cyan950: cyan950 ?? this.cyan950,
      // Purple Colors
      purple50: purple50 ?? this.purple50,
      purple100: purple100 ?? this.purple100,
      purple200: purple200 ?? this.purple200,
      purple300: purple300 ?? this.purple300,
      purple400: purple400 ?? this.purple400,
      purple500: purple500 ?? this.purple500,
      purple600: purple600 ?? this.purple600,
      purple700: purple700 ?? this.purple700,
      purple800: purple800 ?? this.purple800,
      purple900: purple900 ?? this.purple900,
      purple950: purple950 ?? this.purple950,
      // Gray Colors
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      gray950: gray950 ?? this.gray950,
      // Neutral Colors
      neutral50: neutral50 ?? this.neutral50,
      neutral100: neutral100 ?? this.neutral100,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      neutral900: neutral900 ?? this.neutral900,
      neutral950: neutral950 ?? this.neutral950,
    );
  }

  @override
  ThemeExtension<KitColorsExtension> lerp(
    covariant ThemeExtension<KitColorsExtension>? other,
    double t,
  ) {
    if (other is! KitColorsExtension) {
      return this;
    }
    return KitColorsExtension(
      // Red Colors
      red50: Color.lerp(red50, other.red50, t)!,
      red100: Color.lerp(red100, other.red100, t)!,
      red200: Color.lerp(red200, other.red200, t)!,
      red300: Color.lerp(red300, other.red300, t)!,
      red400: Color.lerp(red400, other.red400, t)!,
      red500: Color.lerp(red500, other.red500, t)!,
      red600: Color.lerp(red600, other.red600, t)!,
      red700: Color.lerp(red700, other.red700, t)!,
      red800: Color.lerp(red800, other.red800, t)!,
      red900: Color.lerp(red900, other.red900, t)!,
      red950: Color.lerp(red950, other.red950, t)!,
      // Yellow Colors
      yellow50: Color.lerp(yellow50, other.yellow50, t)!,
      yellow100: Color.lerp(yellow100, other.yellow100, t)!,
      yellow200: Color.lerp(yellow200, other.yellow200, t)!,
      yellow300: Color.lerp(yellow300, other.yellow300, t)!,
      yellow400: Color.lerp(yellow400, other.yellow400, t)!,
      yellow500: Color.lerp(yellow500, other.yellow500, t)!,
      yellow600: Color.lerp(yellow600, other.yellow600, t)!,
      yellow700: Color.lerp(yellow700, other.yellow700, t)!,
      yellow800: Color.lerp(yellow800, other.yellow800, t)!,
      yellow900: Color.lerp(yellow900, other.yellow900, t)!,
      yellow950: Color.lerp(yellow950, other.yellow950, t)!,
      // Green Colors
      green50: Color.lerp(green50, other.green50, t)!,
      green100: Color.lerp(green100, other.green100, t)!,
      green200: Color.lerp(green200, other.green200, t)!,
      green300: Color.lerp(green300, other.green300, t)!,
      green400: Color.lerp(green400, other.green400, t)!,
      green500: Color.lerp(green500, other.green500, t)!,
      green600: Color.lerp(green600, other.green600, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      green800: Color.lerp(green800, other.green800, t)!,
      green900: Color.lerp(green900, other.green900, t)!,
      green950: Color.lerp(green950, other.green950, t)!,
      // Orange Colors
      orange50: Color.lerp(orange50, other.orange50, t)!,
      orange100: Color.lerp(orange100, other.orange100, t)!,
      orange200: Color.lerp(orange200, other.orange200, t)!,
      orange300: Color.lerp(orange300, other.orange300, t)!,
      orange400: Color.lerp(orange400, other.orange400, t)!,
      orange500: Color.lerp(orange500, other.orange500, t)!,
      orange600: Color.lerp(orange600, other.orange600, t)!,
      orange700: Color.lerp(orange700, other.orange700, t)!,
      orange800: Color.lerp(orange800, other.orange800, t)!,
      orange900: Color.lerp(orange900, other.orange900, t)!,
      orange950: Color.lerp(orange950, other.orange950, t)!,
      // Cyan Colors
      cyan50: Color.lerp(cyan50, other.cyan50, t)!,
      cyan100: Color.lerp(cyan100, other.cyan100, t)!,
      cyan200: Color.lerp(cyan200, other.cyan200, t)!,
      cyan300: Color.lerp(cyan300, other.cyan300, t)!,
      cyan400: Color.lerp(cyan400, other.cyan400, t)!,
      cyan500: Color.lerp(cyan500, other.cyan500, t)!,
      cyan600: Color.lerp(cyan600, other.cyan600, t)!,
      cyan700: Color.lerp(cyan700, other.cyan700, t)!,
      cyan800: Color.lerp(cyan800, other.cyan800, t)!,
      cyan900: Color.lerp(cyan900, other.cyan900, t)!,
      cyan950: Color.lerp(cyan950, other.cyan950, t)!,
      // Purple Colors
      purple50: Color.lerp(purple50, other.purple50, t)!,
      purple100: Color.lerp(purple100, other.purple100, t)!,
      purple200: Color.lerp(purple200, other.purple200, t)!,
      purple300: Color.lerp(purple300, other.purple300, t)!,
      purple400: Color.lerp(purple400, other.purple400, t)!,
      purple500: Color.lerp(purple500, other.purple500, t)!,
      purple600: Color.lerp(purple600, other.purple600, t)!,
      purple700: Color.lerp(purple700, other.purple700, t)!,
      purple800: Color.lerp(purple800, other.purple800, t)!,
      purple900: Color.lerp(purple900, other.purple900, t)!,
      purple950: Color.lerp(purple950, other.purple950, t)!,
      // Gray Colors
      gray50: Color.lerp(gray50, other.gray50, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
      gray950: Color.lerp(gray950, other.gray950, t)!,
      // Neutral Colors
      neutral50: Color.lerp(neutral50, other.neutral50, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
      neutral950: Color.lerp(neutral950, other.neutral950, t)!,
    );
  }
}

class KitColors {
  const KitColors._(); // Private constructor to prevent instantiation

  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red200 = Color(0xFFFECACA);
  static const red300 = Color(0xFFFCA5A5);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red800 = Color(0xFF991B1B);
  static const red900 = Color(0xFF7F1D1D);
  static const red950 = Color(0xFF450A0A);

  static const yellow50 = Color(0xFFFEFCE8);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow200 = Color(0xFFFEF08A);
  static const yellow300 = Color(0xFFFDE047);
  static const yellow400 = Color(0xFFFACC15);
  static const yellow500 = Color(0xFFEAB308);
  static const yellow600 = Color(0xFFCA8A04);
  static const yellow700 = Color(0xFFA16207);
  static const yellow800 = Color(0xFF854D0E);
  static const yellow900 = Color(0xFF713F12);
  static const yellow950 = Color(0xFF422006);

  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green200 = Color(0xFFBBF7D0);
  static const green300 = Color(0xFF86EFAC);
  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const green800 = Color(0xFF166534);
  static const green900 = Color(0xFF14532D);
  static const green950 = Color(0xFF052E16);

  static const orange50 = Color(0xFFFFF7ED);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange200 = Color(0xFFFED7AA);
  static const orange300 = Color(0xFFFDBA74);
  static const orange400 = Color(0xFFFB923C);
  static const orange500 = Color(0xFFFF6B35);
  static const orange600 = Color(0xFFEA580C);
  static const orange700 = Color(0xFFC2410C);
  static const orange800 = Color(0xFF9A3412);
  static const orange900 = Color(0xFF7C2D12);
  static const orange950 = Color(0xFF431407);

  static const cyan50 = Color(0xFFECFEFF);
  static const cyan100 = Color(0xFFCFFAFE);
  static const cyan200 = Color(0xFFA5F3FC);
  static const cyan300 = Color(0xFF67E8F9);
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan500 = Color(0xFF00BCD4);
  static const cyan600 = Color(0xFF0891B2);
  static const cyan700 = Color(0xFF0E7490);
  static const cyan800 = Color(0xFF155E75);
  static const cyan900 = Color(0xFF164E63);
  static const cyan950 = Color(0xFF083344);

  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple200 = Color(0xFFE9D5FF);
  static const purple300 = Color(0xFFD8B4FE);
  static const purple400 = Color(0xFFC084FC);
  static const purple500 = Color(0xFF9C27B0);
  static const purple600 = Color(0xFF9333EA);
  static const purple700 = Color(0xFF7E22CE);
  static const purple800 = Color(0xFF6B21A8);
  static const purple900 = Color(0xFF581C87);
  static const purple950 = Color(0xFF3B0764);

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF9E9E9E);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  static const gray950 = Color(0xFF030712);

  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  static const neutral950 = Color(0xFF0A0A0A);
}
