import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../models/security_event.dart';
import '../services/error_analyzer.dart';

/// 🔬 Page d'analyse détaillée d'une erreur applicative
class ErrorDetailPage extends StatelessWidget {
  final AggregatedError error;
  final List<SecurityEvent> occurrences;

  const ErrorDetailPage({
    super.key,
    required this.error,
    required this.occurrences,
  });

  @override
  Widget build(BuildContext context) {
    final insight = ErrorAnalyzer.analyze(error.message);
    final color = ErrorAnalyzer.color(insight.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text('Analyse d\'erreur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copier le rapport',
            onPressed: () => _copyReport(context, insight),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── En-tête catégorie ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(ErrorAnalyzer.icon(insight.category),
                      size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ErrorAnalyzer.label(insight.category),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: color)),
                      const SizedBox(height: 2),
                      Text(
                          'Confiance de l\'analyse : ${(insight.confidence * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                _stat('${error.count}x', 'occurrences'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Message complet ──
          _section('💬 Message complet'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101840),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              error.message,
              style: const TextStyle(
                color: Colors.white87,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── URL en cause ──
          if (insight.failingUrl != null) ...[
            _section('🔗 URL en cause'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(insight.failingUrl!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.info)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: insight.failingUrl!)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Localisation probable ──
          _section('📍 Localisation probable'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.zone,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(insight.explanation,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Recommandations ──
          _section('🧭 Recommandations correctives'),
          const SizedBox(height: 8),
          for (int i = 0; i < insight.recommendations.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(insight.recommendations[i],
                        style: const TextStyle(fontSize: 12.5, height: 1.45)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── Occurrences ──
          _section('🕐 Historique des occurrences (${occurrences.length})'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _kv('Première', _fmt(occurrences.last.createdAt)),
                _kv('Dernière', _fmt(occurrences.first.createdAt)),
                _kv('Sources', occurrences
                    .map((e) => e.source == 'mobile_app' ? '📱 APP' : '🖥️ ADMIN')
                    .toSet()
                    .join(', ')),
                _kv('IP distinctes', occurrences
                    .map((e) => e.ipAddress ?? '?')
                    .toSet()
                    .length
                    .toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Text(t,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));

  Widget _stat(String v, String l) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF101840))),
          Text(l, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(k,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700))),
          ],
        ),
      );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      'à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _copyReport(BuildContext context, ErrorInsight insight) {
    final report = StringBuffer()
      ..writeln('═══ RAPPORT D\'ERREUR THIX ═══')
      ..writeln('Catégorie : ${ErrorAnalyzer.label(insight.category)}')
      ..writeln('Occurrences : ${error.count}')
      ..writeln('Dernière : ${_fmt(error.lastOccurrence)}')
      ..writeln()
      ..writeln('MESSAGE :')
      ..writeln(error.message)
      ..writeln()
      ..writeln('LOCALISATION PROBABLE :')
      ..writeln(insight.zone)
      ..writeln()
      ..writeln('RECOMMANDATIONS :');
    for (int i = 0; i < insight.recommendations.length; i++) {
      report.writeln('${i + 1}. ${insight.recommendations[i]}');
    }
    Clipboard.setData(ClipboardData(text: report.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📋 Rapport copié dans le presse-papier'),
        backgroundColor: AppColors.success));
  }
}
