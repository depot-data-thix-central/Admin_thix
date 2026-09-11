import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/security_event.dart';

/// 📦 État
@immutable
class SecurityState {
  final List<SecurityEvent> events;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;
  final String? filterSeverity;
  final String? filterType;
  final String? filterSource; // ⬅️ AJOUT : mobile_app | admin_web | null
  final String search;

  const SecurityState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.lastRefresh,
    this.filterSeverity,
    this.filterType,
    this.filterSource, // ⬅️ AJOUT
    this.search = '',
  });

  SecurityState copyWith({
    List<SecurityEvent>? events,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastRefresh,
    String? filterSeverity,
    bool clearSeverity = false,
    String? filterType,
    bool clearType = false,
    String? filterSource, // ⬅️ AJOUT
    bool clearSource = false, // ⬅️ AJOUT
    String? search,
  }) {
    return SecurityState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastRefresh: lastRefresh ?? this.lastRefresh,
      filterSeverity: clearSeverity ? null : (filterSeverity ?? this.filterSeverity),
      filterType: clearType ? null : (filterType ?? this.filterType),
      filterSource: clearSource ? null : (filterSource ?? this.filterSource), // ⬅️ AJOUT
      search: search ?? this.search,
    );
  }
}

/// 🎛️ Notifier monitoring sécurité
class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(const SecurityState()) {
    Future.delayed(const Duration(milliseconds: 150), () {
      refresh();
      loadProfileSignals(); // ⬅️ AJOUT : charger les signaux profils
    });
  }

  static const String kTable = 'security_events';
  static const int kBruteForceThreshold = 5; // ≥ 5 échecs / 24 h = menace
  static const String kSourceMobile = 'mobile_app'; // ⬅️ AJOUT
  static const String kSourceAdmin = 'admin_web'; // ⬅️ AJOUT

  // ─── CHARGEMENT (7 derniers jours, max 1000) ───
  Future<void> refresh({bool silent = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final res = await SupabaseConfig.client
          .from(kTable)
          .select('*')
          .gte('created_at', cutoff.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1000);

      final events = (res as List)
          .map((e) => SecurityEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(
        isLoading: false,
        events: events,
        lastRefresh: DateTime.now(),
      );
    } catch (e, st) {
      _log('refresh', e, st);
      state = state.copyWith(isLoading: false, error: _fmt(e));
    }
  }

  void setFilters({String? severity, String? type, String? search}) {
    state = state.copyWith(
      filterSeverity: severity,
      clearSeverity: severity == null,
      filterType: type,
      clearType: type == null,
      search: search,
    );
  }

  // ⬇️ AJOUT : filtre par source
  void setSourceFilter(String? source) {
    state = state.copyWith(filterSource: source, clearSource: source == null);
  }

  // ═══════════════════════════════════════════════════════════════
  // 📊 STATISTIQUES CALCULÉES
  // ═══════════════════════════════════════════════════════════════

  int _countSince(Duration window, {String? type, bool criticalOnly = false}) {
    final cutoff = DateTime.now().subtract(window);
    return state.events
        .where((e) => e.createdAt.isAfter(cutoff))
        .where((e) => type == null || e.eventType == type)
        .where((e) => !criticalOnly || e.isCritical)
        .length;
  }

  int get loginFailed24h =>
      _countSince(const Duration(hours: 24), type: SecurityEventType.loginFailed);

  int get clientErrors24h =>
      _countSince(const Duration(hours: 24), type: SecurityEventType.clientError);

  int get critical7d => _countSince(const Duration(days: 7), criticalOnly: true);

  // ─── 📱 ÉVÉNEMENTS PAR SOURCE (24 h) ───
  int get mobileEvents24h => _countSinceSource(
        const Duration(hours: 24),
        source: kSourceMobile,
      );

  int get adminEvents24h => _countSinceSource(
        const Duration(hours: 24),
        source: kSourceAdmin,
      );

  int _countSinceSource(Duration window, {required String source}) {
    final cutoff = DateTime.now().subtract(window);
    return state.events
        .where((e) => e.createdAt.isAfter(cutoff))
        .where((e) => e.source == source)
        .length;
  }

  // ─── 🔑 DÉTECTION BRUTE FORCE ───
  List<BruteForceThreat> get bruteForceThreats {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final grouped = <String, List<SecurityEvent>>{};

    for (final e in state.events) {
      if (e.eventType != SecurityEventType.loginFailed) continue;
      if (e.createdAt.isBefore(cutoff)) continue;
      final key = (e.identifier ?? e.userId ?? 'inconnu').toLowerCase();
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final threats = grouped.entries
        .where((entry) => entry.value.length >= kBruteForceThreshold)
        .map((entry) {
          final ips = entry.value
              .map((e) => e.ipAddress ?? '?')
              .toSet();
          final last = entry.value
              .map((e) => e.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          return BruteForceThreat(
            identifier: entry.key,
            attempts: entry.value.length,
            lastAttempt: last,
            ipAddresses: ips,
          );
        }).toList();

    threats.sort((a, b) => b.attempts.compareTo(a.attempts));
    return threats;
  }

  // ─── 🐛 TOP ERREURS AGRÉGÉES ───
  List<AggregatedError> get topErrors {
    final grouped = <String, List<SecurityEvent>>{};
    for (final e in state.events) {
      if (e.eventType != SecurityEventType.clientError) continue;
      final key = e.message.length > 90 ? e.message.substring(0, 90) : e.message;
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final list = grouped.entries.map((entry) {
      final last = entry.value
          .map((e) => e.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return AggregatedError(
        message: entry.key,
        count: entry.value.length,
        lastOccurrence: last,
      );
    }).toList();

    list.sort((a, b) => b.count.compareTo(a.count));
    return list.take(5).toList();
  }

  // ─── 📱 SIGNAUX APPLICATIFS (mobile + profils) ───
  AppSignals get appSignals => AppSignals(
        mobileEvents24h: mobileEvents24h,
        mobileLoginFailures24h: state.events
            .where((e) => e.source == kSourceMobile)
            .where((e) => e.eventType == SecurityEventType.loginFailed)
            .where((e) => e.createdAt.isAfter(
                DateTime.now().subtract(const Duration(hours: 24))))
            .length,
        mobileErrors24h: state.events
            .where((e) => e.source == kSourceMobile)
            .where((e) => e.eventType == SecurityEventType.clientError)
            .where((e) => e.createdAt.isAfter(
                DateTime.now().subtract(const Duration(hours: 24))))
            .length,
        newAccounts24h: _profileSignals.newAccounts24h,
        suspended: _profileSignals.suspended,
        pendingDeletion: _profileSignals.pendingDeletion,
      );

  ProfileSignals _profileSignals = const ProfileSignals();

  /// 📡 Chargement des signaux profils (table profiles)
  Future<void> loadProfileSignals() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final results = await Future.wait([
        _countProfiles(gteCreated: cutoff),
        _countProfiles(eq: {'account_status': 'deactivated'}),
        _countProfiles(eq: {'status': 'pending_deletion'}),
      ]);
      _profileSignals = ProfileSignals(
        newAccounts24h: results[0],
        suspended: results[1],
        pendingDeletion: results[2],
      );
      state = state.copyWith(); // notifie
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Security] signaux profils : $e');
    }
  }

  // ✅ CORRECTION APPLIQUÉE ICI
  Future<int> _countProfiles({
    DateTime? gteCreated,
    Map<String, String>? eq,
  }) async {
    var query = SupabaseConfig.client
        .from('profiles')
        .select('id'); // ⬅️ On retire le CountOption.exact d'ici
        
    if (gteCreated != null) {
      query = query.gte('created_at', gteCreated.toIso8601String());
    }
    if (eq != null) {
      for (final e in eq.entries) {
        query = query.eq(e.key, e.value);
      }
    }
    
    // ⬅️ On l'ajoute ici à la fin
    final res = await query.count(CountOption.exact);
    return res.count ?? 0;
  }

  // ───  LISTE FILTRÉE ───
  List<SecurityEvent> get filteredEvents {
    var list = state.events;
    final f = state;
    if (f.filterSeverity != null) {
      list = list.where((e) => e.severity == f.filterSeverity).toList();
    }
    if (f.filterType != null) {
      list = list.where((e) => e.eventType == f.filterType).toList();
    }
    if (f.filterSource != null) { // ⬅️ AJOUT
      list = list.where((e) => e.source == f.filterSource).toList();
    }
    if (f.search.trim().isNotEmpty) {
      final s = f.search.toLowerCase();
      list = list
          .where((e) =>
              (e.identifier ?? '').toLowerCase().contains(s) ||
              (e.ipAddress ?? '').toLowerCase().contains(s) ||
              e.message.toLowerCase().contains(s))
          .toList();
    }
    return list;
  }

  String _fmt(dynamic e) {
    if (e is PostgrestException) return e.message;
    return 'Erreur : $e';
  }

  void _log(String src, Object e, StackTrace? st) {
    if (!kDebugMode) return;
    debugPrint('❌ [Security/$src] $e');
  }
}

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier();
});

// ═══════════════════════════════════════════════════════════════
// 📊 MODÈLES DE SIGNAUX
// ═══════════════════════════════════════════════════════════════

@immutable
class ProfileSignals {
  final int newAccounts24h;
  final int suspended;
  final int pendingDeletion;
  const ProfileSignals({
    this.newAccounts24h = 0,
    this.suspended = 0,
    this.pendingDeletion = 0,
  });
}

@immutable
class AppSignals {
  final int mobileEvents24h;
  final int mobileLoginFailures24h;
  final int mobileErrors24h;
  final int newAccounts24h;
  final int suspended;
  final int pendingDeletion;
  const AppSignals({
    this.mobileEvents24h = 0,
    this.mobileLoginFailures24h = 0,
    this.mobileErrors24h = 0,
    this.newAccounts24h = 0,
    this.suspended = 0,
    this.pendingDeletion = 0,
  });
}

// ═══════════════════════════════════════════════════════════════
// 📡 REPORTER — appelé par login, crashs, actions admin
// ═══════════════════════════════════════════════════════════════
class SecurityReporter {
  SecurityReporter._();

  static DateTime? _lastClientError;
  static bool _sending = false;

  /// 🔑 Échec de login (appelé depuis AdminLoginPage)
  static void reportLoginFailure({
    required String identifier,
    required String reason,
  }) {
    _send(
      eventType: SecurityEventType.loginFailed,
      severity: SecuritySeverity.medium,
      identifier: identifier,
      message: 'Échec de connexion : $reason',
    );
  }

  /// 🐛 Erreur applicative (throttlée : max 1 / 10 s)
  static void reportClientError({
    required String source,
    required String message,
  }) {
    final now = DateTime.now();
    if (_lastClientError != null &&
        now.difference(_lastClientError!).inSeconds < 10) {
      return;
    }
    _lastClientError = now;
    _send(
      eventType: SecurityEventType.clientError,
      severity: SecuritySeverity.medium,
      identifier: source,
      message: message.length > 480 ? message.substring(0, 480) : message,
    );
  }

  /// 🕵️ Action admin sensible (suspension, réactivation…)
  static void reportAdminAction({
    required String action,
    String? targetId,
    String? details,
  }) {
    _send(
      eventType: SecurityEventType.adminAction,
      severity: SecuritySeverity.low,
      identifier: action,
      message: details ?? 'Action admin : $action',
      metadata: {'target_id': targetId},
    );
  }

  /// 🚨 Activité suspecte manuelle
  static void reportSuspicious({
    required String identifier,
    required String message,
    String severity = SecuritySeverity.high,
  }) {
    _send(
      eventType: SecurityEventType.suspicious,
      severity: severity,
      identifier: identifier,
      message: message,
    );
  }

  static Future<void> _send({
    required String eventType,
    required String severity,
    required String identifier,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    if (_sending) return;
    _sending = true;
    try {
      await SupabaseConfig.client.from('security_events').insert({
        'event_type': eventType,
        'severity': severity,
        'source': 'admin_web',
        'identifier': identifier.length > 200 ? identifier.substring(0, 200) : identifier,
        'message': message,
        'user_id': SupabaseConfig.currentUser?.id,
        'metadata': {
          ...?metadata,
          'app': 'thix_admin',
          'version': '1.0.0',
        },
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SecurityReporter] envoi ignoré : $e');
    } finally {
      _sending = false;
    }
  }
}
