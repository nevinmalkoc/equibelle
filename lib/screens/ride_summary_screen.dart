import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _noteController = TextEditingController();
  ShareCardTheme _selectedTheme = ShareCardTheme.cream;
  File? _customPhotoFile;
  bool _isSaving = false;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}sa ${minutes}dk';
    return '${minutes}dk';
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _customPhotoFile = File(picked.path);
        _selectedTheme = ShareCardTheme.photoBackground; // Otomatik olarak fotoğraflı moda al
      });
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);

    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);

      if (imageBytes != null) {
        await Gal.putImageBytes(
          imageBytes,
          name: 'Equibelle_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.richSaddle,
              content: Text('Kart Fotoğraflar\'a kaydedildi! 🐴✨'),
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
              // 1. ÖZET METRİKLERİ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.softGrey),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
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
              const SizedBox(height: 20),

              // 2. ÖZEL NOT ALANI
              TextField(
                controller: _noteController,
                maxLength: 60,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Sürüşe özel not ekle (Örn: Rüzgar çok keyifliydi...)',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.richSaddle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.softGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.softGrey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. FOTOĞRAF SEÇ BUTONU
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.richSaddle,
                  side: const BorderSide(color: AppTheme.richSaddle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  _customPhotoFile == null ? 'Fotoğrafını Arka Plan Yap 📸' : 'Fotoğrafı Değiştir 🔄',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // 4. TEMA SEÇİM ÇUBUĞU (7 TEMA)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PAYLAŞIM KARTI TEMASI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildThemeChip('📸 Fotoğraflı', ShareCardTheme.photoBackground),
                    const SizedBox(width: 8),
                    _buildThemeChip('🗺️ Harita', ShareCardTheme.mapOverlay),
                    const SizedBox(width: 8),
                    _buildThemeChip('🍦 Krem', ShareCardTheme.cream),
                    const SizedBox(width: 8),
                    _buildThemeChip('🍷 Bordo', ShareCardTheme.bordeaux),
                    const SizedBox(width: 8),
                    _buildThemeChip('👜 Taba (Logo)', ShareCardTheme.saddleBrand),
                    const SizedBox(width: 8),
                    _buildThemeChip('🌑 Gece', ShareCardTheme.dark),
                    const SizedBox(width: 8),
                    _buildThemeChip('🪟 Şeffaf (Video)', ShareCardTheme.transparent),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 5. 9:16 PAYLAŞIM KARTI ÖNİZLEMESİ
              Screenshot(
                controller: _screenshotController,
                child: ShareCardWidget(
                  ride: widget.ride,
                  theme: _selectedTheme,
                  customNote: _noteController.text,
                  customPhotoFile: _customPhotoFile,
                ),
              ),
              const SizedBox(height: 28),

              // 6. GALERİYE KAYDET BUTONU
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.richSaddle,
                    foregroundColor: AppTheme.creamBg,
                    elevation: 4,
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.richSaddle,
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
      selectedColor: AppTheme.richSaddle,
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
