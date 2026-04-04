import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  Color _seedColor = Colors.blueAccent;
  Brightness _brightness = Brightness.light;

  Color get seedColor => _seedColor;
  Brightness get brightness => _brightness;

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
      scaffoldBackgroundColor: isDark ? const Color(0xFF000000) : Colors.grey[50], // Deep Black
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: isDark ? const Color(0xFF121212) : Colors.white, // Dark grey for cards
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void resetTheme() {
    _seedColor = Colors.blueAccent;
    _brightness = Brightness.light;
    notifyListeners();
  }
}
