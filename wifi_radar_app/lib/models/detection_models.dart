import 'dart:math';

class WiFiAccessPoint {
  final String bssid;
  final String ssid;
  final int rssi;
  final DateTime timestamp;
  final int frequency;

  WiFiAccessPoint({
    required this.bssid,
    required this.ssid,
    required this.rssi,
    required this.timestamp,
    required this.frequency,
  });
}

class SignalSample {
  final String bssid;
  final int rssi;
  final DateTime time;

  SignalSample({required this.bssid, required this.rssi, required this.time});
}

enum DetectionLevel { none, low, medium, high, critical }

class DetectedBody {
  final String id;
  final double angle;    // angle in radians on radar
  final double distance; // normalized 0.0 - 1.0
  final double intensity;
  final DateTime detectedAt;
  final bool isMoving;

  DetectedBody({
    required this.id,
    required this.angle,
    required this.distance,
    required this.intensity,
    required this.detectedAt,
    required this.isMoving,
  });

  Offset get radarPosition {
    return Offset(
      distance * cos(angle),
      distance * sin(angle),
    );
  }

  DetectedBody copyWith({bool? isMoving, double? intensity}) {
    return DetectedBody(
      id: id,
      angle: angle,
      distance: distance,
      intensity: intensity ?? this.intensity,
      detectedAt: detectedAt,
      isMoving: isMoving ?? this.isMoving,
    );
  }
}

class ScanResult {
  final List<WiFiAccessPoint> accessPoints;
  final DateTime scanTime;
  final DetectionLevel overallLevel;
  final List<DetectedBody> detectedBodies;
  final double signalVariance;

  ScanResult({
    required this.accessPoints,
    required this.scanTime,
    required this.overallLevel,
    required this.detectedBodies,
    required this.signalVariance,
  });
}

class RadarBlip {
  final Offset position; // -1.0 to 1.0 on each axis
  final double intensity; // 0.0 - 1.0
  final DateTime createdAt;
  final bool isActive;

  RadarBlip({
    required this.position,
    required this.intensity,
    required this.createdAt,
    this.isActive = true,
  });

  double get age =>
      DateTime.now().difference(createdAt).inMilliseconds / 1000.0;

  double get fadedIntensity => intensity * max(0, 1.0 - age / 5.0);
}
