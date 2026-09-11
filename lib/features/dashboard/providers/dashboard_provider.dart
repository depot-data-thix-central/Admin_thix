// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';

/// 🎯 État du dashboard
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

/// 🚀 Provider principal du dashboard
class DashboardNotifier extends StateNotifier<DashboardState> {
  final SupabaseClient _supabase;
  
  DashboardNotifier(this._supabase) : super(const DashboardState()) {
    // Chargement initial
    refresh();
  }

  /// 🔄 Rafraîchir toutes les statistiques
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

  /// 📊 Récupérer toutes les statistiques depuis Supabase
  Future<DashboardStats> _fetchStats() async {
    // 🔒 REQUÊTES PARALLÈLES OPTIMISÉES
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

  /// 👥 Compter les utilisateurs (avec RLS)
  Future<int> _countUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id', head: true); // 🔒 head: true pour COUNT uniquement
      
      return response.count ?? 0;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count users: $e');
      return 0;
    }
  }

  /// 📰 Compter les articles publiés
  Future<int> _countArticles() async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('id')
          .eq('status', 'published');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count articles: $e');
      return 0;
    }
  }

  /// 📝 Compter les posts du réseau social
  Future<int> _countPosts() async {
    try {
      final response = await _supabase
          .from('network_posts')
          .select('id')
          .eq('status', 'public');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count posts: $e');
      return 0;
    }
  }

  /// ⚠️ Compter les signalements en attente
  Future<int> _countPendingReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select('id')
          .eq('status', 'pending');
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count reports: $e');
      return 0;
    }
  }

  /// 📈 Nouveaux utilisateurs aujourd'hui
  Future<int> _countNewUsersToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final response = await _supabase
          .from('users')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String());
      
      return (response as List).length;
    } catch (e) {
      debugPrint('[Dashboard] Erreur count new users: $e');
      return 0;
    }
  }

  /// 📰 Nouveaux articles cette semaine
  Future<int> _countNewArticlesThisWeek() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final response = await _supabase
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

  /// 📝 Nouveaux posts cette semaine
  Future<int> _countNewPostsThisWeek() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final response = await _supabase
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

  /// 📊 Activité des 7 derniers jours
  Future<List<DailyActivity>> _fetchWeeklyActivity() async {
    try {
      final now = DateTime.now();
      final activities = <DailyActivity>[];

      // 🔒 Boucle sur les 7 derniers jours
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final usersCount = await _supabase
            .from('users')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String());

        final postsCount = await _supabase
            .from('network_posts')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String())
            .eq('status', 'public');

        final articlesCount = await _supabase
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

  /// ⚠️ Récupérer les alertes système
  Future<List<SystemAlert>> _fetchAlerts() async {
    try {
      final alerts = <SystemAlert>[];

      // 🔴 Signalements en attente
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

      // 🔵 Demandes de certification en attente
      try {
        final pendingCertifications = await _supabase
            .from('enterprise_certifications')
            .select('id')
            .eq('status', 'pending');
        
        final certCount = (pendingCertifications as List).length;
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

      // 🟡 Utilisateurs en attente de suppression
      try {
        final pendingDeletions = await _supabase
            .from('users')
            .select('id')
            .eq('status', 'pending_deletion');
        
        final deletionCount = (pendingDeletions as List).length;
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

  /// 🔒 Formatage sécurisé des erreurs
  String _formatError(dynamic error) {
    if (error is PostgrestException) {
      return 'Erreur base de données: ${error.message}';
    }
    if (error is AuthException) {
      return 'Erreur d\'authentification: ${error.message}';
    }
    return 'Une erreur inattendue s\'est produite';
  }
}

/// 🎯 Provider exposé
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final supabase = Supabase.instance.client;
  return DashboardNotifier(supabase);
});
