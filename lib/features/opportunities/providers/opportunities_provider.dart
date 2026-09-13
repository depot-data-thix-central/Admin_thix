// lib/features/opportunities/providers/opportunities_provider.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/admin_opportunity.dart';

/// 🔍 Filtres
@immutable
class OpportunitiesFilters {
  final String search;
  final String? status;
  final String? category;

  const OpportunitiesFilters({
    this.search = '',
    this.status,
    this.category,
  });

  bool get isEmpty => search.isEmpty && status == null && category == null;

  OpportunitiesFilters copyWith({
    String? search,
    String? status,
    String? category,
    bool clearStatus = false,
    bool clearCategory = false,
  }) {
    return OpportunitiesFilters(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

/// 📦 État
@immutable
class OpportunitiesState {
  final List<AdminOpportunity> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final OpportunitiesFilters filters;
  final bool isSaving;
  final bool isUploading;

  const OpportunitiesState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const OpportunitiesFilters(),
    this.isSaving = false,
    this.isUploading = false,
  });

  OpportunitiesState copyWith({
    List<AdminOpportunity>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    OpportunitiesFilters? filters,
    bool? isSaving,
    bool? isUploading,
  }) {
    return OpportunitiesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      isSaving: isSaving ?? this.isSaving,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

/// 🎛️ Notifier CRUD
class OpportunitiesNotifier extends StateNotifier<OpportunitiesState> {
  OpportunitiesNotifier() : super(const OpportunitiesState()) {
    Future.delayed(const Duration(milliseconds: 100), () => load(refresh: true));
  }

  static const String kTable = 'thix_opportunities';
  static const String kBucket = 'thix_opportunity_images';
  static const int kPageSize = 20;

  // ─── LECTURE ───
  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: refresh ? const [] : state.items,
    );
    try {
      final rows = await _query(rangeStart: 0);
      state = state.copyWith(
        isLoading: false,
        items: rows,
        hasMore: rows.length >= kPageSize,
      );
    } catch (e, stack) {
      _logError('load', e, stack);
      state = state.copyWith(isLoading: false, error: _fmtError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final rows = await _query(rangeStart: state.items.length);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<AdminOpportunity>> _query({required int rangeStart}) async {
    var query = SupabaseConfig.client.from(kTable).select('*');
    final f = state.filters;
    if (f.search.isNotEmpty) {
      query = query.or('title.ilike.%${f.search}%,organizer.ilike.%${f.search}%');
    }
    if (f.status != null) query = query.eq('status', f.status!);
    if (f.category != null) query = query.eq('category', f.category!);

    final response = await query
        .order('created_at', ascending: false)
        .range(rangeStart, rangeStart + kPageSize - 1);

    return (response as List)
        .map((e) => AdminOpportunity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> setFilters(OpportunitiesFilters filters) async {
    state = state.copyWith(filters: filters, hasMore: true);
    await load(refresh: true);
  }

  // ─── CRÉATION / ÉDITION ───
  Future<OpportunityOpResult> save({
    required AdminOpportunity draft,
    String? existingId,
  }) async {
    if (state.isSaving) return OpportunityOpResult.fail('Sauvegarde en cours…');
    state = state.copyWith(isSaving: true);
    try {
      final isInsert = existingId == null || existingId.isEmpty;
      final payload = draft.toPayload(isInsert: isInsert);
      if (isInsert) {
        final res = await SupabaseConfig.client
            .from(kTable)
            .insert(payload)
            .select();
        final id = (res as List).first['id'].toString();
        state = state.copyWith(isSaving: false);
        await load(refresh: true);
        return OpportunityOpResult.ok(id);
      } else {
        await SupabaseConfig.client.from(kTable).update(payload).eq('id', existingId);
        state = state.copyWith(isSaving: false);
        await load(refresh: true);
        return OpportunityOpResult.ok(existingId);
      }
    } catch (e, stack) {
      _logError('save', e, stack);
      state = state.copyWith(isSaving: false);
      return OpportunityOpResult.fail(_fmtError(e));
    }
  }

  // ─── SUPPRESSION ───
  Future<OpportunityOpResult> delete(String id) async {
    try {
      await SupabaseConfig.client.from(kTable).delete().eq('id', id);
      state = state.copyWith(
        items: state.items.where((o) => o.id != id).toList(),
      );
      return OpportunityOpResult.ok();
    } catch (e, stack) {
      _logError('delete', e, stack);
      return OpportunityOpResult.fail(_fmtError(e));
    }
  }

  // ─── TOGGLES RAPIDES (statut) ───
  Future<OpportunityOpResult> updateStatus(String id, String newStatus) async {
    try {
      await SupabaseConfig.client
          .from(kTable)
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      state = state.copyWith(
        items: state.items.map((o) {
          if (o.id != id) return o;
          return o.copyWith(status: newStatus);
        }).toList(),
      );
      return OpportunityOpResult.ok();
    } catch (e, stack) {
      _logError('updateStatus', e, stack);
      return OpportunityOpResult.fail(_fmtError(e));
    }
  }

  // ─── UPLOAD IMAGE ───
  Future<OpportunityOpResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? extension,
  }) async {
    if (state.isUploading) return OpportunityOpResult.fail('Upload en cours…');
    state = state.copyWith(isUploading: true);
    try {
      final ext = (extension ?? 'jpg').toLowerCase();
      final contentType = _mime(ext);
      final path = 'opportunities/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final url = SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
      state = state.copyWith(isUploading: false);
      return OpportunityOpResult.ok(url);
    } catch (e, stack) {
      _logError('uploadImage', e, stack);
      state = state.copyWith(isUploading: false);
      return OpportunityOpResult.fail(_fmtError(e));
    }
  }

  String _mime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  String _fmtError(dynamic e) {
    if (e is PostgrestException) return e.message;
    if (e is StorageException) return e.message;
    return 'Erreur inattendue : ${e.toString()}';
  }

  void _logError(String src, Object e, StackTrace? st) {
    if (!kDebugMode) return;
    debugPrint('❌ [Opportunities/$src] $e');
    if (st != null) debugPrint(st.toString());
  }
}

final opportunitiesProvider =
    StateNotifierProvider<OpportunitiesNotifier, OpportunitiesState>((ref) {
  return OpportunitiesNotifier();
});

final opportunitiesCategoriesProvider = Provider<List<String>>((ref) => const [
      'Bourses',
      'Emplois',
      'Subventions',
      'Concours',
      'Formations',
      'Stages',
    ]);
