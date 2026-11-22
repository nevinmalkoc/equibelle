import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../models/ride.dart';
import '../theme/app_theme.dart';
import '../widgets/share_card_widget.dart';

class RideSummaryScreen extends StatefulWidget {
  final Ride ride;

  const RideSummaryScreen({super.key, required this.ride});

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ShareCardTheme _selectedTheme = ShareCardTheme.cream;
  bool _isSaving = false;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}sa ${minutes}dk';
    }
    return '${minutes}dk';
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);

    try {
      // 1. Ekrandaki 9:16 kartın yüksek çözünürlüklü ekran görüntüsünü al
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0, // Retina ekran kalitesi (Çok net)
      );

      if (imageBytes != null) {
        // 2. iPhone Fotoğraf Galerisine kaydet
        await Gal.putImageBytes(
          imageBytes,
          name: 'Equibelle_Ride_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.forestGreen,
              content: Text('Kart başarıyla Fotoğraflar\'a kaydedildi! 🐴✨'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Kaydetme hatası: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: const Text('SÜRÜŞ ÖZETİ'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Özet İstatistik Satırları
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.softGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Mesafe', '${widget.ride.totalDistanceKm} km'),
                    _buildStat('Toplam Süre', _formatDuration(widget.ride.totalDurationSeconds)),
                    _buildStat('Hareket', _formatDuration(widget.ride.movingDurationSeconds)),
                    _buildStat('Mola', _formatDuration(widget.ride.stoppedDurationSeconds)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tema Seçim Hapları
              const Text(
                'PAYLAŞIM KARTI TEMASI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildThemeChip('Krem (Minimal)', ShareCardTheme.cream),
                  const SizedBox(width: 10),
                  _buildThemeChip('Gece (Asil)', ShareCardTheme.dark),
                  const SizedBox(width: 10),
                  _buildThemeChip('Şeffaf (Video)', ShareCardTheme.transparent),
                ],
              ),
              const SizedBox(height: 20),

              // 9:16 PAYLAŞIM KARTI ÖNİZLEMESİ
              Screenshot(
                controller: _screenshotController,
                child: ShareCardWidget(
                  ride: widget.ride,
                  theme: _selectedTheme,
                ),
              ),
              const SizedBox(height: 28),

              // GALERİYE KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    foregroundColor: AppTheme.creamBg,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveToGallery,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isSaving ? 'KAYDEDİLİYOR...' : 'FOTOĞRAFLARA KAYDET',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeChip(String title, ShareCardTheme theme) {
    final isSelected = _selectedTheme == theme;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: AppTheme.forestGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() => _selectedTheme = theme);
      },
    );
  }
}
