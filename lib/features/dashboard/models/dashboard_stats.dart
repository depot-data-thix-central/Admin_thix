// lib/features/dashboard/models/dashboard_stats.dart
import 'package:flutter/foundation.dart';

/// 📊 Modèle de statistiques du dashboard admin
/// Ce modèle est IMMUTABLE et VALIDÉ pour éviter les injections
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

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      totalArticles: 0,
      totalPosts: 0,
      pendingReports: 0,
      newUsersToday: 0,
      newArticlesThisWeek: 0,
      newPostsThisWeek: 0,
      weeklyActivity: [],
      alerts: [],
      lastUpdated: DateTime.now(),
    );
  }

  factory DashboardStats.fromSupabase(Map<String, dynamic> json) {
    // 🔒 VALIDATION ROBUSTE : Protection contre les types invalides
    int safeInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    List<DailyActivity> parseActivity(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      
      return value
          .whereType<Map>()
          .map((e) => DailyActivity.fromSupabase(e.cast<String, dynamic>()))
          .toList();
    }

    List<SystemAlert> parseAlerts(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      
      return value
          .whereType<Map>()
          .map((e) => SystemAlert.fromSupabase(e.cast<String, dynamic>()))
          .toList();
    }

    return DashboardStats(
      totalUsers: safeInt(json['total_users']),
      totalArticles: safeInt(json['total_articles']),
      totalPosts: safeInt(json['total_posts']),
      pendingReports: safeInt(json['pending_reports']),
      newUsersToday: safeInt(json['new_users_today']),
      newArticlesThisWeek: safeInt(json['new_articles_week']),
      newPostsThisWeek: safeInt(json['new_posts_week']),
      weeklyActivity: parseActivity(json['weekly_activity']),
      alerts: parseAlerts(json['alerts']),
      lastUpdated: DateTime.now(),
    );
  }

  /// 🔒 Sérialisation sécurisée pour le cache
  Map<String, dynamic> toCache() {
    return {
      'total_users': totalUsers,
      'total_articles': totalArticles,
      'total_posts': totalPosts,
      'pending_reports': pendingReports,
      'new_users_today': newUsersToday,
      'new_articles_week': newArticlesThisWeek,
      'new_posts_week': newPostsThisWeek,
      'weekly_activity': weeklyActivity.map((e) => e.toCache()).toList(),
      'alerts': alerts.map((e) => e.toCache()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

/// 📈 Activité quotidienne
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

  factory DailyActivity.fromSupabase(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    int safeInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    return DailyActivity(
      date: parseDate(json['date']),
      usersCount: safeInt(json['users_count']),
      postsCount: safeInt(json['posts_count']),
      articlesCount: safeInt(json['articles_count']),
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'date': date.toIso8601String(),
      'users_count': usersCount,
      'posts_count': postsCount,
      'articles_count': articlesCount,
    };
  }
}

/// ⚠️ Alerte système
@immutable
class SystemAlert {
  final String id;
  final String type; // 'report', 'certification', 'user_deletion'
  final String title;
  final String? message;
  final int count;
  final DateTime createdAt;
  final String severity; // 'low', 'medium', 'high', 'critical'

  const SystemAlert({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    required this.count,
    required this.createdAt,
    required this.severity,
  });

  factory SystemAlert.fromSupabase(Map<String, dynamic> json) {
    String safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    int safeInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return SystemAlert(
      id: safeString(json['id'], defaultValue: DateTime.now().millisecondsSinceEpoch.toString()),
      type: safeString(json['type'], defaultValue: 'unknown'),
      title: safeString(json['title'], defaultValue: 'Alerte inconnue'),
      message: json['message']?.toString(),
      count: safeInt(json['count'], defaultValue: 1),
      createdAt: parseDate(json['created_at']),
      severity: safeString(json['severity'], defaultValue: 'low'),
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'count': count,
      'created_at': createdAt.toIso8601String(),
      'severity': severity,
    };
  }

  /// 🔒 Validation du type d'alerte
  bool get isValidType {
    const validTypes = ['report', 'certification', 'user_deletion', 'system'];
    return validTypes.contains(type);
  }
}
