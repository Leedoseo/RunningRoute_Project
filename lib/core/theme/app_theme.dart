import 'package:flutter/material.dart';

const _seed = Color(0xFF3E7BFA);

/// 라이트 테마
ThemeData buildLightTheme() =>
    _buildTheme(ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light), isDark: false);

/// 다크 테마
ThemeData buildDarkTheme() =>
    _buildTheme(ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark), isDark: true);

/// 공통 빌더 (라이트/다크 차이는 ColorScheme와 타이포 베이스만 다름)
ThemeData _buildTheme(ColorScheme cs, {required bool isDark}) {
  final baseTypography = isDark ? Typography.material2021().white : Typography.material2021().black;

  final textTheme = baseTypography.apply(
    bodyColor: cs.onSurface,
    displayColor: cs.onSurface,
  ).copyWith(
    // 버튼/칩 가독성 살짝 강화
    labelLarge: const TextStyle(fontWeight: FontWeight.w700),
  );

  final appBarTitle = (isDark ? Typography.whiteMountainView : Typography.blackMountainView)
      .titleLarge
      ?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: textTheme,

    // AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: appBarTitle,
      iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.6),
      ),
      prefixIconColor: cs.onSurfaceVariant,
      suffixIconColor: cs.onSurfaceVariant,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: cs.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(44),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(44),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        minimumSize: const Size.fromHeight(44),
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: cs.outlineVariant),
      backgroundColor: cs.surfaceContainerHigh,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1, thickness: 1),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.surfaceContainerHigh,
      contentTextStyle: TextStyle(color: cs.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Modal / Dialog (통일)
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: cs.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Nav transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // 배경 계열(다크 이슈 방지 + 라이트도 톤 고정)
    scaffoldBackgroundColor: cs.surface,
    canvasColor: cs.surface,
    dialogBackgroundColor: cs.surface,

    // 잉크 이펙트(라운드에 맞춰 잘림)
    splashFactory: InkSparkle.splashFactory,
  );
}
