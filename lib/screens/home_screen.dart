import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/claude_service.dart';
import '../services/storage_service.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAnalyzing = false;
  String? _currentFileName;

  Future<void> _pickAndAnalyze() async {
    final apiKey = await StorageService.getApiKey();
    if (!mounted) return;

    if (apiKey == null || apiKey.isEmpty) {
      _showError(
        'API ключ не настроен. Нажмите "Настройки" для добавления ключа Anthropic.',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showError('Не удалось прочитать файл. Попробуйте снова.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentFileName = file.name;
    });

    try {
      final service = ClaudeService(apiKey: apiKey);
      final legalCase = await service.analyzeLegalDocument(file.bytes!);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(legalCase: legalCase),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Ок',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Правовой анализ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Исполнительные документы Казахстана',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Настройки API ключа',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Kazakhstan flag-colored header banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Анализ документов\nисполнительного производства',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Загрузите PDF — Claude AI проведёт полный\nправовой анализ по законодательству РК',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Upload card
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Поддерживаемые документы',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DocTypeRow(
                          icon: Icons.draw,
                          color: Colors.deepPurple,
                          title: 'Исполнительная надпись нотариуса',
                          subtitle:
                              'Нотариально заверенный документ взыскания долга',
                        ),
                        const SizedBox(height: 12),
                        _DocTypeRow(
                          icon: Icons.account_balance,
                          color: Colors.indigo,
                          title: 'Исполнительный лист',
                          subtitle:
                              'Судебный документ принудительного исполнения',
                        ),
                        const SizedBox(height: 24),
                        if (_isAnalyzing)
                          _AnalyzingWidget(fileName: _currentFileName)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _pickAndAnalyze,
                              icon: const Icon(Icons.upload_file, size: 22),
                              label: const Text(
                                'Загрузить PDF для анализа',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Features section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'Что анализирует система',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.search,
                    color: Colors.blue,
                    title: 'Извлечение данных',
                    items: const [
                      'Должник и взыскатель',
                      'Дата и сумма взыскания',
                      'Нотариус и номер дела',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                    title: 'Выявление нарушений',
                    items: const [
                      'Отсутствие уведомления должника (ст. 26)',
                      'Истечение срока давности (ст. 178 ГК РК)',
                      'Процессуальные нарушения документа',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.description,
                    color: Colors.green,
                    title: 'Генерация документов',
                    items: const [
                      'Подробный правовой анализ',
                      'Рекомендованная стратегия защиты',
                      'Готовое возражение для суда/прокуратуры',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocTypeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _DocTypeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }
}

class _AnalyzingWidget extends StatelessWidget {
  final String? fileName;
  const _AnalyzingWidget({this.fileName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Анализирую: ${fileName ?? 'документ'}',
          style: const TextStyle(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Claude AI читает документ и проводит правовой анализ...\nОбычно занимает 30–60 секунд',
          style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: color, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
