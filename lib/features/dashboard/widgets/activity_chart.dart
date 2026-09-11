import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/dashboard_stats.dart';

/// 📈 Graphique d'activité des 7 derniers jours (custom paint, pas de dépendance externe)
class ActivityChart extends StatelessWidget {
  final List<DailyActivity> activities;

  const ActivityChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activité des 7 derniers jours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101840),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Évolution quotidienne des créations',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _buildLegend(),
            ],
          ),

          const SizedBox(height: 24),

          // ── Graphique ──
          SizedBox(
            height: 220,
            child: activities.isEmpty
                ? const _EmptyChart()
                : _ChartBody(activities: activities),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendDot(color: AppColors.primary, label: 'Users'),
        SizedBox(width: 12),
        _LegendDot(color: Color(0xFF8B5CF6), label: 'Posts'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.enterprise, label: 'Articles'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Aucune activité enregistrée',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  final List<DailyActivity> activities;

  const _ChartBody({required this.activities});

  @override
  Widget build(BuildContext context) {
    // Calcul du max pour normaliser
    int maxVal = 1;
    for (final a in activities) {
      maxVal = math.max(maxVal, a.usersCount);
      maxVal = math.max(maxVal, a.postsCount);
      maxVal = math.max(maxVal, a.articlesCount);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // ── Grille + barres ──
            Expanded(
              child: Stack(
                children: [
                  // Grille horizontale
                  _buildGrid(),
                  // Barres
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ChartPainter(
                      activities: activities,
                      maxValue: maxVal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Labels jours ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: activities
                  .map((a) => SizedBox(
                        width: constraints.maxWidth / activities.length,
                        child: Center(
                          child: Text(
                            a.shortLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        4,
        (i) => Container(
          height: 1,
          color: const Color(0xFFF3F4F6),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<DailyActivity> activities;
  final int maxValue;

  _ChartPainter({required this.activities, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (activities.isEmpty) return;

    final barGroupWidth = size.width / activities.length;
    final barWidth = (barGroupWidth - 16) / 3;
    final chartHeight = size.height - 8;

    for (int i = 0; i < activities.length; i++) {
      final a = activities[i];
      final x = i * barGroupWidth + 8;

      // Barre users
      _drawBar(
        canvas,
        x,
        a.usersCount,
        barWidth,
        chartHeight,
        AppColors.primary,
      );

      // Barre posts
      _drawBar(
        canvas,
        x + barWidth + 2,
        a.postsCount,
        barWidth,
        chartHeight,
        const Color(0xFF8B5CF6),
      );

      // Barre articles
      _drawBar(
        canvas,
        x + (barWidth + 2) * 2,
        a.articlesCount,
        barWidth,
        chartHeight,
        AppColors.enterprise,
      );
    }
  }

  void _drawBar(
    Canvas canvas,
    double x,
    int value,
    double width,
    double maxHeight,
    Color color,
  ) {
    if (value == 0) {
      // Barre minimum de 2px pour indiquer la présence
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, maxHeight - 2, width, 2),
        const Radius.circular(1),
      );
      canvas.drawRRect(rect, Paint()..color = color.withOpacity(0.2));
      return;
    }

    final height = (value / maxValue) * maxHeight;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, maxHeight - height, width, height),
      const Radius.circular(3),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect.outerRect);

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.activities != activities || oldDelegate.maxValue != maxValue;
  }
}
