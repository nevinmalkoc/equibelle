import 'package:flutter/material.dart';

class AppTheme {
  // Equibelle Özel Lüks Palet (Senin Seçtiğin Asil Taba & Krem Kimliği)
  static const Color richSaddle = Color(0xFF493011);    // Zengin Süet / Sıcak Eyer Taba (Logonun Arka Planı)
  static const Color creamBg = Color(0xFFF9F7F2);       // İpeksi Fildişi / Krem
  static const Color warmCream = Color(0xFFEADBCE);     // Logodaki Zarif At Çizgisi Rengi
  static const Color darkCharcoal = Color(0xFF1F1A14);  // Mat Asil Koyu Grafit
  static const Color softGrey = Color(0xFFE6E0D6);      // İnce Sınır Çizgisi
  static const Color accentGold = Color(0xFFC7A258);    // İnce Mat Altın Vurgu

  // Hıza Göre Rota Çizgi Renkleri
  static const Color speedWalk = Color(0xFF385E48);     // Yürüyüş: Sakin Orman Yeşili
  static const Color speedTrot = Color(0xFF7A4E24);     // Tırıs: Klas Deri Taba
  static const Color speedGallop = Color(0xFF8B2635);   // Dörtnala: Asil Bordo / Merlot

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: creamBg,
      primaryColor: richSaddle,
      colorScheme: const ColorScheme.light(
        primary: richSaddle,
        secondary: warmCream,
        surface: creamBg,
      ),
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: richSaddle),
        titleTextStyle: TextStyle(
          color: richSaddle,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}
