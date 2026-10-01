import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/historical_figure.dart';

/// 🔍 Filtres de la liste
@immutable
class HistoricalFiguresFilters {
  final String search;
  final String? category;
  final bool? activeOnly;

  const HistoricalFiguresFilters({
    this.search = '',
    this.category,
    this.activeOnly,
  });

  bool get isEmpty => search.isEmpty && category == null && activeOnly == null;

  HistoricalFiguresFilters copyWith({
    String? search,
    String? category,
    bool? activeOnly,
    bool clearCategory = false,
    bool clearActiveOnly = false,
  }) {
    return HistoricalFiguresFilters(
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
      activeOnly: clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
    );
  }
}

/// 📦 État de la liste
@immutable
class HistoricalFiguresState {
  final List<HistoricalFigure> figures;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final HistoricalFiguresFilters filters;
  final bool isSaving;
  final bool isUploading;

  const HistoricalFiguresState({
    this.figures = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const HistoricalFiguresFilters(),
    this.isSaving = false,
    this.isUploading = false,
  });

  HistoricalFiguresState copyWith({
    List<HistoricalFigure>? figures,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    HistoricalFiguresFilters? filters,
    bool? isSaving,
    bool? isUploading,
  }) {
    return HistoricalFiguresState(
      figures: figures ?? this.figures,
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

/// 🎛️ Notifier CRUD complet
class HistoricalFiguresNotifier extends StateNotifier<HistoricalFiguresState> {
  HistoricalFiguresNotifier() : super(const HistoricalFiguresState()) {
    Future.delayed(
        const Duration(milliseconds: 100), () => loadFigures());
  }

  static const String kTable = 'historical_figures';
  static const String kBucket = 'historical_figures_photos';
  static const int kPageSize = 20;

  // ─── LECTURE (pagination + filtres) ───
  Future<void> loadFigures({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      figures: refresh ? const [] : state.figures,
    );

    try {
      final rows = await _query(rangeStart: 0);
      state = state.copyWith(
        isLoading: false,
        figures: rows,
        hasMore: rows.length >= kPageSize,
      );
    } catch (e, stack) {
      _logError('loadFigures', e, stack);
      state = state.copyWith(isLoading: false, error: _fmtError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final rows = await _query(rangeStart: state.figures.length);
      state = state.copyWith(
        isLoadingMore: false,
        figures: [...state.figures, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<HistoricalFigure>> _query({required int rangeStart}) async {
    var query = SupabaseConfig.client.from(kTable).select('*');

    final f = state.filters;
    if (f.search.isNotEmpty) {
      query = query.ilike('full_name', '%${f.search}%');
    }
    if (f.category != null) query = query.eq('category', f.category!);
    if (f.activeOnly == true) query = query.eq('is_active', true);

    final response = await query
        .order('created_at', ascending: false)
        .range(rangeStart, rangeStart + kPageSize - 1);

    return (response as List)
        .map((e) => HistoricalFigure.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── FILTRES ───
  Future<void> setFilters(HistoricalFiguresFilters filters) async {
    state = state.copyWith(filters: filters, hasMore: true);
    await loadFigures(refresh: true);
  }

  // ─── CRÉATION / ÉDITION ───
  Future<HistoricalFigureOpResult> saveFigure({
    required HistoricalFigure draft,
    String? existingId,
  }) async {
    if (state.isSaving) {
      return HistoricalFigureOpResult.fail('Sauvegarde en cours…');
    }
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
        await loadFigures(refresh: true);
        return HistoricalFigureOpResult.ok(id);
      } else {
        await SupabaseConfig.client
            .from(kTable)
            .update(payload)
            .eq('id', existingId);
        state = state.copyWith(isSaving: false);
        await loadFigures(refresh: true);
        return HistoricalFigureOpResult.ok(existingId);
      }
    } catch (e, stack) {
      _logError('saveFigure', e, stack);
      state = state.copyWith(isSaving: false);
      return HistoricalFigureOpResult.fail(_fmtError(e));
    }
  }

  // ─── SUPPRESSION ───
  Future<HistoricalFigureOpResult> deleteFigure(String id) async {
    try {
      await SupabaseConfig.client.from(kTable).delete().eq('id', id);
      state = state.copyWith(
        figures: state.figures.where((f) => f.id != id).toList(),
      );
      return HistoricalFigureOpResult.ok();
    } catch (e, stack) {
      _logError('deleteFigure', e, stack);
      return HistoricalFigureOpResult.fail(_fmtError(e));
    }
  }

  // ─── TOGGLE ACTIF ───
  Future<HistoricalFigureOpResult> toggleActive(String id, bool isActive) async {
    try {
      await SupabaseConfig.client
          .from(kTable)
          .update({'is_active': isActive})
          .eq('id', id);

      state = state.copyWith(
        figures: state.figures.map((f) {
          if (f.id != id) return f;
          return f.copyWith(isActive: isActive);
        }).toList(),
      );
      return HistoricalFigureOpResult.ok();
    } catch (e, stack) {
      _logError('toggleActive', e, stack);
      return HistoricalFigureOpResult.fail(_fmtError(e));
    }
  }

  // ─── UPLOAD IMAGE ───
  Future<HistoricalFigureOpResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? extension,
  }) async {
    if (state.isUploading) {
      return HistoricalFigureOpResult.fail('Upload en cours…');
    }
    state = state.copyWith(isUploading: true);

    try {
      final ext = (extension ?? 'jpg').toLowerCase();
      final contentType = _mimeImage(ext);
      final path = 'figures/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url =
          SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
      state = state.copyWith(isUploading: false);
      return HistoricalFigureOpResult.ok(url);
    } catch (e, stack) {
      _logError('uploadImage', e, stack);
      state = state.copyWith(isUploading: false);
      return HistoricalFigureOpResult.fail(_fmtError(e));
    }
  }

  String _mimeImage(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
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
    debugPrint('❌ [HistoricalFigures/$src] $e');
    if (st != null) debugPrint(st.toString());
  }
}

/// 🎯 Providers
final historicalFiguresProvider =
    StateNotifierProvider<HistoricalFiguresNotifier, HistoricalFiguresState>((ref) {
  return HistoricalFiguresNotifier();
});

/// 🏷️ Catégories de figures historiques
final historicalFiguresCategoriesProvider = Provider<List<String>>((ref) => const [
      'Politique',
      'Religion',
      'Science & Technologie',
      'Arts & Littérature',
      'Sport',
      'Militaire',
      'Entrepreneuriat',
      'Éducation',
      'Autre',
    ]);
