import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase/supabase_config.dart';
import '../models/admin_article.dart';

/// 🔍 Filtres de la liste
@immutable
class ArticlesFilters {
  final String search;
  final String? status;
  final String? category;
  final bool? featured;
  final bool? breaking;

  const ArticlesFilters({
    this.search = '',
    this.status,
    this.category,
    this.featured,
    this.breaking,
  });

  bool get isEmpty =>
      search.isEmpty &&
      status == null &&
      category == null &&
      featured == null &&
      breaking == null;

  ArticlesFilters copyWith({
    String? search,
    String? status,
    String? category,
    bool? featured,
    bool? breaking,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearFeatured = false,
    bool clearBreaking = false,
  }) {
    return ArticlesFilters(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      featured: clearFeatured ? null : (featured ?? this.featured),
      breaking: clearBreaking ? null : (breaking ?? this.breaking),
    );
  }
}

/// 📦 État de la liste
@immutable
class ArticlesState {
  final List<AdminArticle> articles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final ArticlesFilters filters;
  final bool isSaving;
  final bool isUploading;

  const ArticlesState({
    this.articles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filters = const ArticlesFilters(),
    this.isSaving = false,
    this.isUploading = false,
  });

  ArticlesState copyWith({
    List<AdminArticle>? articles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    ArticlesFilters? filters,
    bool? isSaving,
    bool? isUploading,
  }) {
    return ArticlesState(
      articles: articles ?? this.articles,
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
class ArticlesNotifier extends StateNotifier<ArticlesState> {
  ArticlesNotifier() : super(const ArticlesState()) {
    Future.delayed(const Duration(milliseconds: 100), () => loadArticles());
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ CONFIGURATION
  // ═══════════════════════════════════════════════════════════════
  static const String kTable = 'news_articles';
  static const String kBucket = 'news_images';
  static const int kPageSize = 20;

  // ─── LECTURE (pagination + filtres) ───
  Future<void> loadArticles({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      articles: refresh ? const [] : state.articles,
    );

    try {
      final rows = await _query(rangeStart: 0);
      state = state.copyWith(
        isLoading: false,
        articles: rows,
        hasMore: rows.length >= kPageSize,
      );
    } catch (e, stack) {
      _logError('loadArticles', e, stack);
      state = state.copyWith(isLoading: false, error: _fmtError(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final rows = await _query(rangeStart: state.articles.length);
      state = state.copyWith(
        isLoadingMore: false,
        articles: [...state.articles, ...rows],
        hasMore: rows.length >= kPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<AdminArticle>> _query({required int rangeStart}) async {
    var query = SupabaseConfig.client.from(kTable).select('*');

    final f = state.filters;
    if (f.search.isNotEmpty) {
      query = query.ilike('title', '%${f.search}%');
    }
    if (f.status != null) query = query.eq('status', f.status!);
    if (f.category != null) query = query.eq('category', f.category!);
    if (f.featured != null) query = query.eq('is_featured', f.featured!);
    if (f.breaking != null) query = query.eq('is_breaking', f.breaking!);

    final response = await query
        .order('published_at', ascending: false)
        .range(rangeStart, rangeStart + kPageSize - 1);

    return (response as List)
        .map((e) => AdminArticle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── FILTRES ───
  Future<void> setFilters(ArticlesFilters filters) async {
    state = state.copyWith(filters: filters, hasMore: true);
    await loadArticles(refresh: true);
  }

  // ─── CRÉATION / ÉDITION ───
  Future<ArticleOpResult> saveArticle({
    required AdminArticle draft,
    String? existingId,
  }) async {
    if (state.isSaving) return ArticleOpResult.fail('Sauvegarde en cours…');
    state = state.copyWith(isSaving: true);

    try {
      final authorId = SupabaseConfig.currentUser?.id;
      final isInsert = existingId == null || existingId.isEmpty;

      // ⬇️ Payload enrichi avec is_published (alignement PROD)
      final payload = <String, dynamic>{
        ...draft.toPayload(isInsert: isInsert, authorId: authorId),
        'is_published': draft.status == ArticleStatus.published,
      };

      if (isInsert) {
        final res = await SupabaseConfig.client
            .from(kTable)
            .insert(payload)
            .select();
        final id = (res as List).first['id'].toString();
        state = state.copyWith(isSaving: false);
        await loadArticles(refresh: true);
        return ArticleOpResult.ok(id);
      } else {
        await SupabaseConfig.client
            .from(kTable)
            .update(payload)
            .eq('id', existingId);
        state = state.copyWith(isSaving: false);
        await loadArticles(refresh: true);
        return ArticleOpResult.ok(existingId);
      }
    } catch (e, stack) {
      _logError('saveArticle', e, stack);
      state = state.copyWith(isSaving: false);
      return ArticleOpResult.fail(_fmtError(e));
    }
  }

  // ─── SUPPRESSION ───
  Future<ArticleOpResult> deleteArticle(String id) async {
    try {
      await SupabaseConfig.client.from(kTable).delete().eq('id', id);
      state = state.copyWith(
        articles: state.articles.where((a) => a.id != id).toList(),
      );
      return ArticleOpResult.ok();
    } catch (e, stack) {
      _logError('deleteArticle', e, stack);
      return ArticleOpResult.fail(_fmtError(e));
    }
  }

  // ─── TOGGLES RAPIDES (à la une / breaking / statut) ───
  Future<ArticleOpResult> updateFlags(
    String id, {
    bool? isFeatured,
    bool? isBreaking,
    String? status,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (isFeatured != null) payload['is_featured'] = isFeatured;
      if (isBreaking != null) payload['is_breaking'] = isBreaking;
      if (status != null) {
        payload['status'] = status;
        // ⬇️ AJOUT : synchroniser is_published avec le statut
        payload['is_published'] = status == ArticleStatus.published;
      }
      if (payload.isEmpty) return ArticleOpResult.ok();

      await SupabaseConfig.client.from(kTable).update(payload).eq('id', id);

      state = state.copyWith(
        articles: state.articles.map((a) {
          if (a.id != id) return a;
          return a.copyWith(
            isFeatured: isFeatured,
            isBreaking: isBreaking,
            status: status,
          );
        }).toList(),
      );
      return ArticleOpResult.ok();
    } catch (e, stack) {
      _logError('updateFlags', e, stack);
      return ArticleOpResult.fail(_fmtError(e));
    }
  }

  // ─── UPLOAD IMAGE (Storage) ───
  Future<ArticleOpResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? extension,
  }) async {
    if (state.isUploading) return ArticleOpResult.fail('Upload en cours…');
    state = state.copyWith(isUploading: true);

    try {
      final ext = (extension ?? 'jpg').toLowerCase();
      final contentType = _mimeImage(ext);
      final path =
          'articles/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url =
          SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
      state = state.copyWith(isUploading: false);
      return ArticleOpResult.ok(url);
    } catch (e, stack) {
      _logError('uploadImage', e, stack);
      state = state.copyWith(isUploading: false);
      return ArticleOpResult.fail(_fmtError(e));
    }
  }

  // ─── UPLOAD VIDÉO / AUDIO (NOUVEAU) ───
  Future<ArticleOpResult> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    String? extension,
  }) async {
    if (state.isUploading) return ArticleOpResult.fail('Upload en cours…');

    // Vérification taille (max 100 MB pour les podcasts/vidéos)
    final sizeMB = bytes.length / (1024 * 1024);
    if (sizeMB > 100) {
      return ArticleOpResult.fail(
          'Fichier trop volumineux (${sizeMB.toStringAsFixed(1)} MB, max 100 MB)');
    }

    state = state.copyWith(isUploading: true);

    try {
      final ext = (extension ?? 'mp4').toLowerCase();
      final contentType = _mimeMedia(ext);
      final path =
          'media/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url =
          SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
      state = state.copyWith(isUploading: false);
      return ArticleOpResult.ok(url);
    } catch (e, stack) {
      _logError('uploadVideo', e, stack);
      state = state.copyWith(isUploading: false);
      return ArticleOpResult.fail(_fmtError(e));
    }
  }

  String _mimeImage(String ext) {
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

  String _mimeMedia(String ext) {
    switch (ext) {
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      // Vidéo
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  String _fmtError(dynamic e) {
    if (e is PostgrestException) return e.message;
    if (e is StorageException) return e.message;
    return 'Erreur inattendue : ${e.toString()}';
  }

  void _logError(String src, Object e, StackTrace? st) {
    if (!kDebugMode) return;
    debugPrint('❌ [Articles/$src] $e');
    if (st != null) debugPrint(st.toString());
  }
}

/// 🎯 Providers
final articlesProvider =
    StateNotifierProvider<ArticlesNotifier, ArticlesState>((ref) {
  return ArticlesNotifier();
});

/// 🏷️ Catégories (incluant les 3 espaces)
final articlesCategoriesProvider = Provider<List<String>>((ref) => const [
      'Annonces officielles',
      'Actualités',
      // ⬇️ ESPACES SPÉCIAUX (affichés dans Magazine/Podcasts/Découverte sur PROD)
      'Magazine',
      'Podcast',
      'Découverte',
      // ── Catégories classiques ──
      'Politique',
      'Économie',
      'Santé',
      'Éducation',
      'Technologie',
      'Sports',
      'Culture',
      'Maintenance',
    ]);
