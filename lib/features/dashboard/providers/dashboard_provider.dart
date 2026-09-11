import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../supabase/supabase_config.dart';
import '../models/dashboard_stats.dart';

/// 🔐 État global du dashboard
@immutable
class DashboardState {
  final bool isLoading;
  final bool isRefreshing;
  final DashboardStats? stats;
  final String? error;
  final DateTime? lastRefresh;
  final int retryCount;

  const DashboardState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.stats,
    this.error,
    this.lastRefresh,
    this.retryCount = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    DashboardStats? stats,
    String? error,
    bool clearError = false,
    DateTime? lastRefresh,
    int? retryCount,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      stats: stats ?? this.stats,
      error: clearError ? null : (error ?? this.error),
      lastRefresh: lastRefresh ?? this.lastRefresh,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Indique si c'est le premier chargement (pas encore de données)
  bool get isFirstLoad => isLoading && stats == null;

  /// Indique un rafraîchissement (données déjà présentes)
  bool get isPullToRefresh => isRefreshing && stats != null;
}

/// 🎛️ Notifier du dashboard
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState()) {
    // Chargement initial différé de 100ms pour laisser le temps à Supabase
    Future.delayed(const Duration(milliseconds: 100), refresh);
  }

  /// 🔁 Rafraîchir toutes les données
  Future<void> refresh() async {
    if (state.isLoading || state.isRefreshing) return;

    final isRefresh = state.stats != null;
    state = state.copyWith(
      isLoading: !isRefresh,
      isRefreshing: isRefresh,
      clearError: true,
    );

    try {
      final stats = await _fetchAllStats();
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        stats: stats,
        lastRefresh: DateTime.now(),
        retryCount: 0,
      );
      _logInfo('✅ Dashboard rafraîchi');
    } catch (e, stack) {
      _logError('refresh', e, stack);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _formatError(e),
        stats: state.stats ?? DashboardStats.empty(),
        retryCount: state.retryCount + 1,
      );
    }
  }

  /// 📊 Collecte parallèle de toutes les stats
  Future<DashboardStats> _fetchAllStats() async {
    final results = await Future.wait([
      _safeCount('users', filters: null),
      _safeCount('news_articles', filters: {'status': 'published'}),
      _safeCount('network_posts', filters: {'status': 'public'}),
      _safeCount('reports', filters: {'status': 'pending'}),
      _countSince('users', _startOfDay()),
      _countSince('news_articles', _weekAgo(), extraFilters: {'status': 'published'}),
      _countSince('network_posts', _weekAgo(), extraFilters: {'status': 'public'}),
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

  /// 🛡️ Comptage sécurisé (retourne 0 en cas d'erreur)
  Future<int> _safeCount(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      final data = await SupabaseService.select(
        table,
        select: 'id',
        filters: filters,
      );
      return data.length;
    } catch (e) {
      _logError('_safeCount($table)', e, null);
      return 0;
    }
  }

  /// 📅 Comptage depuis une date donnée
  Future<int> _countSince(
    String table,
    DateTime since, {
    Map<String, dynamic>? extraFilters,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from(table)
          .select('id')
          .gte('created_at', since.toIso8601String());

      if (extraFilters != null) {
        for (final entry in extraFilters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      _logError('_countSince($table)', e, null);
      return 0;
    }
  }

  /// 📈 Activité des 7 derniers jours
  Future<List<DailyActivity>> _fetchWeeklyActivity() async {
    try {
      final now = DateTime.now();
      final activities = <DailyActivity>[];

      // Requêtes en parallèle pour chaque jour
      final futures = List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return _fetchDayActivity(date);
      });

      final results = await Future.wait(futures);
      activities.addAll(results);
      return activities;
    } catch (e) {
      _logError('_fetchWeeklyActivity', e, null);
      return _generateEmptyWeek();
    }
  }

  Future<DailyActivity> _fetchDayActivity(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final results = await Future.wait([
        _countInRange('users', start, end),
        _countInRange('network_posts', start, end, extraFilters: {'status': 'public'}),
        _countInRange('news_articles', start, end, extraFilters: {'status': 'published'}),
      ]);

      return DailyActivity(
        date: date,
        usersCount: results[0],
        postsCount: results[1],
        articlesCount: results[2],
      );
    } catch (e) {
      return DailyActivity(
        date: date,
        usersCount: 0,
        postsCount: 0,
        articlesCount: 0,
      );
    }
  }

  Future<int> _countInRange(
    String table,
    DateTime start,
    DateTime end, {
    Map<String, dynamic>? extraFilters,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from(table)
          .select('id')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      if (extraFilters != null) {
        for (final entry in extraFilters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// 🚨 Génération des alertes système
  Future<List<SystemAlert>> _fetchAlerts() async {
    final alerts = <SystemAlert>[];
    final now = DateTime.now();

    // 1. Signalements en attente
    final pendingReports = await _safeCount('reports', filters: {'status': 'pending'});
    if (pendingReports > 0) {
      alerts.add(SystemAlert(
        id: 'reports',
        type: 'report',
        title: 'Signalements non traités',
        message: '$pendingReports signalement${pendingReports > 1 ? 's' : ''} en attente de modération',
        count: pendingReports,
        createdAt: now,
        severity: pendingReports > 10 ? 'high' : (pendingReports > 5 ? 'medium' : 'low'),
      ));
    }

    // 2. Certifications en attente
    final pendingCerts = await _safeCount('enterprise_certifications', filters: {'status': 'pending'});
    if (pendingCerts > 0) {
      alerts.add(SystemAlert(
        id: 'certifications',
        type: 'certification',
        title: 'Certifications en attente',
        message: '$pendingCerts demande${pendingCerts > 1 ? 's' : ''} de certification à examiner',
        count: pendingCerts,
        createdAt: now,
        severity: 'medium',
      ));
    }

    // 3. Comptes en attente de suppression
    final pendingDeletions = await _safeCount('users', filters: {'status': 'pending_deletion'});
    if (pendingDeletions > 0) {
      alerts.add(SystemAlert(
        id: 'deletions',
        type: 'user_deletion',
        title: 'Suppressions programmées',
        message: '$pendingDeletions compte${pendingDeletions > 1 ? 's' : ''} en attente de suppression définitive',
        count: pendingDeletions,
        createdAt: now,
        severity: 'low',
      ));
    }

    // 4. Comptes suspendus
    final suspended = await _safeCount('users', filters: {'status': 'deactivated'});
    if (suspended > 0) {
      alerts.add(SystemAlert(
        id: 'suspended',
        type: 'suspended_users',
        title: 'Comptes suspendus',
        message: '$suspended compte${suspended > 1 ? 's' : ''} actuellement suspendu${suspended > 1 ? 's' : ''}',
        count: suspended,
        createdAt: now,
        severity: 'low',
      ));
    }

    // Tri : critiques d'abord
    alerts.sort((a, b) {
      const order = {'high': 0, 'medium': 1, 'low': 2};
      return (order[a.severity] ?? 3).compareTo(order[b.severity] ?? 3);
    });

    return alerts;
  }

  /// 📅 Helpers dates
  DateTime _startOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _weekAgo() => DateTime.now().subtract(const Duration(days: 7));

  List<DailyActivity> _generateEmptyWeek() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => DailyActivity(
        date: now.subtract(Duration(days: 6 - i)),
        usersCount: 0,
        postsCount: 0,
        articlesCount: 0,
      ),
    );
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Une erreur inattendue s\'est produite';
  }

  void _logError(String source, Object error, StackTrace? stack) {
    if (!kDebugMode) return;
    debugPrint('❌ [Dashboard/$source] $error');
    if (stack != null) debugPrint(stack.toString());
  }

  void _logInfo(String message) {
    if (!kDebugMode) return;
    debugPrint('ℹ️ [Dashboard] $message');
  }
}

/// 🎯 Provider Riverpod
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
