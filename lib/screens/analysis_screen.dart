import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/legal_case.dart';

class AnalysisScreen extends StatelessWidget {
  final LegalCase legalCase;

  const AnalysisScreen({super.key, required this.legalCase});

  @override
  Widget build(BuildContext context) {
    final hasViolations = legalCase.violations.hasViolations;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Результаты анализа',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              Text(
                legalCase.documentInfo.documentTypeDisplay,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          actions: [
            // Violation badge in AppBar
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasViolations ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasViolations
                        ? '${legalCase.violations.allViolations.length} нарушений'
                        : 'Нарушений нет',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Документ'),
              Tab(
                  icon: Icon(Icons.warning_amber, size: 18),
                  text: 'Нарушения'),
              Tab(icon: Icon(Icons.balance, size: 18), text: 'Анализ'),
              Tab(icon: Icon(Icons.description, size: 18), text: 'Возражение'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DocumentTab(info: legalCase.documentInfo),
            _ViolationsTab(violations: legalCase.violations),
            _AnalysisTab(
              analysis: legalCase.legalAnalysis,
              strategy: legalCase.recommendedStrategy,
            ),
            _ObjectionTab(objection: legalCase.objectionDraft),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── TAB 1: Document Info ──────────────────────

class _DocumentTab extends StatelessWidget {
  final DocumentInfo info;
  const _DocumentTab({required this.info});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabHeader(
            icon: Icons.article,
            title: 'Информация о документе',
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Тип',
                    value: info.documentTypeDisplay,
                    icon: Icons.description,
                  ),
                  _InfoRow(
                    label: 'Должник',
                    value: _orNone(info.debtor),
                    icon: Icons.person,
                  ),
                  _InfoRow(
                    label: 'Взыскатель',
                    value: _orNone(info.creditor),
                    icon: Icons.business,
                  ),
                  _InfoRow(
                    label: 'Дата',
                    value: _orNone(info.date),
                    icon: Icons.calendar_today,
                  ),
                  _InfoRow(
                    label: 'Сумма',
                    value: _orNone(info.amount),
                    icon: Icons.attach_money,
                    isLast: info.notary.isEmpty && info.caseNumber.isEmpty,
                  ),
                  if (info.notary.isNotEmpty)
                    _InfoRow(
                      label: 'Нотариус',
                      value: info.notary,
                      icon: Icons.draw,
                      isLast: info.caseNumber.isEmpty,
                    ),
                  if (info.caseNumber.isNotEmpty)
                    _InfoRow(
                      label: 'Номер дела',
                      value: info.caseNumber,
                      icon: Icons.tag,
                      isLast: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _orNone(String v) => v.isEmpty ? 'Не указано' : v;
}

// ─────────────────────────────── TAB 2: Violations ─────────────────────────

class _ViolationsTab extends StatelessWidget {
  final ViolationAnalysis violations;
  const _ViolationsTab({required this.violations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBanner(hasViolations: violations.hasViolations),
          const SizedBox(height: 16),
          _ViolationGroup(
            title: 'Уведомление должника',
            subtitle: 'Ст. 26 Закона об исполнительном производстве РК',
            icon: Icons.notifications_off,
            color: Colors.orange,
            violations: violations.notificationViolations,
          ),
          const SizedBox(height: 12),
          _ViolationGroup(
            title: 'Срок исковой давности',
            subtitle: 'Ст. 178 Гражданского кодекса РК — 3 года',
            icon: Icons.timer_off,
            color: Colors.red,
            violations: violations.limitationPeriodViolations,
          ),
          const SizedBox(height: 12),
          _ViolationGroup(
            title: 'Процессуальные нарушения',
            subtitle: 'Нарушения порядка оформления документа',
            icon: Icons.rule,
            color: Colors.purple,
            violations: violations.proceduralViolations,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── TAB 3: Analysis ───────────────────────────

class _AnalysisTab extends StatelessWidget {
  final String analysis;
  final String strategy;

  const _AnalysisTab({required this.analysis, required this.strategy});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabHeader(icon: Icons.balance, title: 'Правовой анализ'),
          const SizedBox(height: 12),
          _ContentBox(
            text: analysis.isEmpty ? 'Анализ не был сгенерирован.' : analysis,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          _TabHeader(
              icon: Icons.lightbulb, title: 'Рекомендуемая стратегия'),
          const SizedBox(height: 12),
          _ContentBox(
            text: strategy.isEmpty
                ? 'Стратегия не была сгенерирована.'
                : strategy,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── TAB 4: Objection ──────────────────────────

class _ObjectionTab extends StatefulWidget {
  final String objection;
  const _ObjectionTab({required this.objection});

  @override
  State<_ObjectionTab> createState() => _ObjectionTabState();
}

class _ObjectionTabState extends State<_ObjectionTab> {
  bool _saving = false;

  Future<void> _saveToFile() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/vozrazhenie_$ts.txt');
      await file.writeAsString(widget.objection);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сохранено: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (_) {
      // Fallback: clipboard
      await Clipboard.setData(ClipboardData(text: widget.objection));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Файл не удалось сохранить — текст скопирован'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.objection));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Текст скопирован в буфер обмена'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TabHeader(
                  icon: Icons.description,
                  title: 'Проект возражения / жалобы',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Готовый документ для подачи в суд, прокуратуру '
                  'или нотариальную палату.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    widget.objection.isEmpty
                        ? 'Документ не был сгенерирован.'
                        : widget.objection,
                    style: const TextStyle(
                      height: 1.8,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копировать'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1A237E)),
                    foregroundColor: const Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveToFile,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: Text(_saving ? 'Сохранение...' : 'Скачать TXT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Shared Widgets ─────────────────────────────

class _TabHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _TabHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A237E)),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool hasViolations;
  const _StatusBanner({required this.hasViolations});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasViolations ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasViolations ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasViolations ? Icons.gpp_bad : Icons.verified_user,
            color: hasViolations ? Colors.red : Colors.green,
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasViolations
                      ? 'Обнаружены правовые нарушения'
                      : 'Существенных нарушений не выявлено',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: hasViolations ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasViolations
                      ? 'Документ может быть оспорен — перейдите на вкладку "Возражение"'
                      : 'Документ соответствует требованиям законодательства РК',
                  style: TextStyle(
                    color:
                        hasViolations ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViolationGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> violations;

  const _ViolationGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.violations,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = violations.isEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: color)),
                      Text(subtitle,
                          style: TextStyle(
                              color: color.withOpacity(0.7), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEmpty ? Colors.green : color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isEmpty ? '✓ Норм' : '${violations.length} нар.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Body
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < violations.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(
                            violations[i],
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Нарушений данного типа не обнаружено',
                style: TextStyle(
                    color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContentBox extends StatelessWidget {
  final String text;
  final Color color;

  const _ContentBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(height: 1.7, fontSize: 14),
      ),
    );
  }
}
