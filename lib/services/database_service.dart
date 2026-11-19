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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Telefonun güvenli yerel dosya yolunu alıyoruz
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

  // Yeni bir sürüş başlatıldığında veritabanına ekle ve oluşturulan ID'yi dön
  Future<int> insertRide(Ride ride) async {
    final db = await database;
    return await db.insert('rides', ride.toMap());
  }

  // Sürüş sırasında her yeni GPS koordinatını bu sürüşe ekle
  Future<void> insertCoordinatePoint(CoordinatePoint point) async {
    final db = await database;
    await db.insert('coordinate_points', point.toMap());
  }

  // Sürüş bittiğinde toplam süre, km ve ortalama hızları güncelle
  Future<void> updateRide(Ride ride) async {
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
    final db = await database;
    await db.delete('rides', where: 'id = ?', whereArgs: [rideId]);
    await db.delete('coordinate_points', where: 'ride_id = ?', whereArgs: [rideId]);
  }
}
