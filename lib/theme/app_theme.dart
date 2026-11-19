import 'package:flutter/material.dart';

class AppTheme {
  // Equibelle Özel Renk Paleti (Equestrian Lifestyle)
  static const Color creamBg = Color(0xFFF8F6F2);       // Kırık Beyaz / Krem
  static const Color forestGreen = Color(0xFF1E352F);   // Koyu Orman Yeşili
  static const Color saddleBrown = Color(0xFF8C6239);   // Eyer / Taba Kahvesi
  static const Color darkCharcoal = Color(0xFF1A1A1A);  // Mat Koyu Siyah
  static const Color softGrey = Color(0xFFE8E5DF);      // Yumuşak Gri Çizgiler
  static const Color accentGold = Color(0xFFC29B38);     // İnce Altın Detay

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: creamBg,
      primaryColor: forestGreen,
      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        secondary: saddleBrown,
        surface: creamBg,
      ),
      fontFamily: 'serif', // Zarif, edebi bir tipografi hissi için
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: forestGreen),
        titleTextStyle: TextStyle(
          color: forestGreen,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
