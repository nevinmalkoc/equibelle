import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'ride_summary_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Ride>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  void _loadRides() {
    setState(() {
      _ridesFuture = _dbService.getAllRides();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}sa ${minutes}dk';
    return '${minutes}dk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: const Text('SÜRÜŞ GEÇMİŞİ'),
      ),
      body: FutureBuilder<List<Ride>>(
        future: _ridesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.forestGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata oluştu: ${snapshot.error}'),
            );
          }

          final rides = snapshot.data ?? [];

          if (rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_off_rounded,
                    size: 64,
                    color: AppTheme.saddleBrown.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz kaydedilmiş bir sürüş yok.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'İlk orman turunu başlattığında burada göreceksin.',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.softGrey),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onTap: () {
                    // Tıklanınca o sürüşün 9:16 paylaşım kartını aç
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideSummaryScreen(ride: ride),
                      ),
                    );
                  },
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: AppTheme.forestGreen,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    _formatDate(ride.startTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text(
                          '${ride.totalDistanceKm} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.saddleBrown,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.black38)),
                        Text(
                          _formatDuration(ride.totalDurationSeconds),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.black38)),
                        Text(
                          '${ride.avgSpeedKmh} km/s',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.black38, size: 22),
                    onPressed: () async {
                      // Silme Onay Penceresi
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sürüşü Sil'),
                          content: const Text('Bu sürüş kaydını silmek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Vazgeç'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && ride.id != null) {
                        await _dbService.deleteRide(ride.id!);
                        _loadRides();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
