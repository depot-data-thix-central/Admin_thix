// lib/features/dashboard/widgets/activity_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_stats.dart';

/// 📈 Graphique d'activité des 7 derniers jours
class ActivityChart extends StatelessWidget {
  final List<DailyActivity> activities;

  const ActivityChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 🔒 Trouver la valeur max pour normalisation
    final maxValue = activities.fold<int>(
      0,
      (max, activity) {
        final total = activity.usersCount + activity.postsCount + activity.articlesCount;
        return total > max ? total : max;
      },
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité des 7 derniers jours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101840),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisateurs, posts et articles publiés',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: activities.asMap().entries.map((entry) {
                final activity = entry.value;
                final total = activity.usersCount + activity.postsCount + activity.articlesCount;
                final height = maxValue > 0 ? (total / maxValue) * 180 : 0.0;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip au survol (pour web)
                        MouseRegion(
                          child: Tooltip(
                            message: _formatTooltip(activity),
                            child: Container(
                              height: height.clamp(4.0, 180.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    const Color(0xFFFFB800),
                                    const Color(0xFFFFD700),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEE').format(activity.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTooltip(DailyActivity activity) {
    return '${DateFormat('d MMM').format(activity.date)}\n'
        'Utilisateurs: ${activity.usersCount}\n'
        'Posts: ${activity.postsCount}\n'
        'Articles: ${activity.articlesCount}';
  }
}
