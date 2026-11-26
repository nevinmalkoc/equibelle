import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride.dart';
import '../models/coordinate_point.dart';
import '../theme/app_theme.dart';

enum ShareCardTheme {
  cream,           // Krem
  dark,            // Gece
  bordeaux,        // Asil Bordo (Merlot)
  saddleBrand,     // Logo Taba Rengi
  mapOverlay,      // Arkada Gerçek Harita
  photoBackground, // Kendi Fotoğrafını Yüklediğin Kart!
  transparent      // Şeffaf (Video Katmanı)
}

class ShareCardWidget extends StatelessWidget {
  final Ride ride;
  final ShareCardTheme theme;
  final String? customNote;
  final File? customPhotoFile;

  const ShareCardWidget({
    super.key,
    required this.ride,
    required this.theme,
    this.customNote,
    this.customPhotoFile,
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
    bool showMap = false;
    bool showPhoto = false;

    switch (theme) {
      case ShareCardTheme.cream:
        bgColor = AppTheme.creamBg;
        textColor = AppTheme.richSaddle;
        secondaryTextColor = const Color(0xFF6E5336);
        break;
      case ShareCardTheme.dark:
        bgColor = AppTheme.darkCharcoal;
        textColor = AppTheme.creamBg;
        secondaryTextColor = AppTheme.accentGold;
        break;
      case ShareCardTheme.bordeaux:
        bgColor = const Color(0xFF4A121A);
        textColor = AppTheme.creamBg;
        secondaryTextColor = const Color(0xFFE2C4A6);
        break;
      case ShareCardTheme.saddleBrand:
        bgColor = AppTheme.richSaddle;
        textColor = AppTheme.creamBg;
        secondaryTextColor = AppTheme.warmCream;
        break;
      case ShareCardTheme.mapOverlay:
        bgColor = Colors.black;
        textColor = Colors.white;
        secondaryTextColor = AppTheme.warmCream;
        showMap = true;
        break;
      case ShareCardTheme.photoBackground:
        bgColor = Colors.black;
        textColor = Colors.white;
        secondaryTextColor = const Color(0xFFE5E2DA);
        showPhoto = true;
        break;
      case ShareCardTheme.transparent:
        bgColor = Colors.transparent;
        textColor = Colors.white;
        secondaryTextColor = const Color(0xFFE5E2DA);
        break;
    }

    final latLngPoints = ride.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final centerPoint = latLngPoints.isNotEmpty
        ? latLngPoints[latLngPoints.length ~/ 2]
        : const LatLng(41.1167, 29.2000);

    return AspectRatio(
      aspectRatio: 9 / 16, // TikTok / Instagram Hikaye Oranı
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: theme != ShareCardTheme.transparent
              ? Border.all(color: AppTheme.softGrey.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: theme != ShareCardTheme.transparent
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // 1. KULLANICININ SEÇTİĞİ ARKA PLAN FOTOĞRAFI
            if (showPhoto && customPhotoFile != null)
              Positioned.fill(
                child: Image.file(
                  customPhotoFile!,
                  fit: BoxFit.cover,
                ),
              ),

            // Fotoğraf varsa üzerine şık karanlık katman (yazılar ve rota parlasın diye)
            if (showPhoto)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.40),
                ),
              ),

            // 2. HARİTA MODU SEÇİLDİYSE
            if (showMap && latLngPoints.isNotEmpty)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 14.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.equibelle.equibelle',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: latLngPoints,
                            strokeWidth: 6.0,
                            color: AppTheme.speedGallop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 3. KARTIN YAZILARI VE ROTA ÇİZİMİ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'E Q U I B E L L E',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.5,
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

                  // Özel Not
                  if (customNote != null && customNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '“${customNote!.trim()}”',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ROTA ÇİZİMİ (Fotoğraflı veya Düz modlarda)
                  if (!showMap)
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
                    )
                  else
                    const Spacer(flex: 5),

                  const Spacer(),

                  // ALT METRİKLER
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: secondaryTextColor.withValues(alpha: 0.35),
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
                            color: secondaryTextColor.withValues(alpha: 0.85),
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

// 🎨 Matematiksel Rota Çizici
class RoutePainter extends CustomPainter {
  final List<CoordinatePoint> points;
  final ShareCardTheme cardTheme;

  RoutePainter({required this.points, required this.cardTheme});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

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

    const double padding = 20.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    Offset toOffset(CoordinatePoint p) {
      final x = padding + ((p.longitude - minLng) / lngRange) * drawWidth;
      final y = padding + (1.0 - ((p.latitude - minLat) / latRange)) * drawHeight;
      return Offset(x, y);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final offset1 = toOffset(p1);
      final offset2 = toOffset(p2);

      Color segmentColor;
      if (cardTheme == ShareCardTheme.photoBackground) {
        // Fotoğraf arkasındayken altın/beyaz neon gibi parlasın
        segmentColor = p2.speed > 12.0 ? const Color(0xFFFF4D4D) : const Color(0xFFF9F7F2);
      } else {
        if (p2.speed < 4.0) {
          segmentColor = AppTheme.speedWalk;
        } else if (p2.speed < 12.0) {
          segmentColor = AppTheme.speedTrot;
        } else {
          segmentColor = AppTheme.speedGallop;
        }
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
