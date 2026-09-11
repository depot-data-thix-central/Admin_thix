import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import 'package:thix_admin/features/users/models/admin_user_profile.dart';


/// 📦 État
@immutable
class UsersState {
  final List<AdminUserProfile> users;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final UsersFilters filters;
  final UsersStats stats;
  final bool isOperating;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const UsersFilters(),
    this.stats = const UsersStats(),
    this.isOperating = false,
  });

  UsersState copyWith({
    List<AdminUserProfile>? users,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    UsersFilters? filters,
    UsersStats? stats,
    bool? isOperating,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      stats: stats ?? this.stats,
      isOperating: isOperating ?? this.isOperating,
    );
  }
}

/// 🎛️ Notifier monitoring utilisateurs
class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier() : super(const UsersState()) {
    Future.delayed(const Duration(milliseconds: 100), () {
      loadUsers();
      loadStats();
    });
  }

  // ⚙️ CONFIG — table des profils
  static const String kTable = 'profiles';
  static const int kPageSize = 20;

  // ─── LECTURE ───
  Future<void> loadUsers({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rows = await _query(rangeStart: 0);
      state = state.copyWith(
        isLoading: false,
        users: rows,
        hasMore: rows.length >= kPageSize,
      );
    } catch (e, st) {
      _log('loadUsers', e, st);
      state = state.copyWith(isLoading: false, error: _fmt(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final rows = await _query(rangeStart: state.users.length);
      state = state.copyWith(
        isLoadingMore: false,
        users: [...state.users, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<AdminUserProfile>> _query({required int rangeStart}) async {
    var query = SupabaseConfig.client.from(kTable).select('*');

    final f = state.filters;
    if (f.search.isNotEmpty) {
      final s = '%${f.search}%';
      query = query.or(
          'display_name.ilike.$s,thix_id.ilike.$s,full_name.ilike.$s');
    }
    if (f.role != null) query = query.eq('role', f.role!);
    if (f.accountType != null) query = query.eq('account_type', f.accountType!);

    switch (f.statusGroup) {
      case 'suspended':
        query = query.eq('account_status', 'deactivated');
        break;
      case 'pending_deletion':
        query = query.eq('status', 'pending_deletion');
        break;
      case 'admins':
        query = query.eq('role', 'admin');
        break;
      case 'active':
        query = query
            .eq('status', 'active')
            .neq('account_status', 'deactivated');
        break;
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(rangeStart, rangeStart + kPageSize - 1);

    return (res as List)
        .map((e) => AdminUserProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> setFilters(UsersFilters filters) async {
    state = state.copyWith(filters: filters, hasMore: true);
    await loadUsers(refresh: true);
  }

  // ─── STATISTIQUES ───
  Future<void> loadStats() async {
    try {
      final results = await Future.wait([
        _count(),
        _count(eq: {'role': 'admin'}),
        _count(eq: {'account_status': 'deactivated'}),
        _count(eq: {'status': 'pending_deletion'}),
      ]);
      state = state.copyWith(
        stats: UsersStats(
          total: results[0],
          admins: results[1],
          suspended: results[2],
          pendingDeletion: results[3],
        ),
      );
    } catch (e, st) {
      _log('loadStats', e, st);
    }
  }

  // ✅ CORRECTION ICI : Le query est construit d'abord, puis .count() est appliqué à la fin
  Future<int> _count({Map<String, String>? eq}) async {
    var query = SupabaseConfig.client.from(kTable).select('id');

    if (eq != null) {
      for (final e in eq.entries) {
        query = query.eq(e.key, e.value);
      }
    }
    
    // On ajoute le count() juste au moment de l'exécution
    final res = await query.count(CountOption.exact);
    return res.count ?? 0;
  }

  // ─── ACTIONS SÉCURISÉES (statut uniquement) ───
  Future<UserOpResult> suspendUser(String id) async {
    return _updateStatus(id, 'deactivated');
  }

  Future<UserOpResult> reactivateUser(String id) async {
    return _updateStatus(id, 'active');
  }

  Future<UserOpResult> _updateStatus(String id, String accountStatus) async {
    if (state.isOperating) return UserOpResult.fail('Opération en cours…');
    state = state.copyWith(isOperating: true);
    try {
      await SupabaseConfig.client
          .from(kTable)
          .update({'account_status': accountStatus}).eq('id', id);

      // ✅ CORRECTION : cast explicite pour éviter l'inférence Object?
      state = state.copyWith(
        isOperating: false,
        users: state.users
            .map<AdminUserProfile>((AdminUserProfile u) =>
                u.id == id ? u.copyWith(accountStatus: accountStatus) : u)
            .toList(),
      );
      await loadStats();
      return UserOpResult.ok();
    } catch (e, st) {
      _log('_updateStatus', e, st);
      state = state.copyWith(isOperating: false);
      return UserOpResult.fail(_fmt(e));
    }
  }

  String _fmt(dynamic e) {
    if (e is PostgrestException) return e.message;
    return 'Erreur : ${e.toString()}';
  }

  void _log(String src, Object e, StackTrace? st) {
    if (!kDebugMode) return;
    debugPrint('❌ [Users/$src] $e');
    if (st != null) debugPrint(st.toString());
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier();
});
