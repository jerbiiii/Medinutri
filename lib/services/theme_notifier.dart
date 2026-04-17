import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  // ── Premium Teal palette ──
  static const Color _tealPrimary = Color(0xFF0D9488);
  static const Color _blueSky = Color(0xFF3B82F6);
  static const Color _lightBg = Color(0xFFF8FAFC);

  Color _seedColor = _tealPrimary;
  Brightness _brightness = Brightness.light;

  Color get seedColor => _seedColor;
  Brightness get brightness => _brightness;

  /// Convenience gradient used across app
  static const List<Color> primaryGradient = [_tealPrimary, _blueSky];

  void toggleTheme() {
    _brightness = (_brightness == Brightness.light) ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  void updateTheme({Color? newColor}) {
    if (newColor != null) _seedColor = newColor;
    notifyListeners();
  }

  ThemeData get themeData {
    final isDark = _brightness == Brightness.dark;
    final textTheme = isDark
        ? const TextTheme(
            headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            bodyLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          )
        : null;

    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: _brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF000000) : _lightBg,
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: isDark ? const Color(0xFF121212) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none,
        ),
        shadowColor: isDark ? Colors.transparent : _tealPrimary.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF161616) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _tealPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _tealPrimary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _tealPrimary.withValues(alpha: 0.4);
          return null;
        }),
      ),
    );
  }

  void resetTheme() {
    _seedColor = _tealPrimary;
    _brightness = Brightness.light;
    notifyListeners();
  }
}
