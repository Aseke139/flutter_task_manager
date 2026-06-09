import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wifi_scanner_service.dart';
import '../models/detection_models.dart';
import '../widgets/radar_painter.dart';
import '../widgets/signal_bar.dart';
import 'settings_screen.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = context.read<WiFiScannerService>();
    final granted = await service.checkAndRequestPermissions();
    if (mounted && granted) {
      service.startScanning();
    } else if (mounted) {
      // Start anyway — will use demo mode if Wi-Fi unavailable
      service.startScanning();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<WiFiScannerService>(
          builder: (context, service, _) {
            return Column(
              children: [
                _buildTopBar(service),
                Expanded(child: _buildRadarSection(service)),
                _buildBottomPanel(service),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(WiFiScannerService service) {
    final color = _levelColor(service.currentLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering, color: color, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Wi-Fi РАДАР',
            style: TextStyle(
              color: Color(0xFF00FF41),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          DetectionLevelBar(level: service.currentLevel),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF00FF41), size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSection(WiFiScannerService service) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Status line
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: _levelColor(service.currentLevel).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                _blinkingDot(service.isScanning, service.currentLevel),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.statusMessage,
                    style: TextStyle(
                      color: _levelColor(service.currentLevel),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Text(
                  'СКАН #${service.scanCount}',
                  style: const TextStyle(
                    color: Color(0xFF00AA30),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Radar display
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: RadarPainter(
                    sweepAngle: service.scanAngle,
                    bodies: service.detectedBodies,
                    blips: service.radarBlips,
                    level: service.currentLevel,
                    pulseRadius: _pulseController.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Coordinate display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip('АЗИМУТ', '${(service.scanAngle * 180 / pi).toStringAsFixed(0)}°'),
              _infoChip('ТЕЛА', '${service.detectedBodies.length}'),
              _infoChip('ДВИЖ.', service.detectedBodies.where((b) => b.isMoving).length.toString()),
              _infoChip('СИГН.', service.currentLevel == DetectionLevel.none ? 'ОК' : 'ALT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(WiFiScannerService service) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: const Border(
          top: BorderSide(color: Color(0xFF003300)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ОБНАРУЖЕННЫЕ ТЕЛА',
                style: TextStyle(
                  color: Color(0xFF00AA30),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (service.isScanning) {
                    service.stopScanning();
                  } else {
                    service.startScanning();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: service.isScanning
                          ? const Color(0xFFFF4444)
                          : const Color(0xFF00FF41),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    service.isScanning ? '[ СТОП ]' : '[ СТАРТ ]',
                    style: TextStyle(
                      color: service.isScanning
                          ? const Color(0xFFFF4444)
                          : const Color(0xFF00FF41),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF003300), height: 8),
          Expanded(
            child: service.detectedBodies.isEmpty
                ? Center(
                    child: Text(
                      service.isScanning
                          ? '--- ожидание обнаружения ---'
                          : '--- сканирование остановлено ---',
                      style: const TextStyle(
                        color: Color(0xFF003300),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: service.detectedBodies.length,
                    itemBuilder: (context, i) {
                      final body = service.detectedBodies[i];
                      final angle = (body.angle * 180 / pi).toStringAsFixed(0);
                      final dist = (body.distance * 100).toStringAsFixed(0);
                      final status = body.isMoving ? 'ДВИЖЕТСЯ' : 'СТАТИЧЕН';
                      final statusColor = body.isMoving
                          ? const Color(0xFFFF4444)
                          : const Color(0xFFFFFF00);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ОБЪЕКТ ${i + 1}',
                              style: const TextStyle(
                                color: Color(0xFF00FF41),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AZM:$angle° DIST:$dist%',
                              style: const TextStyle(
                                color: Color(0xFF008833),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _blinkingDot(bool scanning, DetectionLevel level) {
    if (!scanning) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _levelColor(level)
              .withOpacity(0.5 + _pulseController.value * 0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _levelColor(level).withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF003300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF006600),
              fontSize: 8,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FF41),
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(DetectionLevel level) {
    switch (level) {
      case DetectionLevel.none:
        return const Color(0xFF00FF41);
      case DetectionLevel.low:
        return const Color(0xFF88FF00);
      case DetectionLevel.medium:
        return const Color(0xFFFFFF00);
      case DetectionLevel.high:
        return const Color(0xFFFF8800);
      case DetectionLevel.critical:
        return const Color(0xFFFF0000);
    }
  }
}
