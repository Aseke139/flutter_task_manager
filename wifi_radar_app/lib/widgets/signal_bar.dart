import 'package:flutter/material.dart';
import '../models/detection_models.dart';

class DetectionLevelBar extends StatelessWidget {
  final DetectionLevel level;

  const DetectionLevelBar({super.key, required this.level});

  Color get _color {
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

  int get _filledBars {
    switch (level) {
      case DetectionLevel.none:
        return 0;
      case DetectionLevel.low:
        return 1;
      case DetectionLevel.medium:
        return 2;
      case DetectionLevel.high:
        return 3;
      case DetectionLevel.critical:
        return 4;
    }
  }

  String get _label {
    switch (level) {
      case DetectionLevel.none:
        return 'ЧИСТО';
      case DetectionLevel.low:
        return 'СЛАБО';
      case DetectionLevel.medium:
        return 'ДВИЖЕНИЕ';
      case DetectionLevel.high:
        return 'АКТИВНО';
      case DetectionLevel.critical:
        return 'ТРЕВОГА';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: _color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (i) {
            final filled = i < _filledBars;
            return Container(
              width: 8,
              height: 16 + i * 3.0,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: filled ? _color : _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
                boxShadow: filled
                    ? [BoxShadow(color: _color.withOpacity(0.6), blurRadius: 4)]
                    : null,
              ),
            );
          }),
          const SizedBox(width: 10),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class SignalStrengthWidget extends StatelessWidget {
  final int rssi;
  final String ssid;

  const SignalStrengthWidget({
    super.key,
    required this.rssi,
    required this.ssid,
  });

  Color get _color {
    if (rssi > -50) return const Color(0xFF00FF41);
    if (rssi > -65) return const Color(0xFF88FF00);
    if (rssi > -75) return const Color(0xFFFFFF00);
    return const Color(0xFFFF4444);
  }

  int get _bars {
    if (rssi > -50) return 4;
    if (rssi > -65) return 3;
    if (rssi > -75) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(4, (i) => Container(
          width: 4,
          height: 6.0 + i * 3,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: i < _bars ? _color : _color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(1),
          ),
        )),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            ssid.length > 12 ? '${ssid.substring(0, 12)}...' : ssid,
            style: TextStyle(
              color: _color.withOpacity(0.8),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$rssi dBm',
          style: TextStyle(
            color: _color.withOpacity(0.6),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
