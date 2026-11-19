import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'ride_summary_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final TrackingService _tracker = TrackingService();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // TrackingService her yeni konum veya saniye ürettiğinde ekranı yenile
    _tracker.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  // Süreyi HH:MM:SS formatına dönüştüren yardımcı fonksiyon
  String _formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = _tracker.state == TrackingState.paused;
    final isStopped = _tracker.state == TrackingState.stopped;

    // Rota koordinatlarını latlong listesine çevir
    final routePoints = _tracker.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Harita merkezini son noktaya veya Polonezköy koordinatına ayarla
    final centerPos = routePoints.isNotEmpty
        ? routePoints.last
        : const LatLng(41.1167, 29.2000); // Polonezköy merkez

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: const Text('E Q U I B E L L E'),
      ),
      body: Stack(
        children: [
          // 1. HARİTA ALANI (İnternetsiz ortamda bile çizgi çalışır)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPos,
              initialZoom: 15.0,
            ),
            children: [
              // Açık kaynak OpenStreetMap karoları
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.equibelle.equibelle',
              ),
              // Canlı Rota Çizgimiz
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.0,
                    color: AppTheme.forestGreen,
                  ),
                ],
              ),
              // Atın Bulunduğu Son Konum İşaretçisi
              if (routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.last,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.saddleBrown,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. ÜST BİLGİ KARTI (Minimalist Gösterge Paneli)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.creamBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.softGrey),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mesafe
                    _buildStatItem(
                      'MESAFE',
                      (_tracker.totalDistanceMeters / 1000).toStringAsFixed(2),
                      'km',
                    ),
                    _buildDivider(),
                    // Süre
                    _buildStatItem(
                      'SÜRE',
                      _formatDuration(_tracker.totalDurationSeconds),
                      '',
                    ),
                    _buildDivider(),
                    // Hız
                    _buildStatItem(
                      'HIZ',
                      _tracker.currentSpeedKmh.toStringAsFixed(1),
                      'km/s',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. ALT KONTROL BUTONLARI (At üstünde tek elle basılacak büyüklükte)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: isStopped
                  ? // SÜRÜŞÜ BAŞLAT BUTONU
                  SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          foregroundColor: AppTheme.creamBg,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        onPressed: () async {
                          final success = await _tracker.startRide();
                          if (!success) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lütfen Ayarlar\'dan Konum İznini Açın'),
                              ),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 30),
                            SizedBox(width: 8),
                            Text(
                              'SÜRÜŞÜ BAŞLAT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : // SÜRÜŞ ESNASINDAKI KONTROLLER (DURAKLAT / BİTİR)
                  Row(
                      children: [
                        // Duraklat / Devam Et Butonu
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.saddleBrown,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () => _tracker.togglePause(),
                              child: Icon(
                                isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sürüşü Bitir Butonu
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B263E), // Zarif Bordo / Kırmızı
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                final completedRide = await _tracker.stopRide();
                                if (completedRide != null) {
                                  if (!context.mounted) return;
                                  // Sürüş bittiğinde Özet / Paylaşım ekranına yönlendir
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RideSummaryScreen(ride: completedRide),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'SÜRÜŞÜ BİTİR',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.forestGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: AppTheme.softGrey,
    );
  }
}
