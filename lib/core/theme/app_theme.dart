import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
      surface: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      fontFamilyFallback: const [
        // 기기별 기본 한글 폰트 대응
        'Apple SD Gothic Neo', // iOS/macOS
        'Malgun Gothic', // Windows
        'Noto Sans KR', // Android/Web
        // 기기별 기본 이모지 폰트 대응
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
      ],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      fontFamilyFallback: const [
        // 기기별 기본 한글 폰트 대응
        'Apple SD Gothic Neo', // iOS/macOS
        'Malgun Gothic', // Windows
        'Noto Sans KR', // Android/Web
        // 기기별 기본 이모지 폰트 대응
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
      ],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
