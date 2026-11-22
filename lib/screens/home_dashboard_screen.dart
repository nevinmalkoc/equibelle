import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ride.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'live_tracking_screen.dart';
import 'ride_history_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _riderName = 'Binici';
  String _horseName = '';
  List<Ride> _recentRides = [];
  double _totalKm = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRider = prefs.getString('rider_name');
    final savedHorse = prefs.getString('horse_name') ?? '';

    // Eğer ilk kez açılıyorsa isim sorma penceresini aç
    if (savedRider == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileDialog();
      });
    } else {
      _riderName = savedRider;
      _horseName = savedHorse;
    }

    final rides = await _dbService.getAllRides();
    double total = 0.0;
    for (var r in rides) {
      total += r.totalDistanceKm;
    }

    if (mounted) {
      setState(() {
        _recentRides = rides;
        _totalKm = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _showProfileDialog() async {
    final riderCtrl = TextEditingController(text: _riderName == 'Binici' ? '' : _riderName);
    final horseCtrl = TextEditingController(text: _horseName);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'E Q U I B E L L E',
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
            fontFamily: 'serif',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Size ve atınıza özel bir deneyim için bilgilerinizi girin:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: riderCtrl,
              decoration: InputDecoration(
                labelText: 'İsminiz',
                labelStyle: const TextStyle(color: AppTheme.forestGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: horseCtrl,
              decoration: InputDecoration(
                labelText: 'Atınızın Adı (Opsiyonel)',
                labelStyle: const TextStyle(color: AppTheme.forestGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final name = riderCtrl.text.trim().isEmpty ? 'Binici' : riderCtrl.text.trim();
              final horse = horseCtrl.text.trim();

              await prefs.setString('rider_name', name);
              await prefs.setString('horse_name', horse);

              if (!context.mounted) return;
              if (mounted) {
                setState(() {
                  _riderName = name;
                  _horseName = horse;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('KAYDET VE BAŞLA'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: const Text('E Q U I B E L L E'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 26),
            tooltip: 'Profili Düzenle',
            onPressed: _showProfileDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.forestGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KİŞİSEL SELAMLAMA KARTI
                  Text(
                    '${_getGreeting()}, $_riderName',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                      letterSpacing: 0.5,
                      fontFamily: 'serif',
                    ),
                  ),
                  if (_horseName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$_horseName ile bir orman turuna hazır mısın?',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.saddleBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // 2. İSTATİSTİK ÖZETİ
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.softGrey),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('TOPLAM MESAFE', '${_totalKm.toStringAsFixed(1)} km'),
                        Container(height: 40, width: 1, color: AppTheme.softGrey),
                        _buildStatBox('SÜRÜŞ SAYISI', '${_recentRides.length} Tur'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 3. BÜYÜK SÜRÜŞE BAŞLA KARTI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.explore_rounded, size: 48, color: AppTheme.accentGold),
                        const SizedBox(height: 14),
                        const Text(
                          'ORMAN PARKURU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'İnternetsiz GPS ile rotanızı kaydedin',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.creamBg,
                              foregroundColor: AppTheme.forestGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LiveTrackingScreen(),
                                ),
                              ).then((_) => _loadProfileAndData());
                            },
                            child: const Text(
                              'SÜRÜŞÜ BAŞLAT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. GEÇMİŞ SÜRÜŞLER BUTONU
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.softGrey),
                    ),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.history_rounded, color: AppTheme.forestGreen),
                    title: const Text(
                      'Sürüş Geçmişi & Arşiv',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.forestGreen),
                    ),
                    subtitle: const Text('Eski turlarınızı ve kartlarınızı görün'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RideHistoryScreen(),
                        ),
                      ).then((_) => _loadProfileAndData());
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
      ],
    );
  }
}
