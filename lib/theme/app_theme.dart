import 'package:flutter/material.dart';

class AppTheme {
  // Equibelle Lüks Binicilik Paleti (Quiet Luxury Equestrian)
  static const Color creamBg = Color(0xFFF9F8F5);       // İpeksi Fildişi / Krem
  static const Color forestGreen = Color(0xFF14241F);   // Asil İngiliz Yarış Yeşili (Çok Koyu Zümrüt)
  static const Color saddleBrown = Color(0xFF6B4226);   // Sıcak Kestane / Deri Kahvesi (Cognac)
  static const Color darkCharcoal = Color(0xFF121514);  // Mat Asil Koyu Grafit
  static const Color softGrey = Color(0xFFE5E2DA);      // İnce Zarif Sınır Çizgisi
  static const Color accentGold = Color(0xFFC5A059);    // Antik Mat Altın

  // Hıza Göre Rota Renkleri (Çiğ renkler yerine asil tonlar)
  static const Color speedWalk = Color(0xFF2D5A43);     // Yürüyüş: Sakin Orman Yeşili
  static const Color speedTrot = Color(0xFF8B5A2B);     // Tırıs: Klasik Deri Taba
  static const Color speedGallop = Color(0xFF721824);   // Dörtnala: Asil Fransız Bordo / Merlot

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: creamBg,
      primaryColor: forestGreen,
      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        secondary: saddleBrown,
        surface: creamBg,
      ),
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: forestGreen),
        titleTextStyle: TextStyle(
          color: forestGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}
