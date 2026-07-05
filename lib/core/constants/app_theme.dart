import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // ─── Fixed Application Palette ──────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFFfeb245);

  static const Color darkGrayColor = Color(0xFF888787);
  static const Color darkerGrayColor = Color(0xFF5B5A5A);
  static const Color blackColor = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color redColor = Color(0xFFE4134A);
  static const Color greybtn = Color(0xFFE6E5E5);
  static const Color darkBlue = Color(0xFF1E3A8A);
  // tealColor is now a dynamic getter — see below (forwards to company theme_color)
  static const Color _defaultTealColor = Color(0xFFFFB347);
  static const Color skyBlue = Color(0xFF0DCAF0);
  static const Color lightBlue = Color(0xFF0563F0);
  static const Color orangeColor = secondaryColor;
  static const Color yellow = secondaryColor;
  static const Color darkOrange = Color(0xFFF57C00);
  static const Color lightGrayBg = Color(0xFFF5F5F5);
  static const Color shadowBlack = Color(0x1F000000);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color lightGreen = Color(0xFFD4EED8);
  static const Color stepperBG = Color(0xFFF5FBFE);
  static const Color lightSecondaryColor = Color(0xFFFFD180);
  static Color redColorOpacity10 = redColor.withValues(alpha: 0.1);

  static const double inputRadius = 5.0;
  static const double authButtonRadius = 5.0;
  static const double productButtonRadius = 20.0;
  static const double arrowSize = 25.0;

  /// Returns a responsive back-button icon size.
  /// On tablets (width >= 600) returns 32, otherwise 24.
  static double backIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 ? 40 : 24;
  }

  /// Returns true if the device is a tablet (shortestSide >= 600).
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  // ─── Dynamic Company Colors (mutable, loaded from SharedPreferences) ─────────
  // Defaults mirror the original hardcoded values so the app looks identical
  // until a company is selected.
  static Color dynamicTextColor = const Color(0xFF333333);   // text_color
  static Color dynamicHintColor = const Color(0xFFBDBDBD);   // hint_color
  static Color dynamicThemeColor = primaryColor;              // theme_color  → buttons
  static Color dynamicAppbarColor = primaryColor;             // appbar_color → AppBar
  static Color dynamicBorderColor = const Color(0xFFBDBDBD); // border_color → borders
  static Color dynamicPrimaryButtonColor = _defaultTealColor;
  static Color dynamicSecondaryButtonColor = greybtn;

  // Convenience aliases used throughout widgets ─────────────────────────────────
  // These forward to the dynamic variants so any widget using these names
  // automatically picks up the company-configured color.
  static Color get textColor => dynamicTextColor;
  static Color get hintColor => dynamicHintColor;
  static Color get borderColor => dynamicBorderColor;

  /// Maps to company `theme_color`.
  /// All existing `AppTheme.tealColor` usages (buttons, Add to Cart, etc.)
  /// now automatically use the company's theme color.
  /// Falls back to amber/orange if no company color is set.
  static Color get tealColor => dynamicThemeColor != primaryColor
      ? dynamicThemeColor
      : _defaultTealColor;

  /// Maps to company `appbar_color`.
  static Color get appbarColor => dynamicAppbarColor;

  /// New primary button color from API
  static Color get primaryButtonColor => dynamicPrimaryButtonColor;

  /// New secondary button color from API
  static Color get secondaryButtonColor => dynamicSecondaryButtonColor;

  // ─── Theme Notifier ──────────────────────────────────────────────────────────
  // Increment this to trigger a MaterialApp rebuild after colors change.
  static final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);

  // ─── Helper ──────────────────────────────────────────────────────────────────
  /// Parses a hex color string (with or without '#') and returns a [Color].
  /// Returns [fallback] when the string is null, empty, or invalid.
  static Color hexToColor(String? hex, {Color fallback = primaryColor}) {
    if (hex == null || hex.isEmpty) return fallback;
    final buffer = StringBuffer();
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) buffer.write('FF');
    if (cleaned.length == 8 || cleaned.length == 6) {
      buffer.write(cleaned);
      return Color(int.tryParse(buffer.toString(), radix: 16) ?? fallback.toARGB32());
    }
    return fallback;
  }

  // ─── Material Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: dynamicThemeColor,
        secondary: dynamicThemeColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dynamicAppbarColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dynamicThemeColor,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: dynamicHintColor, fontSize: 14.sp),
        labelStyle: TextStyle(color: dynamicTextColor, fontSize: 14.sp),
        floatingLabelStyle: TextStyle(color: dynamicThemeColor, fontSize: 14.sp),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: dynamicBorderColor),
          borderRadius: BorderRadius.circular(inputRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: dynamicAppbarColor, width: 1.5),
          borderRadius: BorderRadius.circular(inputRadius),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: dynamicBorderColor),
          borderRadius: BorderRadius.circular(inputRadius),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        bodyLarge: TextStyle(
            fontSize: 16, color: dynamicTextColor, fontFamily: 'OpenSans'),
        bodyMedium: TextStyle(
            fontSize: 14, color: dynamicTextColor, fontFamily: 'OpenSans'),
        bodySmall: TextStyle(
            fontSize: 12, color: dynamicTextColor, fontFamily: 'OpenSans'),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
        labelSmall: TextStyle(
            fontSize: 10,
            letterSpacing: 0.5,
            color: dynamicTextColor,
            fontFamily: 'OpenSans'),
      ).apply(fontFamily: 'OpenSans'),
    );
  }
}
