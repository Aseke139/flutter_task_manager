import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/legal_case.dart';

class ClaudeService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-opus-4-6';
  static const _anthropicVersion = '2023-06-01';

  final String apiKey;

  ClaudeService({required this.apiKey});

  Future<LegalCase> analyzeLegalDocument(List<int> pdfBytes) async {
    final base64Pdf = base64Encode(pdfBytes);

    const systemPrompt =
        'Вы — эксперт по законодательству Республики Казахстан в области '
        'исполнительного производства. Специализируетесь на Законе РК '
        '"Об исполнительном производстве и статусе судебных исполнителей", '
        'Гражданском процессуальном кодексе РК и Гражданском кодексе РК. '
        'ВАЖНО: Возвращайте ответ ТОЛЬКО в формате JSON, начиная с { и заканчивая }. '
        'Не добавляйте никакого текста до или после JSON.';

    const userPrompt = '''Проанализируйте предоставленный документ исполнительного производства.

Верните результат СТРОГО в формате JSON без каких-либо пояснений:

{
  "document_info": {
    "document_type": "executive_inscription или enforcement_order или unknown",
    "debtor": "ФИО или наименование должника",
    "creditor": "ФИО или наименование взыскателя/кредитора",
    "date": "дата документа",
    "amount": "сумма взыскания с валютой (тенге/KZT)",
    "notary": "ФИО нотариуса и нотариальный округ (для надписи) или Не указано",
    "case_number": "номер дела или исполнительного документа или Не указано"
  },
  "violations": {
    "notification_violations": [
      "Нарушение уведомления — конкретное описание со ссылкой на ст. 26 Закона РК об исполнительном производстве. Например: должник не был уведомлен за 3 дня до совершения исполнительной надписи"
    ],
    "limitation_period_violations": [
      "Нарушение срока исковой давности — конкретное описание со ссылкой на ст. 178 ГК РК (3 года). Например: с момента возникновения обязательства прошло более 3 лет"
    ],
    "procedural_violations": [
      "Процессуальное нарушение — конкретное описание. Например: отсутствует нотариальная печать, неверно указана сумма, нет подписи должника"
    ]
  },
  "legal_analysis": "Подробный правовой анализ на 4-6 абзацев. Включить: 1) Правовую природу документа и применимое законодательство; 2) Анализ соответствия требованиям ст. 91 Закона о нотариате РК или ст. 240 ГПК РК; 3) Детальный разбор выявленных нарушений со ссылками на конкретные статьи; 4) Правовые последствия нарушений для должника; 5) Оценку перспектив оспаривания.",
  "recommended_strategy": "Конкретная пошаговая стратегия защиты должника: 1) Немедленные действия (в течение 10 дней); 2) Куда обращаться (суд/прокуратура/нотариальная палата); 3) Какие доказательства собрать; 4) Какие ходатайства заявить; 5) Прогноз результата.",
  "objection_draft": "В [название суда/органа]\\nАдрес: [адрес]\\n\\nОт: [ФИО должника]\\nАдрес: [адрес должника]\\nТелефон: [телефон]\\n\\nВзыскатель: [наименование взыскателя]\\n\\nВОЗРАЖЕНИЕ\\nна исполнительную надпись нотариуса / исполнительный лист\\n\\nДата документа: [дата]\\nСумма: [сумма]\\n\\nСодержание возражения со ссылками на конкретные статьи законов РК, описанием нарушений и просительной частью с конкретными требованиями (отменить/признать недействительным/приостановить исполнение).\\n\\n[Дата]\\n[Подпись] / [ФИО должника]"
}

Если информация отсутствует — укажите "Не указано".
Если нарушений нет — укажите пустой массив [].
Составляйте документ строго по законодательству Казахстана.''';

    final requestBody = {
      'model': _model,
      'max_tokens': 8000,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'document',
              'source': {
                'type': 'base64',
                'media_type': 'application/pdf',
                'data': base64Pdf,
              },
            },
            {
              'type': 'text',
              'text': userPrompt,
            },
          ],
        },
      ],
    };

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': _anthropicVersion,
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      final errorBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> errorJson;
      try {
        errorJson = jsonDecode(errorBody);
      } catch (_) {
        throw Exception('API Error ${response.statusCode}: $errorBody');
      }
      final message =
          errorJson['error']?['message'] ?? 'Unknown error';
      throw Exception('API Error ${response.statusCode}: $message');
    }

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    final contentBlocks = responseData['content'] as List? ?? [];

    // Find the text block (skip thinking blocks if present)
    String jsonText = '';
    for (final block in contentBlocks) {
      if (block['type'] == 'text') {
        jsonText = block['text'] as String? ?? '';
        break;
      }
    }

    if (jsonText.isEmpty) {
      throw Exception('Пустой ответ от Claude API');
    }

    final cleanedJson = _extractJson(jsonText);

    try {
      final parsedJson = jsonDecode(cleanedJson) as Map<String, dynamic>;
      return LegalCase.fromJson(parsedJson);
    } catch (e) {
      throw Exception(
          'Не удалось разобрать ответ Claude.\n'
          'Ошибка: $e\n\n'
          'Ответ (первые 500 символов): ${cleanedJson.substring(0, cleanedJson.length.clamp(0, 500))}');
    }
  }

  /// Extracts the JSON object from text that may contain extra content.
  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return text;
    return text.substring(start, end + 1);
  }
}
