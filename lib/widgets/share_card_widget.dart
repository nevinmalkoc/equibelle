import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/coordinate_point.dart';
import '../theme/app_theme.dart';

enum ShareCardTheme { cream, dark, transparent }

class ShareCardWidget extends StatelessWidget {
  final Ride ride;
  final ShareCardTheme theme;

  const ShareCardWidget({
    super.key,
    required this.ride,
    required this.theme,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}s ${minutes}d';
    return '${minutes}d';
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color secondaryTextColor;

    switch (theme) {
      case ShareCardTheme.cream:
        bgColor = AppTheme.creamBg;
        textColor = AppTheme.forestGreen;
        secondaryTextColor = AppTheme.saddleBrown;
        break;
      case ShareCardTheme.dark:
        bgColor = AppTheme.darkCharcoal;
        textColor = AppTheme.creamBg;
        secondaryTextColor = AppTheme.accentGold;
        break;
      case ShareCardTheme.transparent:
        bgColor = Colors.transparent;
        textColor = Colors.white;
        secondaryTextColor = const Color(0xFFE5E2DA);
        break;
    }

    return AspectRatio(
      aspectRatio: 9 / 16, // TikTok / Instagram Hikaye Oranı
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: theme != ShareCardTheme.transparent
              ? Border.all(color: AppTheme.softGrey.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: theme != ShareCardTheme.transparent
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. EQUİBELLE BAŞLIĞI / İMZASI
            Text(
              'E Q U I B E L L E',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'POLONEZKÖY FOREST TRAIL',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),

            const Spacer(),

            // 2. ORTA ALAN: HIZA GÖRE RENKLENEN VEKTÖR ROTA ÇİZİMİ
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ride.routePoints.isNotEmpty
                    ? CustomPaint(
                        size: Size.infinite,
                        painter: RoutePainter(
                          points: ride.routePoints,
                          cardTheme: theme,
                        ),
                      )
                    : Center(
                        child: Text(
                          'Rota çizilemedi',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // 3. ALT BİLGİ ALANI: MESAFE, SÜRE, HIZ, TARİH
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: secondaryTextColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBottomMetric('MESAFE', '${ride.totalDistanceKm} km', textColor, secondaryTextColor),
                      _buildBottomMetric('SÜRE', _formatDuration(ride.totalDurationSeconds), textColor, secondaryTextColor),
                      _buildBottomMetric('ORT. HIZ', '${ride.avgSpeedKmh} km/s', textColor, secondaryTextColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDate(ride.startTime),
                    style: TextStyle(
                      color: secondaryTextColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMetric(String label, String value, Color mainColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: mainColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// 🎨 Matematiksel Rota Çizici (CustomPainter)
class RoutePainter extends CustomPainter {
  final List<CoordinatePoint> points;
  final ShareCardTheme cardTheme;

  RoutePainter({required this.points, required this.cardTheme});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Koordinat sınırlarını buluyoruz (Min/Max Enlem-Boylam)
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    double latRange = (maxLat - minLat).abs();
    double lngRange = (maxLng - minLng).abs();

    if (latRange == 0) latRange = 0.0001;
    if (lngRange == 0) lngRange = 0.0001;

    // Çizimin kenarlara yapışmaması için boşluk payı (padding)
    const double padding = 20.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    // Koordinatı ekrandaki piksel koordinatına (Offset x,y) çeviren fonksiyon
    Offset toOffset(CoordinatePoint p) {
      final x = padding + ((p.longitude - minLng) / lngRange) * drawWidth;
      // Haritada enlem yukardan aşağı ters orantılıdır (Y ekseni ters)
      final y = padding + (1.0 - ((p.latitude - minLat) / latRange)) * drawHeight;
      return Offset(x, y);
    }

    // Her iki nokta arasındaki çizgiyi hızına göre renklendirerek çiz
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final offset1 = toOffset(p1);
      final offset2 = toOffset(p2);

      // Hıza göre asil renk seçimi
      Color segmentColor;
      if (p2.speed < 4.0) {
        // Yürüyüş / Mola: Sakin Zümrüt Yeşili
        segmentColor = AppTheme.speedWalk;
      } else if (p2.speed < 12.0) {
        // Tırıs: Klas Deri Taba Kahvesi
        segmentColor = AppTheme.speedTrot;
      } else {
        // Dörtnala: Asil Fransız Bordosu (Ateş Merlot!)
        segmentColor = AppTheme.speedGallop;
      }

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(offset1, offset2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) => true;
}
