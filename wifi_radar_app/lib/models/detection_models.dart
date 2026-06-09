import 'dart:math';
import 'dart:ui';

class APData {
  final String bssid;
  final String ssid;
  final int rssi;
  final DateTime timestamp;
  final int frequency;

  APData({
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
  final double angle;
  final double distance;
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

class RadarBlip {
  final Offset position;
  final double intensity;
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
