import 'package:flutter/foundation.dart';

/// 📊 Modèle des statistiques du dashboard
@immutable
class DashboardStats {
  final int totalUsers;
  final int totalArticles;
  final int totalPosts;
  final int pendingReports;
  final int newUsersToday;
  final int newArticlesThisWeek;
  final int newPostsThisWeek;
  final List<DailyActivity> weeklyActivity;
  final List<SystemAlert> alerts;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.totalUsers,
    required this.totalArticles,
    required this.totalPosts,
    required this.pendingReports,
    required this.newUsersToday,
    required this.newArticlesThisWeek,
    required this.newPostsThisWeek,
    required this.weeklyActivity,
    required this.alerts,
    required this.lastUpdated,
  });

  /// 🆓 Instance vide (pour initial state)
  factory DashboardStats.empty() => DashboardStats(
        totalUsers: 0,
        totalArticles: 0,
        totalPosts: 0,
        pendingReports: 0,
        newUsersToday: 0,
        newArticlesThisWeek: 0,
        newPostsThisWeek: 0,
        weeklyActivity: const [],
        alerts: const [],
        lastUpdated: DateTime.now(),
      );

  /// ✅ Indicateurs d'état
  bool get isEmpty =>
      totalUsers == 0 &&
      totalArticles == 0 &&
      totalPosts == 0;

  bool get hasAlerts => alerts.isNotEmpty;

  int get criticalAlertsCount =>
      alerts.where((a) => a.severity == 'high').length;
}

/// 📈 Activité quotidienne (pour le graphique)
@immutable
class DailyActivity {
  final DateTime date;
  final int usersCount;
  final int postsCount;
  final int articlesCount;

  const DailyActivity({
    required this.date,
    required this.usersCount,
    required this.postsCount,
    required this.articlesCount,
  });

  int get total => usersCount + postsCount + articlesCount;

  /// Label court (ex: "Lun 09")
  String get shortLabel {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return '${days[date.weekday % 7]} ${date.day.toString().padLeft(2, '0')}';
  }
}

/// 🚨 Alerte système
@immutable
class SystemAlert {
  final String id;
  final String type; // report, certification, user_deletion, system
  final String title;
  final String message;
  final int count;
  final DateTime createdAt;
  final String severity; // low, medium, high

  const SystemAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.count,
    required this.createdAt,
    required this.severity,
  });

  bool get isCritical => severity == 'high';
  bool get isWarning => severity == 'medium';

  /// Temps relatif (ex: "Il y a 2h")
  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return 'Il y a plus d\'une semaine';
  }
}
