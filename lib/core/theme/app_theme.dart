import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ThemeData cho toàn app — "Field Research Journal".
///
/// - Display: Fraunces (heading). Body: Inter.
/// - Bản nâng cấp lần 2: gộp light/dark vào 1 hàm dựng chung (hết lặp),
///   đồng bộ colorScheme với bảng màu thương hiệu (secondary = rêu,
///   surface = surface của app), nút disabled không còn xám đục, thêm
///   FilledButton/ListTile/Switch theme.
/// - KHÔNG đổi cấu trúc TextTheme, vẫn giữ `lightTheme`/`darkTheme`.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base =
        isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final muted = AppColors.textSecondaryOf(brightness);

    final display = GoogleFonts.frauncesTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      headlineLarge: display.headlineLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: display.titleLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: base, height: 1.5),
      bodyMedium: body.bodyMedium?.copyWith(color: base, height: 1.45),
      bodySmall: body.bodySmall?.copyWith(color: muted),
      labelLarge: body.labelLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: body.labelSmall?.copyWith(color: muted),
    );
  }

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final bg = isLight ? AppColors.backgroundLight : AppColors.backgroundDark;
    final surface = AppColors.surfaceOf(brightness);
    final muted = AppColors.surfaceMutedOf(brightness);
    final border = AppColors.borderOf(brightness);
    final textPrimary =
        isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final textSecondary = AppColors.textSecondaryOf(brightness);
    final accentText = AppColors.primaryTextOf(brightness);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: surface,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final buttonText = GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      textTheme: _textTheme(brightness),
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.42),
          disabledForegroundColor: Colors.white.withOpacity(0.85),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          foregroundColor: accentText,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        border: inputBorder(Colors.transparent, 0),
        enabledBorder: inputBorder(Colors.transparent, 0),
        focusedBorder: inputBorder(AppColors.primary, 1.6),
        errorBorder: inputBorder(AppColors.error, 1.4),
        focusedErrorBorder: inputBorder(AppColors.error, 1.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14.5),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        floatingLabelStyle: GoogleFonts.inter(
          color: accentText,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : muted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : border;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withOpacity(isLight ? 0.14 : 0.22),
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accentText : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accentText : textSecondary,
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isLight ? const Color(0xFF2B2A28) : const Color(0xFF3A3835),
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
