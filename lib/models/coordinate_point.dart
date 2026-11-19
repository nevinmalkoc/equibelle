class CoordinatePoint {
  final int? id;
  final int? rideId;
  final double latitude;
  final double longitude;
  final double speed; // km/h cinsinden tutacağız
  final DateTime timestamp;

  CoordinatePoint({
    this.id,
    this.rideId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });

  // Veritabanına (SQLite) kaydederken Map (sözlük) formatına çeviriyoruz
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ride_id': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Veritabanından okurken Map'ten nesneye dönüştürüyoruz
  factory CoordinatePoint.fromMap(Map<String, dynamic> map) {
    return CoordinatePoint(
      id: map['id'] as int?,
      rideId: map['ride_id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
