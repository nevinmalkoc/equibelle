import 'coordinate_point.dart';

class Ride {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceKm;
  final int totalDurationSeconds; // Toplam geçen süre (saniye)
  final int movingDurationSeconds; // Sadece hareket edilen süre (saniye)
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final List<CoordinatePoint> routePoints;

  Ride({
    this.id,
    required this.startTime,
    this.endTime,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.movingDurationSeconds,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    this.routePoints = const [],
  });

  // Durma süresi (Mola süresi = Toplam - Hareket)
  int get stoppedDurationSeconds {
    final diff = totalDurationSeconds - movingDurationSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_distance_km': totalDistanceKm,
      'total_duration_seconds': totalDurationSeconds,
      'moving_duration_seconds': movingDurationSeconds,
      'avg_speed_kmh': avgSpeedKmh,
      'max_speed_kmh': maxSpeedKmh,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map, {List<CoordinatePoint> points = const []}) {
    return Ride(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      totalDistanceKm: (map['total_distance_km'] as num).toDouble(),
      totalDurationSeconds: map['total_duration_seconds'] as int,
      movingDurationSeconds: map['moving_duration_seconds'] as int,
      avgSpeedKmh: (map['avg_speed_kmh'] as num).toDouble(),
      maxSpeedKmh: (map['max_speed_kmh'] as num).toDouble(),
      routePoints: points,
    );
  }
}
