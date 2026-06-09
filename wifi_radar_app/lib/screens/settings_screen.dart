import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sensitivity = 1.5;
  double _scanInterval = 1.5;
  bool _soundAlerts = true;
  bool _vibration = true;
  String _displayMode = 'radar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'НАСТРОЙКИ РАДАРА',
          style: TextStyle(
            color: Color(0xFF00FF41),
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF003300)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('ОБНАРУЖЕНИЕ'),
          _sliderTile(
            label: 'ЧУВСТВИТЕЛЬНОСТЬ',
            value: _sensitivity,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            displayValue: _sensitivity.toStringAsFixed(1),
            onChanged: (v) => setState(() => _sensitivity = v),
          ),
          _sliderTile(
            label: 'ИНТЕРВАЛ СКАНИРОВАНИЯ (с)',
            value: _scanInterval,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            displayValue: '${_scanInterval.toStringAsFixed(1)}с',
            onChanged: (v) => setState(() => _scanInterval = v),
          ),

          const SizedBox(height: 16),
          _sectionHeader('ОТОБРАЖЕНИЕ'),
          _radioTile('Радар (круговой)', 'radar', _displayMode,
              (v) => setState(() => _displayMode = v!)),
          _radioTile('Тепловая карта', 'heatmap', _displayMode,
              (v) => setState(() => _displayMode = v!)),
          _radioTile('Список объектов', 'list', _displayMode,
              (v) => setState(() => _displayMode = v!)),

          const SizedBox(height: 16),
          _sectionHeader('ОПОВЕЩЕНИЯ'),
          _switchTile('Звуковые сигналы', _soundAlerts,
              (v) => setState(() => _soundAlerts = v)),
          _switchTile('Вибрация', _vibration,
              (v) => setState(() => _vibration = v)),

          const SizedBox(height: 24),
          _sectionHeader('О ТЕХНОЛОГИИ'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Приложение использует изменения уровня сигнала Wi-Fi (RSSI) '
              'для обнаружения движения тел в помещении. '
              'Тело человека поглощает и отражает радиоволны (2.4 / 5 ГГц), '
              'создавая характерные флуктуации сигнала.\n\n'
              'Точность зависит от:\n'
              '• Количества точек доступа Wi-Fi\n'
              '• Расположения роутера\n'
              '• Материала стен\n'
              '• Количества объектов в помещении\n\n'
              'Диапазон: до 10-15 метров (типично для домашнего Wi-Fi).',
              style: TextStyle(
                color: Color(0xFF006600),
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003300),
              foregroundColor: const Color(0xFF00FF41),
              side: const BorderSide(color: Color(0xFF00FF41)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ПРИМЕНИТЬ',
              style: TextStyle(fontFamily: 'monospace', letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00AA30),
          fontSize: 10,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF003300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00FF41),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                displayValue,
                style: const TextStyle(
                  color: Color(0xFF00AA30),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00FF41),
              inactiveTrackColor: const Color(0xFF003300),
              thumbColor: const Color(0xFF00FF41),
              overlayColor: const Color(0xFF00FF41).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioTile(String label, String value, String groupValue,
      ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value
              ? const Color(0xFF00FF41)
              : const Color(0xFF003300),
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FF41),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        activeColor: const Color(0xFF00FF41),
        dense: true,
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF003300)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FF41),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        activeColor: const Color(0xFF00FF41),
        dense: true,
      ),
    );
  }
}
