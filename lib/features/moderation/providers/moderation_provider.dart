import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../../security/providers/security_provider.dart';
import '../moderation_config.dart';
import '../models/moderation_item.dart';

@immutable
class ModerationState {
  final List<ModerationItem> items;
  final bool isLoading;
  final String? error;
  final bool isActing;
  final String? lastActionError;

  const ModerationState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isActing = false,
    this.lastActionError,
  });

  ModerationState copyWith({
    List<ModerationItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isActing,
    String? lastActionError,
    bool clearActionError = false,
  }) {
    return ModerationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isActing: isActing ?? this.isActing,
      lastActionError:
          clearActionError ? null : (lastActionError ?? this.lastActionError),
    );
  }
}

class ModerationNotifier extends StateNotifier<ModerationState> {
  ModerationNotifier() : super(const ModerationState()) {
    Future.delayed(const Duration(milliseconds: 120), () => load());
  }

  static const String kCasesTable = 'moderation_cases';

  // ═══════════════ CHARGEMENT ═══════════════
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Décisions admin existantes
      final casesRes =
          await SupabaseConfig.client.from(kCasesTable).select('*');
      final cases = <String, Map<String, dynamic>>{};
      for (final c in casesRes as List) {
        final m = Map<String, dynamic>.from(c);
        cases['${m['source_table']}:${m['source_id']}'] = m;
      }

      // 2. Signalements depuis chaque table source
      final items = <ModerationItem>[];
      for (final src in ModerationConfig.sources) {
        try {
          final res = await SupabaseConfig.client
              .from(src.table)
              .select('*')
              .order('created_at', ascending: false)
              .limit(200);
          for (final r in res as List) {
            final j = Map<String, dynamic>.from(r);
            final id = j['id']?.toString() ?? '';
            final caseRow = cases['${src.table}:$id'];
            items.add(ModerationItem(
              id: id,
              sourceTable: src.table,
              contentType: src.contentType,
              contentId: _s(j, ModerationConfig.targetKeys),
              reporterId: _s(j, ModerationConfig.reporterKeys),
              reason: _s(j, ModerationConfig.reasonKeys) ?? '',
              details: _s(j, ModerationConfig.detailsKeys) ?? '',
              sourceStatus: _statusOf(j),
              caseAction: caseRow?['action']?.toString(),
              createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
              raw: j,
            ));
          }
        } catch (e) {
          debugPrint('⚠️ [Modération] table ${src.table} illisible : $e');
        }
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(isLoading: false, items: items);
    } catch (e, st) {
      debugPrint('❌ [Modération] $e\n$st');
      state = state.copyWith(
          isLoading: false,
          error: e is PostgrestException ? e.message : 'Erreur : $e');
    }
  }

  // ═══════════════ FILTRES ═══════════════
  List<ModerationItem> get pending =>
      state.items.where((i) => !i.isHandled).toList();

  List<ModerationItem> get handled =>
      state.items.where((i) => i.isHandled).toList();

  // ═══════════════ ACTIONS ═══════════════

  Future<bool> _recordCase(ModerationItem item, String action,
      {String? notes}) async {
    await SupabaseConfig.client.from(kCasesTable).upsert({
      'source_table': item.sourceTable,
      'source_id': item.id,
      'content_type': item.contentType,
      'content_id': item.contentId,
      'reporter_id': item.reporterId,
      'reason': item.reason,
      'details': item.details,
      'action': action,
      'notes': notes,
      'handled_by': SupabaseConfig.currentUser?.id,
    }, onConflict: 'source_table,source_id');
    return true;
  }

  /// ❌ Rejeter le signalement (conserver le contenu)
  Future<bool> dismiss(ModerationItem item, {String? notes}) async {
    if (state.isActing) return false;
    state = state.copyWith(isActing: true, clearActionError: true);
    try {
      await _recordCase(item, 'dismissed', notes: notes);
      SecurityReporter.reportAdminAction(
          action: 'moderation_dismiss', targetId: item.id);
      state = state.copyWith(isActing: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isActing: false, lastActionError: 'Erreur : $e');
      return false;
    }
  }

  /// 🗑️ Supprimer/masquer le contenu signalé
  Future<bool> removeContent(ModerationItem item) async {
    if (state.isActing) return false;
    if (item.contentId == null) {
      state = state.copyWith(
          lastActionError: 'Contenu cible introuvable dans le signalement');
      return false;
    }
    state = state.copyWith(isActing: true, clearActionError: true);
    try {
      final src = ModerationConfig.sources
          .firstWhere((s) => s.table == item.sourceTable);
      bool removed = false;

      for (final table in src.targetTables) {
        for (final payload in ModerationConfig.takedownPayloads) {
          try {
            final res = await SupabaseConfig.client
                .from(table)
                .update(payload)
                .eq('id', item.contentId!)
                .select();
            if ((res as List).isNotEmpty) {
              removed = true;
              break;
            }
          } catch (_) {
            continue; // colonne inexistante → payload suivant
          }
        }
        if (removed) break;
      }

      if (!removed) {
        state = state.copyWith(
            isActing: false,
            lastActionError:
                '⛔ Impossible de masquer le contenu : aucune colonne de statut compatible trouvée');
        return false;
      }

      await _recordCase(item, 'content_removed');
      SecurityReporter.reportAdminAction(
          action: 'moderation_remove_content', targetId: item.contentId);
      state = state.copyWith(isActing: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isActing: false, lastActionError: 'Erreur : $e');
      return false;
    }
  }

  /// 👤 Suspendre l'auteur du contenu signalé
  Future<bool> suspendAuthor(ModerationItem item) async {
    if (state.isActing) return false;
    state = state.copyWith(isActing: true, clearActionError: true);
    try {
      final authorId = await _fetchAuthorId(item);
      if (authorId == null) {
        state = state.copyWith(
            isActing: false,
            lastActionError: 'Auteur introuvable pour ce contenu');
        return false;
      }

      final res = await SupabaseConfig.client
          .from('profiles')
          .update({'account_status': 'deactivated'})
          .eq('id', authorId)
          .select();
      if ((res as List).isEmpty) {
        state = state.copyWith(
            isActing: false,
            lastActionError: '⛔ Suspension bloquée par la RLS (rôle admin requis)');
        return false;
      }

      await _recordCase(item, 'author_suspended');
      SecurityReporter.reportAdminAction(
          action: 'moderation_suspend_author', targetId: authorId);
      state = state.copyWith(isActing: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isActing: false, lastActionError: 'Erreur : $e');
      return false;
    }
  }

  Future<String?> _fetchAuthorId(ModerationItem item) async {
    if (item.contentId == null) return null;
    final src = ModerationConfig.sources
        .firstWhere((s) => s.table == item.sourceTable);
    for (final table in src.targetTables) {
      try {
        final res = await SupabaseConfig.client
            .from(table)
            .select('*')
            .eq('id', item.contentId!)
            .limit(1);
        if ((res as List).isEmpty) continue;
        final j = Map<String, dynamic>.from(res.first);
        final author = _s(j, ModerationConfig.authorKeys);
        if (author != null) return author;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ═══════════════ HELPERS ═══════════════
  String? _s(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }

  String _statusOf(Map<String, dynamic> j) {
    for (final k in ModerationConfig.statusKeys) {
      final v = j[k];
      if (v != null) return v.toString().toLowerCase();
    }
    final resolved = j['resolved'];
    if (resolved is bool) return resolved ? 'resolved' : 'pending';
    return 'pending';
  }
}

final moderationProvider =
    StateNotifierProvider<ModerationNotifier, ModerationState>((ref) {
  return ModerationNotifier();
});
