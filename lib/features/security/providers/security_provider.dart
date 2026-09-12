import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/security_event.dart';

/// 📦 État
@immutable
class SecurityState {
  final List<SecurityEvent> events;
  final List<SecurityBlock> blocklist;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;
  final String? filterSeverity;
  final String? filterType;
  final String? filterSource;
  final String search;
  final bool hideHandled;
  final bool isActing;

  const SecurityState({
    this.events = const [],
    this.blocklist = const [],
    this.isLoading = false,
    this.error,
    this.lastRefresh,
    this.filterSeverity,
    this.filterType,
    this.filterSource,
    this.search = '',
    this.hideHandled = false,
    this.isActing = false,
  });

  SecurityState copyWith({
    List<SecurityEvent>? events,
    List<SecurityBlock>? blocklist,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastRefresh,
    String? filterSeverity,
    bool clearSeverity = false,
    String? filterType,
    bool clearType = false,
    String? filterSource,
    bool clearSource = false,
    String? search,
    bool? hideHandled,
    bool? isActing,
  }) {
    return SecurityState(
      events: events ?? this.events,
      blocklist: blocklist ?? this.blocklist,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastRefresh: lastRefresh ?? this.lastRefresh,
      filterSeverity: clearSeverity ? null : (filterSeverity ?? this.filterSeverity),
      filterType: clearType ? null : (filterType ?? this.filterType),
      filterSource: clearSource ? null : (filterSource ?? this.filterSource),
      search: search ?? this.search,
      hideHandled: hideHandled ?? this.hideHandled,
      isActing: isActing ?? this.isActing,
    );
  }
}

/// 🎛️ Notifier monitoring + ACTIONS
class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(const SecurityState()) {
    Future.delayed(const Duration(milliseconds: 150), () {
      refresh();
      loadBlocklist();
      loadProfileSignals();
    });
  }

  static const String kTable = 'security_events';
  static const String kBlockTable = 'security_blocklist';
  static const int kBruteForceThreshold = 5;
  static const String kSourceMobile = 'mobile_app';
  static const String kSourceAdmin = 'admin_web';

  // ═══════════════════════════════════════════════════════════════
  // 📥 CHARGEMENT
  // ═══════════════════════════════════════════════════════════════
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
      state = state.copyWith(
        isLoading: false,
        events: (res as List)
            .map((e) => SecurityEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        lastRefresh: DateTime.now(),
      );
    } catch (e, st) {
      _log('refresh', e, st);
      state = state.copyWith(isLoading: false, error: _fmt(e));
    }
  }

  Future<void> loadBlocklist() async {
    try {
      final res = await SupabaseConfig.client
          .from(kBlockTable)
          .select('*')
          .eq('active', true)
          .order('created_at', ascending: false);
      state = state.copyWith(
        blocklist: (res as List)
            .map((e) => SecurityBlock.fromJson(Map<String, dynamic>.from(e)))
            .where((b) => !b.isExpired)
            .toList(),
      );
    } catch (e, st) {
      _log('loadBlocklist', e, st);
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

  void setSourceFilter(String? source) {
    state = state.copyWith(filterSource: source, clearSource: source == null);
  }

  void setHideHandled(bool v) => state = state.copyWith(hideHandled: v);

  // ═══════════════════════════════════════════════════════════════
  // 📊 STATS & DÉTECTIONS
  // ═══════════════════════════════════════════════════════════════
  int _countSince(Duration w, {String? type, bool criticalOnly = false}) {
    final cutoff = DateTime.now().subtract(w);
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
  int get mobileEvents24h => state.events
      .where((e) => e.source == kSourceMobile)
      .where((e) => e.createdAt.isAfter(
          DateTime.now().subtract(const Duration(hours: 24))))
      .length;

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
        .where((en) => en.value.length >= kBruteForceThreshold)
        .map((en) {
          String? userId;
          for (final e in en.value) {
            if (e.userId != null) {
              userId = e.userId;
              break;
            }
          }
          return BruteForceThreat(
            identifier: en.key,
            attempts: en.value.length,
            lastAttempt: en.value
                .map((e) => e.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
            ipAddresses: en.value.map((e) => e.ipAddress ?? '?').toSet(),
            userId: userId,
          );
        }).toList();
    threats.sort((a, b) => b.attempts.compareTo(a.attempts));
    return threats;
  }

  List<AggregatedError> get topErrors {
    final grouped = <String, List<SecurityEvent>>{};
    for (final e in state.events) {
      if (e.eventType != SecurityEventType.clientError) continue;
      final key = e.message.length > 90 ? e.message.substring(0, 90) : e.message;
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final list = grouped.entries.map((en) {
      return AggregatedError(
        message: en.key,
        count: en.value.length,
        lastOccurrence: en.value
            .map((e) => e.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }).toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list.take(5).toList();
  }

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

  Future<void> loadProfileSignals() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final r = await Future.wait([
        _countProfiles(gteCreated: cutoff),
        _countProfiles(eq: {'account_status': 'deactivated'}),
        _countProfiles(eq: {'status': 'pending_deletion'}),
      ]);
      _profileSignals = ProfileSignals(
          newAccounts24h: r[0], suspended: r[1], pendingDeletion: r[2]);
      state = state.copyWith();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Security] signaux profils : $e');
    }
  }

  Future<int> _countProfiles({DateTime? gteCreated, Map<String, String>? eq}) async {
    try {
      var query = SupabaseConfig.client.from('profiles').select('id');
      if (gteCreated != null) {
        query = query.gte('created_at', gteCreated.toIso8601String());
      }
      if (eq != null) {
        for (final e in eq.entries) {
          query = query.eq(e.key, e.value);
        }
      }
      final res = await query;
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  List<SecurityEvent> get filteredEvents {
    var list = state.events;
    final f = state;
    if (f.hideHandled) list = list.where((e) => !e.isHandled).toList();
    if (f.filterSeverity != null) {
      list = list.where((e) => e.severity == f.filterSeverity).toList();
    }
    if (f.filterType != null) {
      list = list.where((e) => e.eventType == f.filterType).toList();
    }
    if (f.filterSource != null) {
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

  // ═══════════════════════════════════════════════════════════════
  // ⚡ ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// ⛔ Bloquer un identifiant ou une IP (duration null = définitif)
  Future<UserOpResult> blockValue({
    required String type, // 'identifier' | 'ip'
    required String value,
    required String reason,
    Duration? duration,
  }) async {
    if (state.isActing) return UserOpResult.fail('Action en cours…');
    state = state.copyWith(isActing: true);
    try {
      await SupabaseConfig.client.from(kBlockTable).upsert(
        {
          'type': type,
          'value': value,
          'reason': reason,
          'severity': 'high',
          'expires_at': duration == null
              ? null
              : DateTime.now().add(duration).toIso8601String(),
          'active': true,
          'created_by': SupabaseConfig.currentUser?.id,
        },
        onConflict: 'type,value',
      );
      SecurityReporter.reportAdminAction(
        action: 'block_$type',
        details: 'Blocage $type : $value (${duration ?? 'définitif'})',
      );
      state = state.copyWith(isActing: false);
      await loadBlocklist();
      return UserOpResult.ok();
    } catch (e, st) {
      _log('blockValue', e, st);
      state = state.copyWith(isActing: false);
      return UserOpResult.fail(_fmt(e));
    }
  }

  /// 🔓 Débloquer
  Future<UserOpResult> unblock(String blockId) async {
    try {
      await SupabaseConfig.client
          .from(kBlockTable)
          .update({'active': false}).eq('id', blockId);
      SecurityReporter.reportAdminAction(
          action: 'unblock', details: 'Déblocage id=$blockId');
      await loadBlocklist();
      return UserOpResult.ok();
    } catch (e, st) {
      _log('unblock', e, st);
      return UserOpResult.fail(_fmt(e));
    }
  }

  /// ⏱️ Prolonger un blocage de N jours
  Future<UserOpResult> extendBlock(String blockId, int days) async {
    try {
      await SupabaseConfig.client.from(kBlockTable).update({
        'expires_at': DateTime.now().add(Duration(days: days)).toIso8601String(),
      }).eq('id', blockId);
      await loadBlocklist();
      return UserOpResult.ok();
    } catch (e, st) {
      _log('extendBlock', e, st);
      return UserOpResult.fail(_fmt(e));
    }
  }

  /// ✅ Marquer des événements comme traités
  Future<UserOpResult> acknowledgeEvents(List<String> ids) async {
    try {
      final now = DateTime.now().toIso8601String();
      for (final id in ids) {
        await SupabaseConfig.client.from(kTable).update({
          'status': 'acknowledged',
          'handled_by': SupabaseConfig.currentUser?.id,
          'handled_at': now,
        }).eq('id', id);
      }
      state = state.copyWith(
        events: state.events
            .map((e) => ids.contains(e.id)
                ? SecurityEvent(
                    id: e.id,
                    eventType: e.eventType,
                    severity: e.severity,
                    source: e.source,
                    userId: e.userId,
                    identifier: e.identifier,
                    ipAddress: e.ipAddress,
                    userAgent: e.userAgent,
                    message: e.message,
                    metadata: e.metadata,
                    createdAt: e.createdAt,
                    status: 'acknowledged',
                    handledAt: DateTime.now(),
                  )
                : e)
            .toList(),
      );
      return UserOpResult.ok();
    } catch (e, st) {
      _log('acknowledgeEvents', e, st);
      return UserOpResult.fail(_fmt(e));
    }
  }

  /// ✅ Traiter tous les événements d'un identifiant (menace)
  Future<UserOpResult> acknowledgeByIdentifier(String identifier) async {
    final ids = state.events
        .where((e) =>
            (e.identifier ?? '').toLowerCase() == identifier.toLowerCase() &&
            !e.isHandled)
        .map((e) => e.id)
        .toList();
    return acknowledgeEvents(ids);
  }

  /// 👤 Suspendre le compte lié (profiles)
  Future<UserOpResult> suspendUser(String userId) async {
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'account_status': 'deactivated'}).eq('id', userId);
      SecurityReporter.reportAdminAction(
          action: 'suspend_user', targetId: userId);
      return UserOpResult.ok();
    } catch (e, st) {
      _log('suspendUser', e, st);
      return UserOpResult.fail(_fmt(e));
    }
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

@immutable
class ProfileSignals {
  final int newAccounts24h;
  final int suspended;
  final int pendingDeletion;
  const ProfileSignals(
      {this.newAccounts24h = 0, this.suspended = 0, this.pendingDeletion = 0});
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

class UserOpResult {
  final bool success;
  final String? error;
  const UserOpResult({required this.success, this.error});
  factory UserOpResult.ok() => const UserOpResult(success: true);
  factory UserOpResult.fail(String e) => UserOpResult(success: false, error: e);
}

// ═══════════════════════════════════════════════════════════════
// 📡 REPORTER (inchangé)
// ═══════════════════════════════════════════════════════════════
class SecurityReporter {
  SecurityReporter._();
  static DateTime? _lastClientError;
  static bool _sending = false;

  static void reportLoginFailure({required String identifier, required String reason}) =>
      _send(eventType: SecurityEventType.loginFailed, severity: SecuritySeverity.medium, identifier: identifier, message: 'Échec de connexion : $reason');

  static void reportClientError({required String source, required String message}) {
    final now = DateTime.now();
    if (_lastClientError != null && now.difference(_lastClientError!).inSeconds < 10) return;
    _lastClientError = now;
    _send(eventType: SecurityEventType.clientError, severity: SecuritySeverity.medium, identifier: source, message: message.length > 480 ? message.substring(0, 480) : message);
  }

  static void reportAdminAction({required String action, String? targetId, String? details}) =>
      _send(eventType: SecurityEventType.adminAction, severity: SecuritySeverity.low, identifier: action, message: details ?? 'Action admin : $action', metadata: {'target_id': targetId});

  static void reportSuspicious({required String identifier, required String message, String severity = SecuritySeverity.high}) =>
      _send(eventType: SecurityEventType.suspicious, severity: severity, identifier: identifier, message: message);

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
        'metadata': {...?metadata, 'app': 'thix_admin', 'version': '1.0.0'},
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SecurityReporter] envoi ignoré : $e');
    } finally {
      _sending = false;
    }
  }
}
