import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ride.dart';
import '../models/coordinate_point.dart';

class DatabaseService {
  // Singleton Pattern: Uygulama boyunca tek bir veritabanı bağlantısı olsun diye.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Web ortamı için bellek ve SharedPreferences önbelleği
  final List<Ride> _webRides = [];
  bool _webLoaded = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'equibelle_tracks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Sürüşler Tablosu
    await db.execute('''
      CREATE TABLE rides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_distance_km REAL NOT NULL,
        total_duration_seconds INTEGER NOT NULL,
        moving_duration_seconds INTEGER NOT NULL,
        avg_speed_kmh REAL NOT NULL,
        max_speed_kmh REAL NOT NULL
      )
    ''');

    // 2. Koordinat Noktaları Tablosu (Her sürüşün rota çizgileri)
    await db.execute('''
      CREATE TABLE coordinate_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ride_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- WEB İÇİN VERİ SAKLAMA YARDIMCILARI ---
  Future<void> _ensureWebLoaded() async {
    if (!_webLoaded) {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('equibelle_web_rides');
      if (jsonStr != null) {
        try {
          final List<dynamic> decoded = jsonDecode(jsonStr);
          _webRides.clear();
          for (var item in decoded) {
            final pointsData = (item['points'] as List<dynamic>? ?? [])
                .map((p) => CoordinatePoint.fromMap(Map<String, dynamic>.from(p)))
                .toList();
            _webRides.add(Ride.fromMap(Map<String, dynamic>.from(item), points: pointsData));
          }
        } catch (_) {}
      }
      _webLoaded = true;
    }
  }

  Future<void> _saveWebRides() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _webRides.map((r) {
      final map = r.toMap();
      map['points'] = r.routePoints.map((p) => p.toMap()).toList();
      return map;
    }).toList();
    await prefs.setString('equibelle_web_rides', jsonEncode(list));
  }

  // Yeni bir sürüş başlatıldığında veritabanına ekle ve oluşturulan ID'yi dön
  Future<int> insertRide(Ride ride) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final newId = _webRides.isEmpty
          ? 1
          : (_webRides.map((r) => r.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newRide = Ride(
        id: newId,
        startTime: ride.startTime,
        endTime: ride.endTime,
        totalDistanceKm: ride.totalDistanceKm,
        totalDurationSeconds: ride.totalDurationSeconds,
        movingDurationSeconds: ride.movingDurationSeconds,
        avgSpeedKmh: ride.avgSpeedKmh,
        maxSpeedKmh: ride.maxSpeedKmh,
        routePoints: [],
      );
      _webRides.insert(0, newRide);
      await _saveWebRides();
      return newId;
    }

    final db = await database;
    return await db.insert('rides', ride.toMap());
  }

  // Sürüş sırasında her yeni GPS koordinatını bu sürüşe ekle
  Future<void> insertCoordinatePoint(CoordinatePoint point) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webRides.indexWhere((r) => r.id == point.rideId);
      if (index != -1) {
        final existing = _webRides[index];
        final updatedPoints = List<CoordinatePoint>.from(existing.routePoints)..add(point);
        _webRides[index] = Ride(
          id: existing.id,
          startTime: existing.startTime,
          endTime: existing.endTime,
          totalDistanceKm: existing.totalDistanceKm,
          totalDurationSeconds: existing.totalDurationSeconds,
          movingDurationSeconds: existing.movingDurationSeconds,
          avgSpeedKmh: existing.avgSpeedKmh,
          maxSpeedKmh: existing.maxSpeedKmh,
          routePoints: updatedPoints,
        );
      }
      return;
    }

    final db = await database;
    await db.insert('coordinate_points', point.toMap());
  }

  // Sürüş bittiğinde toplam süre, km ve ortalama hızları güncelle
  Future<void> updateRide(Ride ride) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webRides.indexWhere((r) => r.id == ride.id);
      if (index != -1) {
        final existing = _webRides[index];
        _webRides[index] = Ride(
          id: ride.id,
          startTime: ride.startTime,
          endTime: ride.endTime,
          totalDistanceKm: ride.totalDistanceKm,
          totalDurationSeconds: ride.totalDurationSeconds,
          movingDurationSeconds: ride.movingDurationSeconds,
          avgSpeedKmh: ride.avgSpeedKmh,
          maxSpeedKmh: ride.maxSpeedKmh,
          routePoints: existing.routePoints.isNotEmpty ? existing.routePoints : ride.routePoints,
        );
        await _saveWebRides();
      }
      return;
    }

    final db = await database;
    await db.update(
      'rides',
      ride.toMap(),
      where: 'id = ?',
      whereArgs: [ride.id],
    );
  }

  // Geçmiş tüm sürüşleri tarihe göre en yeniden en eskiye sıralayarak getir
  Future<List<Ride>> getAllRides() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      return List<Ride>.from(_webRides);
    }

    final db = await database;
    final List<Map<String, dynamic>> rideMaps = await db.query(
      'rides',
      orderBy: 'start_time DESC',
    );

    List<Ride> rides = [];
    for (var rMap in rideMaps) {
      final rideId = rMap['id'] as int;
      final pointMaps = await db.query(
        'coordinate_points',
        where: 'ride_id = ?',
        whereArgs: [rideId],
        orderBy: 'timestamp ASC',
      );

      final points = pointMaps.map((p) => CoordinatePoint.fromMap(p)).toList();
      rides.add(Ride.fromMap(rMap, points: points));
    }
    return rides;
  }

  // İstenmeyen bir sürüşü silmek için
  Future<void> deleteRide(int rideId) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webRides.removeWhere((r) => r.id == rideId);
      await _saveWebRides();
      return;
    }

    final db = await database;
    await db.delete('rides', where: 'id = ?', whereArgs: [rideId]);
    await db.delete('coordinate_points', where: 'ride_id = ?', whereArgs: [rideId]);
  }
}
