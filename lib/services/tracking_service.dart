import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/coordinate_point.dart';
import '../models/ride.dart';
import 'database_service.dart';

enum TrackingState { stopped, recording, paused }

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final DatabaseService _dbService = DatabaseService();

  TrackingState state = TrackingState.stopped;
  int? currentRideId;
  DateTime? startTime;

  List<CoordinatePoint> points = [];
  double totalDistanceMeters = 0.0;
  int totalDurationSeconds = 0;
  int movingDurationSeconds = 0;
  double currentSpeedKmh = 0.0;
  double maxSpeedKmh = 0.0;

  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  // UI (Ekran) dinlesin diye callback fonksiyonlar
  Function()? onUpdate;

  // 1. Sürüşü Başlat
  Future<bool> startRide() async {
    // Konum izni kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    // Değerleri sıfırla
    points.clear();
    totalDistanceMeters = 0.0;
    totalDurationSeconds = 0;
    movingDurationSeconds = 0;
    currentSpeedKmh = 0.0;
    maxSpeedKmh = 0.0;
    startTime = DateTime.now();

    // Veritabanında yeni bir sürüş kaydı aç
    final initialRide = Ride(
      startTime: startTime!,
      totalDistanceKm: 0.0,
      totalDurationSeconds: 0,
      movingDurationSeconds: 0,
      avgSpeedKmh: 0.0,
      maxSpeedKmh: 0.0,
    );
    currentRideId = await _dbService.insertRide(initialRide);

    state = TrackingState.recording;

    // Saniye sayacı (Her saniye toplam ve hareket süresini günceller)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == TrackingState.recording) {
        totalDurationSeconds++;
        if (currentSpeedKmh > 2.5) {
          movingDurationSeconds++; // 2.5 km/s üzerindeyse at hareket ediyor
        }
        onUpdate?.call();
      }
    });

    // iOS Arka Plan GPS Ayarları
    const locationSettings = AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // En az 2 metre hareket edince sinyal ver
      pauseLocationUpdatesAutomatically: false, // Arka planda asla uyutma!
      showBackgroundLocationIndicator: true, // Üstte mavi konum hapı görünsün
    );

    // Canlı GPS Dinleme Akışı (Stream)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onNewPosition);

    return true;
  }

  // Yeni bir GPS konumu geldiğinde çalışan fonksiyon
  void _onNewPosition(Position position) async {
    if (state != TrackingState.recording || currentRideId == null) return;

    // m/s -> km/h çevirisi (1 m/s = 3.6 km/h)
    double speedKmh = position.speed > 0 ? (position.speed * 3.6) : 0.0;
    currentSpeedKmh = speedKmh;

    if (speedKmh > maxSpeedKmh) {
      maxSpeedKmh = speedKmh;
    }

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      
      // Mesafe hesabı (Haversine formülü ile iki koordinat arası metre)
      const distanceCalc = Distance();
      final double distanceMeters = distanceCalc.as(
        LengthUnit.Meter,
        LatLng(lastPoint.latitude, lastPoint.longitude),
        LatLng(position.latitude, position.longitude),
      );

      // GPS DRIFT FİLTRESİ: 3 metreden az oynamaları durma kabul et, rotaya ve mesafeye ekleme!
      if (distanceMeters < 3.0) {
        return;
      }

      totalDistanceMeters += distanceMeters;
    }

    final newPoint = CoordinatePoint(
      rideId: currentRideId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: speedKmh,
      timestamp: DateTime.now(),
    );

    points.add(newPoint);

    // Noktayı internetsiz olarak SQLite'a yaz (Telefon kapansa bile kaybolmaz!)
    await _dbService.insertCoordinatePoint(newPoint);

    onUpdate?.call();
  }

  // 2. Sürüşü Duraklat / Devam Et
  void togglePause() {
    if (state == TrackingState.recording) {
      state = TrackingState.paused;
      currentSpeedKmh = 0.0;
    } else if (state == TrackingState.paused) {
      state = TrackingState.recording;
    }
    onUpdate?.call();
  }

  // 3. Sürüşü Bitir ve Kaydet
  Future<Ride?> stopRide() async {
    if (state == TrackingState.stopped || currentRideId == null) return null;

    state = TrackingState.stopped;
    _positionStream?.cancel();
    _timer?.cancel();

    final endTime = DateTime.now();
    final double totalDistanceKm = totalDistanceMeters / 1000.0;

    // Ortalama hız = Yol / Zaman (Saat cinsinden)
    double avgSpeed = 0.0;
    if (movingDurationSeconds > 0) {
      avgSpeed = (totalDistanceKm / (movingDurationSeconds / 3600.0));
    }

    final completedRide = Ride(
      id: currentRideId,
      startTime: startTime!,
      endTime: endTime,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(2)),
      totalDurationSeconds: totalDurationSeconds,
      movingDurationSeconds: movingDurationSeconds,
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeedKmh.toStringAsFixed(1)),
      routePoints: List.from(points),
    );

    // Veritabanındaki özeti son haline güncelle
    await _dbService.updateRide(completedRide);

    return completedRide;
  }
}
