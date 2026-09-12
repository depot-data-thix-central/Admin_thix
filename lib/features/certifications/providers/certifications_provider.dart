import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../../security/providers/security_provider.dart';
import '../models/admin_certification.dart';

@immutable
class CertState {
  final List<AdminCertification> items;
  final bool isLoading;
  final String? error;
  final String search;
  final String? tierFilter;
  final bool isActing;

  const CertState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.tierFilter,
    this.isActing = false,
  });

  CertState copyWith({
    List<AdminCertification>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? tierFilter,
    bool clearTier = false,
    bool? isActing,
  }) {
    return CertState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      tierFilter: clearTier ? null : (tierFilter ?? this.tierFilter),
      isActing: isActing ?? this.isActing,
    );
  }
}

class CertificationsNotifier extends StateNotifier<CertState> {
  CertificationsNotifier() : super(const CertState()) {
    Future.delayed(const Duration(milliseconds: 120), () => load());
  }

  static const String kTable = 'profiles';

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await SupabaseConfig.client
          .from(kTable)
          .select('id, thix_id, display_name, avatar_url, account_type, '
              'certification_tier, certification_status, certified_at, '
              'certification_starts_at, certification_expires_at, '
              'certification_auto_renew, certification_notes, '
              'certification_suspended_until, certification_suspension_reason')
          .or('certification_status.neq.none,certification_tier.neq.gratuit,'
              'certification_suspended_until.not.is.null');

      final items = (res as List)
          .map((e) => AdminCertification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      items.sort((a, b) => a.state.index.compareTo(b.state.index));
      state = state.copyWith(isLoading: false, items: items);
    } catch (e, st) {
      debugPrint('❌ [Certifications] $e\n$st');
      state = state.copyWith(
          isLoading: false,
          error: e is PostgrestException ? e.message : 'Erreur : $e');
    }
  }

  void setSearch(String v) => state = state.copyWith(search: v);
  void setTier(String? t) =>
      state = state.copyWith(tierFilter: t, clearTier: t == null);

  List<AdminCertification> byState(CertStateFilter f) {
    var list = state.items;
    if (state.tierFilter != null) {
      list = list.where((c) => c.tier == state.tierFilter).toList();
    }
    if (state.search.trim().isNotEmpty) {
      final s = state.search.toLowerCase();
      list = list
          .where((c) =>
              c.displayName.toLowerCase().contains(s) ||
              c.thixId.toLowerCase().contains(s))
          .toList();
    }
    switch (f) {
      case CertStateFilter.pending:
        return list.where((c) => c.state == CertState.pending).toList();
      case CertStateFilter.active:
        return list.where((c) => c.state == CertState.active).toList();
      case CertStateFilter.expiring:
        return list.where((c) => c.state == CertState.expiring).toList();
      case CertStateFilter.suspended:
        return list.where((c) => c.state == CertState.suspended).toList();
      case CertStateFilter.expired:
        return list.where((c) => c.state == CertState.expired).toList();
      case CertStateFilter.history:
        return list
            .where((c) =>
                c.state == CertState.revoked || c.state == CertState.rejected)
            .toList();
      case CertStateFilter.all:
        return list;
    }
  }

  int countOf(CertStateFilter f) => byState(f).length;

  // ═══════════════════════════════════════════════════════════════
  // ⚡ ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _update(String userId, Map<String, dynamic> payload,
      String actionLabel) async {
    if (state.isActing) return false;
    state = state.copyWith(isActing: true);
    try {
      await SupabaseConfig.client.from(kTable).update(payload).eq('id', userId);
      SecurityReporter.reportAdminAction(
          action: actionLabel, targetId: userId);
      state = state.copyWith(isActing: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isActing: false);
      return false;
    }
  }

  /// ✅ Approuver une demande
  Future<bool> approve(String userId, String tier, int months) {
    final now = DateTime.now();
    return _update(userId, {
      'certification_status': 'approved',
      'certification_tier': tier,
      'certified_at': now.toIso8601String(),
      'certification_starts_at': now.toIso8601String(),
      'certification_expires_at':
          DateTime(now.year, now.month + months, now.day).toIso8601String(),
      'certification_suspended_until': null,
      'certification_suspension_reason': null,
    }, 'certification_approve');
  }

  /// ❌ Refuser / supprimer une demande
  Future<bool> reject(String userId, String reason) {
    return _update(userId, {
      'certification_status': 'rejected',
      'certification_notes': reason,
    }, 'certification_reject');
  }

  /// ⏸️ Suspendre (temporaire ou définitif)
  Future<bool> suspend(String userId, int? days, String reason) {
    return _update(userId, {
      'certification_status': 'suspended',
      'certification_suspended_until': days == null
          ? null
          : DateTime.now().add(Duration(days: days)).toIso8601String(),
      'certification_suspension_reason': reason,
    }, 'certification_suspend');
  }

  /// ▶️ Réactiver une certification suspendue
  Future<bool> reactivate(String userId) {
    return _update(userId, {
      'certification_status': 'approved',
      'certification_suspended_until': null,
      'certification_suspension_reason': null,
    }, 'certification_reactivate');
  }

  /// ⏱️ Prolonger la durée
  Future<bool> extend(String userId, DateTime currentExpiry, int days) {
    final base = currentExpiry.isBefore(DateTime.now())
        ? DateTime.now()
        : currentExpiry;
    return _update(userId, {
      'certification_expires_at':
          base.add(Duration(days: days)).toIso8601String(),
    }, 'certification_extend');
  }

  /// 🗑️ Révoquer définitivement
  Future<bool> revoke(String userId, String reason) {
    return _update(userId, {
      'certification_status': 'revoked',
      'certification_notes': reason,
      'certification_suspended_until': null,
    }, 'certification_revoke');
  }

  /// 🧹 Supprimer une demande en attente (retour à aucun statut)
  Future<bool> deleteRequest(String userId) {
    return _update(userId, {
      'certification_status': 'none',
      'certification_notes': null,
    }, 'certification_delete_request');
  }
}

enum CertStateFilter { pending, active, expiring, suspended, expired, history, all }

final certificationsProvider =
    StateNotifierProvider<CertificationsNotifier, CertState>((ref) {
  return CertificationsNotifier();
});
