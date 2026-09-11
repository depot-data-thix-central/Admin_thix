// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
// ✅ Import de votre service
import 'package:thix_admin/supabase/supabase_config.dart';
import '../models/dashboard_stats.dart';

@immutable
class DashboardState {
  final bool isLoading;
  final DashboardStats? stats;
  final String? error;
  final DateTime? lastRefresh;

  const DashboardState({
    this.isLoading = false,
    this.stats,
    this.error,
    this.lastRefresh,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    String? error,
    DateTime? lastRefresh,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState()) {
    refresh();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _fetchStats();
      state = state.copyWith(
        isLoading: false,
        stats: stats,
        lastRefresh: DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('[DashboardProvider] Erreur: $e');
      debugPrintStack(stackTrace: stack);
      
      state = state.copyWith(
        isLoading: false,
        error: _formatError(e),
        stats: state.stats ?? DashboardStats.empty(),
      );
    }
  }

  Future<DashboardStats> _fetchStats() async {
    final results = await Future.wait([
      _countUsers(),
      _countArticles(),
      _countPosts(),
      _countPendingReports(),
      _countNewUsersToday(),
      _countNewArticlesThisWeek(),
      _countNewPostsThisWeek(),
      _fetchWeeklyActivity(),
      _fetchAlerts(),
    ]);

    return DashboardStats(
      totalUsers: results[0] as int,
      totalArticles: results[1] as int,
      totalPosts: results[2] as int,
      pendingReports: results[3] as int,
      newUsersToday: results[4] as int,
      newArticlesThisWeek: results[5] as int,
      newPostsThisWeek: results[6] as int,
      weeklyActivity: results[7] as List<DailyActivity>,
      alerts: results[8] as List<SystemAlert>,
      lastUpdated: DateTime.now(),
    );
  }

  // ✅ Utilisation de SupabaseService
  Future<int> _countUsers() async {
    try {
      final users = await SupabaseService.select('users', select: 'id');
      return users.length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count users: $e');
      return 0;
    }
  }

  Future<int> _countArticles() async {
    try {
      final articles = await SupabaseService.select(
        'news_articles',
        select: 'id',
        filters: {'status': 'published'},
      );
      return articles.length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count articles: $e');
      return 0;
    }
  }

  Future<int> _countPosts() async {
    try {
      final posts = await SupabaseService.select(
        'network_posts',
        select: 'id',
        filters: {'status': 'public'},
      );
      return posts.length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count posts: $e');
      return 0;
    }
  }

  Future<int> _countPendingReports() async {
    try {
      final reports = await SupabaseService.select(
        'reports',
        select: 'id',
        filters: {'status': 'pending'},
      );
      return reports.length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count reports: $e');
      return 0;
    }
  }

  Future<int> _countNewUsersToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      // Utilisation directe du client pour les requêtes complexes
      final response = await SupabaseConfig.client
          .from('users')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String());
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count new users: $e');
      return 0;
    }
  }

  Future<int> _countNewArticlesThisWeek() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final response = await SupabaseConfig.client
          .from('news_articles')
          .select('id')
          .gte('created_at', weekAgo.toIso8601String())
          .eq('status', 'published');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count new articles: $e');
      return 0;
    }
  }

  Future<int> _countNewPostsThisWeek() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final response = await SupabaseConfig.client
          .from('network_posts')
          .select('id')
          .gte('created_at', weekAgo.toIso8601String())
          .eq('status', 'public');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count new posts: $e');
      return 0;
    }
  }

  Future<List<DailyActivity>> _fetchWeeklyActivity() async {
    try {
      final now = DateTime.now();
      final activities = <DailyActivity>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final usersCount = await SupabaseConfig.client
            .from('users')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String());

        final postsCount = await SupabaseConfig.client
            .from('network_posts')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String())
            .eq('status', 'public');

        final articlesCount = await SupabaseConfig.client
            .from('news_articles')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String())
            .eq('status', 'published');

        activities.add(DailyActivity(
          date: date,
          usersCount: (usersCount as List).length,
          postsCount: (postsCount as List).length,
          articlesCount: (articlesCount as List).length,
        ));
      }

      return activities;
    } catch (e) {
      debugPrint('[Dashboard] Erreur fetch activity: $e');
      return [];
    }
  }

  Future<List<SystemAlert>> _fetchAlerts() async {
    try {
      final alerts = <SystemAlert>[];

      // Signalements en attente
      final pendingReports = await _countPendingReports();
      if (pendingReports > 0) {
        alerts.add(SystemAlert(
          id: 'reports_${DateTime.now().millisecondsSinceEpoch}',
          type: 'report',
          title: 'Signalements non traités',
          message: '$pendingReports signalements en attente de modération',
          count: pendingReports,
          createdAt: DateTime.now(),
          severity: pendingReports > 10 ? 'high' : 'medium',
        ));
      }

      // Demandes de certification en attente
      try {
        final pendingCertifications = await SupabaseService.select(
          'enterprise_certifications',
          select: 'id',
          filters: {'status': 'pending'},
        );
        
        final certCount = pendingCertifications.length;
        if (certCount > 0) {
          alerts.add(SystemAlert(
            id: 'certifications_${DateTime.now().millisecondsSinceEpoch}',
            type: 'certification',
            title: 'Certifications en attente',
            message: '$certCount demandes de certification à examiner',
            count: certCount,
            createdAt: DateTime.now(),
            severity: 'medium',
          ));
        }
      } catch (e) {
        debugPrint('[Dashboard] Erreur certifications: $e');
      }

      // Utilisateurs en attente de suppression
      try {
        final pendingDeletions = await SupabaseService.select(
          'users',
          select: 'id',
          filters: {'status': 'pending_deletion'},
        );
        
        final deletionCount = pendingDeletions.length;
        if (deletionCount > 0) {
          alerts.add(SystemAlert(
            id: 'deletions_${DateTime.now().millisecondsSinceEpoch}',
            type: 'user_deletion',
            title: 'Suppressions programmées',
            message: '$deletionCount comptes en attente de suppression',
            count: deletionCount,
            createdAt: DateTime.now(),
            severity: 'low',
          ));
        }
      } catch (e) {
        debugPrint('[Dashboard] Erreur deletions: $e');
      }

      return alerts;
    } catch (e) {
      debugPrint('[Dashboard] Erreur fetch alerts: $e');
      return [];
    }
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Une erreur inattendue s\'est produite';
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
