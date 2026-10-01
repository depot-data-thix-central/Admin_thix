import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/supabase_config.dart';
import '../models/exemplary_citizen.dart';

/// 🔍 Filtres de la liste
@immutable
class CitizensFilters {
  final String search;
  final String? domain;
  final bool? activeOnly;

  const CitizensFilters({
    this.search = '',
    this.domain,
    this.activeOnly,
  });

  bool get isEmpty => search.isEmpty && domain == null && activeOnly == null;

  CitizensFilters copyWith({
    String? search,
    String? domain,
    bool? activeOnly,
    bool clearDomain = false,
    bool clearActiveOnly = false,
  }) {
    return CitizensFilters(
      search: search ?? this.search,
      domain: clearDomain ? null : (domain ?? this.domain),
      activeOnly: clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
    );
  }
}

/// 📦 État de la liste
@immutable
class CitizensState {
  final List<ExemplaryCitizen> citizens;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final CitizensFilters filters;
  final bool isSaving;
  final bool isUploading;

  const CitizensState({
    this.citizens = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const CitizensFilters(),
    this.isSaving = false,
    this.isUploading = false,
  });

  CitizensState copyWith({
    List<ExemplaryCitizen>? citizens,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    CitizensFilters? filters,
    bool? isSaving,
    bool? isUploading,
  }) {
    return CitizensState(
      citizens: citizens ?? this.citizens,
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
class CitizensNotifier extends StateNotifier<CitizensState> {
  CitizensNotifier() : super(const CitizensState()) {
    Future.delayed(const Duration(milliseconds: 100), () => loadCitizens());
  }

  static const String kTable = 'exemplary_citizens';
  static const String kBucket = 'citizens_photos';
  static const int kPageSize = 20;

  // ─── LECTURE (pagination + filtres) ───
  Future<void> loadCitizens({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      citizens: refresh ? const [] : state.citizens,
    );

    try {
      final rows = await _query(rangeStart: 0);
      state = state.copyWith(
        isLoading: false,
        citizens: rows,
        hasMore: rows.length >= kPageSize,
      );
    } catch (e, stack) {
      _logError('loadCitizens', e, stack);
      state = state.copyWith(isLoading: false, error: _fmtError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final rows = await _query(rangeStart: state.citizens.length);
      state = state.copyWith(
        isLoadingMore: false,
        citizens: [...state.citizens, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<ExemplaryCitizen>> _query({required int rangeStart}) async {
    var query = SupabaseConfig.client.from(kTable).select('*');

    final f = state.filters;
    if (f.search.isNotEmpty) {
      query = query.ilike('full_name', '%${f.search}%');
    }
    if (f.domain != null) query = query.eq('domain', f.domain!);
    if (f.activeOnly == true) query = query.eq('is_active', true);

    final response = await query
        .order('recognition_date', ascending: false)
        .range(rangeStart, rangeStart + kPageSize - 1);

    return (response as List)
        .map((e) => ExemplaryCitizen.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── FILTRES ───
  Future<void> setFilters(CitizensFilters filters) async {
    state = state.copyWith(filters: filters, hasMore: true);
    await loadCitizens(refresh: true);
  }

  // ─── CRÉATION / ÉDITION ───
  Future<CitizenOpResult> saveCitizen({
    required ExemplaryCitizen draft,
    String? existingId,
  }) async {
    if (state.isSaving) return CitizenOpResult.fail('Sauvegarde en cours…');
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
        await loadCitizens(refresh: true);
        return CitizenOpResult.ok(id);
      } else {
        await SupabaseConfig.client
            .from(kTable)
            .update(payload)
            .eq('id', existingId);
        state = state.copyWith(isSaving: false);
        await loadCitizens(refresh: true);
        return CitizenOpResult.ok(existingId);
      }
    } catch (e, stack) {
      _logError('saveCitizen', e, stack);
      state = state.copyWith(isSaving: false);
      return CitizenOpResult.fail(_fmtError(e));
    }
  }

  // ─── SUPPRESSION ───
  Future<CitizenOpResult> deleteCitizen(String id) async {
    try {
      await SupabaseConfig.client.from(kTable).delete().eq('id', id);
      state = state.copyWith(
        citizens: state.citizens.where((c) => c.id != id).toList(),
      );
      return CitizenOpResult.ok();
    } catch (e, stack) {
      _logError('deleteCitizen', e, stack);
      return CitizenOpResult.fail(_fmtError(e));
    }
  }

  // ─── TOGGLE ACTIF ───
  Future<CitizenOpResult> toggleActive(String id, bool isActive) async {
    try {
      await SupabaseConfig.client
          .from(kTable)
          .update({'is_active': isActive})
          .eq('id', id);

      state = state.copyWith(
        citizens: state.citizens.map((c) {
          if (c.id != id) return c;
          return c.copyWith(isActive: isActive);
        }).toList(),
      );
      return CitizenOpResult.ok();
    } catch (e, stack) {
      _logError('toggleActive', e, stack);
      return CitizenOpResult.fail(_fmtError(e));
    }
  }

  // ─── UPLOAD IMAGE ───
  Future<CitizenOpResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? extension,
  }) async {
    if (state.isUploading) return CitizenOpResult.fail('Upload en cours…');
    state = state.copyWith(isUploading: true);

    try {
      final ext = (extension ?? 'jpg').toLowerCase();
      final contentType = _mimeImage(ext);
      final path = 'citizens/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url = SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
      state = state.copyWith(isUploading: false);
      return CitizenOpResult.ok(url);
    } catch (e, stack) {
      _logError('uploadImage', e, stack);
      state = state.copyWith(isUploading: false);
      return CitizenOpResult.fail(_fmtError(e));
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
    debugPrint('❌ [Citizens/$src] $e');
    if (st != null) debugPrint(st.toString());
  }
}

/// 🎯 Providers
final citizensProvider =
    StateNotifierProvider<CitizensNotifier, CitizensState>((ref) {
  return CitizensNotifier();
});

/// 🏷️ Domaines (catégories de citoyens)
final citizensDomainsProvider = Provider<List<String>>((ref) => const [
      'Médecine & Droits Humains',
      'Sport & Humanitaire',
      'Musique & Culture',
      'Science & Technologie',
      'Éducation & Recherche',
      'Entrepreneuriat',
      'Politique & Gouvernance',
      'Arts & Littérature',
      'Général',
    ]);
