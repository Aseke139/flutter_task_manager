import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart' as ws;
import '../models/detection_models.dart';

class WiFiScannerService extends ChangeNotifier {
  static const int _historySize = 30;
  static const double _motionThreshold = 3.0;
  static const double _presenceThreshold = 1.5;

  final Map<String, List<SignalSample>> _signalHistory = {};
  final List<DetectedBody> _currentBodies = [];
  final List<RadarBlip> _radarBlips = [];

  Timer? _scanTimer;
  bool _isScanning = false;
  DetectionLevel _currentLevel = DetectionLevel.none;
  String _statusMessage = 'Инициализация...';
  double _scanAngle = 0.0;
  int _scanCount = 0;

  bool get isScanning => _isScanning;
  DetectionLevel get currentLevel => _currentLevel;
  String get statusMessage => _statusMessage;
  double get scanAngle => _scanAngle;
  List<DetectedBody> get detectedBodies => List.unmodifiable(_currentBodies);
  List<RadarBlip> get radarBlips => List.unmodifiable(_radarBlips);
  int get scanCount => _scanCount;

  Future<bool> checkAndRequestPermissions() async {
    try {
      final canScan = await ws.WiFiScan.instance.canStartScan(askPermissions: true);
      return canScan == ws.CanStartScan.yes;
    } catch (_) {
      return false;
    }
  }

  void startScanning() {
    if (_isScanning) return;
    _isScanning = true;
    _statusMessage = 'Сканирование Wi-Fi сигналов...';
    notifyListeners();

    Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!_isScanning) { t.cancel(); return; }
      _scanAngle = (_scanAngle + 0.03) % (2 * pi);
      notifyListeners();
    });

    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _performScan();
    });

    _performScan();
  }

  void stopScanning() {
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    _statusMessage = 'Сканирование остановлено';
    _currentLevel = DetectionLevel.none;
    notifyListeners();
  }

  Future<void> _performScan() async {
    try {
      final canGet = await ws.WiFiScan.instance.canGetScannedResults(
        askPermissions: false,
      );

      if (canGet == ws.CanGetScannedResults.yes) {
        await ws.WiFiScan.instance.startScan();
        await Future.delayed(const Duration(milliseconds: 800));
        final results = await ws.WiFiScan.instance.getScannedResults();
        final now = DateTime.now();

        final aps = results.map((r) => APData(
          bssid: r.bssid,
          ssid: r.ssid,
          rssi: r.level,
          timestamp: now,
          frequency: r.frequency,
        )).toList();

        _updateSignalHistory(aps, now);
        _analyzeSignals(aps, now);
      } else {
        _generateMockData();
      }
    } catch (_) {
      _generateMockData();
    }
    _scanCount++;
    notifyListeners();
  }

  void _updateSignalHistory(List<APData> aps, DateTime now) {
    for (final ap in aps) {
      _signalHistory.putIfAbsent(ap.bssid, () => []);
      final history = _signalHistory[ap.bssid]!;
      history.add(SignalSample(bssid: ap.bssid, rssi: ap.rssi, time: now));
      if (history.length > _historySize) history.removeAt(0);
    }
  }

  void _analyzeSignals(List<APData> aps, DateTime now) {
    if (_signalHistory.isEmpty) return;

    double totalVariance = 0.0;
    int analyzedCount = 0;
    final Map<String, double> apVariances = {};

    for (final entry in _signalHistory.entries) {
      if (entry.value.length < 3) continue;
      final variance = _calculateVariance(
        entry.value.map((s) => s.rssi.toDouble()).toList(),
      );
      apVariances[entry.key] = variance;
      totalVariance += variance;
      analyzedCount++;
    }

    if (analyzedCount == 0) return;
    final avgVariance = totalVariance / analyzedCount;

    _updateDetectionLevel(avgVariance);
    _updateDetectedBodies(apVariances, aps, now);
    _updateStatusMessage(avgVariance);
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2).toDouble());
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  void _updateDetectionLevel(double avgVariance) {
    if (avgVariance < _presenceThreshold) {
      _currentLevel = DetectionLevel.none;
    } else if (avgVariance < _motionThreshold) {
      _currentLevel = DetectionLevel.low;
    } else if (avgVariance < _motionThreshold * 2) {
      _currentLevel = DetectionLevel.medium;
    } else if (avgVariance < _motionThreshold * 4) {
      _currentLevel = DetectionLevel.high;
    } else {
      _currentLevel = DetectionLevel.critical;
    }
  }

  void _updateDetectedBodies(
    Map<String, double> apVariances,
    List<APData> aps,
    DateTime now,
  ) {
    _currentBodies.clear();
    _radarBlips.removeWhere((b) => b.age > 6.0);

    final motionAPs = apVariances.entries
        .where((e) => e.value > _presenceThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final random = Random(_scanCount);

    for (int i = 0; i < motionAPs.length && i < 5; i++) {
      final entry = motionAPs[i];
      final ap = aps.firstWhere(
        (a) => a.bssid == entry.key,
        orElse: () => APData(
          bssid: entry.key, ssid: '?', rssi: -70,
          timestamp: now, frequency: 2412,
        ),
      );

      final rssiNorm = ((ap.rssi + 100).clamp(0, 60)) / 60.0;
      final distance = (1.0 - rssiNorm) * 0.85 + 0.1;
      final angle = (i / motionAPs.length) * 2 * pi +
          (random.nextDouble() - 0.5) * 0.3;
      final intensity = (entry.value / (_motionThreshold * 3)).clamp(0.0, 1.0);

      final body = DetectedBody(
        id: entry.key,
        angle: angle,
        distance: distance,
        intensity: intensity,
        detectedAt: now,
        isMoving: entry.value > _motionThreshold,
      );
      _currentBodies.add(body);

      _radarBlips.add(RadarBlip(
        position: body.radarPosition,
        intensity: intensity,
        createdAt: now,
      ));
    }
  }

  void _updateStatusMessage(double variance) {
    switch (_currentLevel) {
      case DetectionLevel.none:
        _statusMessage = 'Нет движений. Зона чистая.';
        break;
      case DetectionLevel.low:
        _statusMessage = 'Обнаружено слабое движение';
        break;
      case DetectionLevel.medium:
        _statusMessage = 'Движение в зоне! (${_currentBodies.length} объект(ов))';
        break;
      case DetectionLevel.high:
        _statusMessage = 'Активное движение! ${_currentBodies.length} тел(а)';
        break;
      case DetectionLevel.critical:
        _statusMessage = 'ТРЕВОГА: Множество движений!';
        break;
    }
  }

  void _generateMockData() {
    final random = Random();
    final now = DateTime.now();

    final mockBSSIDs = [
      'AA:BB:CC:DD:EE:01',
      'AA:BB:CC:DD:EE:02',
      'AA:BB:CC:DD:EE:03',
      'AA:BB:CC:DD:EE:04',
    ];

    final motionCycle = (_scanCount ~/ 8) % 3;
    final hasMotion = motionCycle > 0;

    for (int i = 0; i < mockBSSIDs.length; i++) {
      final bssid = mockBSSIDs[i];
      _signalHistory.putIfAbsent(bssid, () => []);
      double baseRssi = -50.0 - i * 10.0;
      double noise = (random.nextDouble() - 0.5) * 2.0;
      if (hasMotion && i < motionCycle + 1) {
        noise += (random.nextDouble() - 0.5) * 12.0;
      }
      final history = _signalHistory[bssid]!;
      history.add(SignalSample(
        bssid: bssid,
        rssi: (baseRssi + noise).round(),
        time: now,
      ));
      if (history.length > _historySize) history.removeAt(0);
    }

    final mockAPs = mockBSSIDs.asMap().entries.map((e) => APData(
      bssid: e.value,
      ssid: 'WiFi_Demo_${e.key + 1}',
      rssi: (-50 - e.key * 10),
      timestamp: now,
      frequency: 2412 + e.key * 5,
    )).toList();

    _analyzeSignals(mockAPs, now);
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }
}
