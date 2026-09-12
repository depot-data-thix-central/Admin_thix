import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/audit_event.dart';

@immutable
class AuditState {
  final List<AuditEvent> events;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DateTime? lastRefresh;
  final String search;
  final String? category;

  const AuditState({
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastRefresh,
    this.search = '',
    this.category,
  });

  AuditState copyWith({
    List<AuditEvent>? events,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    DateTime? lastRefresh,
    String? search,
    String? category,
    bool clearCategory = false,
  }) {
    return AuditState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastRefresh: lastRefresh ?? this.lastRefresh,
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class AuditNotifier extends StateNotifier<AuditState> {
  AuditNotifier() : super(const AuditState()) {
    Future.delayed(const Duration(milliseconds: 150), () => refresh());
  }

  static const String kTable = 'audit_events';
  static const int kPageSize = 100;

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rows = await _query(0);
      state = state.copyWith(
        isLoading: false,
        events: rows,
        hasMore: rows.length >= kPageSize,
        lastRefresh: DateTime.now(),
      );
    } catch (e, st) {
      _log('refresh', e, st);
      state = state.copyWith(isLoading: false, error: _fmt(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final rows = await _query(state.events.length);
      state = state.copyWith(
        isLoadingMore: false,
        events: [...state.events, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<AuditEvent>> _query(int from) async {
    var q = SupabaseConfig.client.from(kTable).select('*');
    if (state.category != null) q = q.eq('category', state.category!);
    if (state.search.trim().isNotEmpty) {
      final s = '%${state.search.trim()}%';
      q = q.or('thix_id.ilike.$s,display_name.ilike.$s,summary.ilike.$s,action.ilike.$s');
    }
    final res = await q
        .order('created_at', ascending: false)
        .range(from, from + kPageSize - 1);
    return (res as List)
        .map((e) => AuditEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void setSearch(String v) => state = state.copyWith(search: v);
  void setCategory(String? c) =>
      state = state.copyWith(category: c, clearCategory: c == null, hasMore: true);

  // ─── STATS ───
  int get total24h => state.events
      .where((e) => e.createdAt.isAfter(
          DateTime.now().subtract(const Duration(hours: 24))))
      .length;

  int get activeUsers24h => state.events
      .where((e) => e.createdAt.isAfter(
          DateTime.now().subtract(const Duration(hours: 24))))
      .map((e) => e.userId ?? e.thixId ?? '?')
      .toSet()
      .length;

  Map<String, int> get categoryCounts {
    final m = <String, int>{};
    for (final e in state.events) {
      m[e.category] = (m[e.category] ?? 0) + 1;
    }
    return m;
  }

  List<MapEntry<String, int>> get topUsers {
    final m = <String, int>{};
    for (final e in state.events) {
      final k = e.thixId ?? e.userId ?? '?';
      m[k] = (m[k] ?? 0) + 1;
    }
    final list = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  /// 📤 Export CSV (copie dans le presse-papier)
  String buildCsv() {
    final buf = StringBuffer();
    buf.writeln('date;categorie;action;thix_id;utilisateur;resume;ip;appareil;version;source');
    for (final e in state.events) {
      buf.writeln([
        e.createdAt.toIso8601String(),
        e.category,
        e.action,
        e.thixId ?? '',
        (e.displayName ?? '').replaceAll(';', ','),
        e.summary.replaceAll(';', ','),
        e.ipAddress ?? '',
        e.device ?? '',
        e.appVersion ?? '',
        e.source,
      ].join(';'));
    }
    return buf.toString();
  }

  String _fmt(dynamic e) {
    if (e is PostgrestException) return e.message;
    return 'Erreur : $e';
  }

  void _log(String src, Object e, StackTrace? st) {
    if (!kDebugMode) return;
    debugPrint('❌ [Audit/$src] $e');
  }
}

final auditProvider = StateNotifierProvider<AuditNotifier, AuditState>((ref) {
  return AuditNotifier();
});
