import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';
import '../providers/articles_provider.dart';
import '../widgets/article_filters_bar.dart';
import '../widgets/article_list_tile.dart';
import 'article_form_page.dart';
import 'article_preview_page.dart';

/// 📋 Page liste des articles & annonces
class AdminArticlesPage extends ConsumerStatefulWidget {
  const AdminArticlesPage({super.key});

  @override
  ConsumerState<AdminArticlesPage> createState() => _AdminArticlesPageState();
}

class _AdminArticlesPageState extends ConsumerState<AdminArticlesPage> {
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(articlesProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(articlesProvider).filters;
      ref
          .read(articlesProvider.notifier)
          .setFilters(current.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesProvider);
    final notifier = ref.read(articlesProvider.notifier);
    final categories = ref.watch(articlesCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles & Annonces',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101840),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Publiez et gérez les annonces officielles THIX',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvel article'),
                ),
              ],
            ),
          ),

          // ── Filtres ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: ArticleFiltersBar(
              filters: state.filters,
              categories: categories,
              onSearch: _onSearch,
              onStatus: (v) => notifier.setFilters(
                  state.filters.copyWith(status: v, clearStatus: v == null)),
              onCategory: (v) => notifier.setFilters(state.filters
                  .copyWith(category: v, clearCategory: v == null)),
              onToggleFeatured: () => notifier.setFilters(state.filters
                  .copyWith(
                      featured: state.filters.featured == true ? null : true,
                      clearFeatured: state.filters.featured == true)),
              onToggleBreaking: () => notifier.setFilters(state.filters
                  .copyWith(
                      breaking: state.filters.breaking == true ? null : true,
                      clearBreaking: state.filters.breaking == true)),
            ),
          ),

          // ── Liste ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.loadArticles(refresh: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ArticlesState state, ArticlesNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(5, (_) => const _ListTileSkeleton()),
      );
    }

    if (state.error != null && state.articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => notifier.loadArticles(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Aucun article trouvé',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101840),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.filters.isEmpty
                  ? 'Publiez votre première annonce officielle'
                  : 'Aucun résultat pour ces filtres',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouvel article'),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final a in state.articles)
          ArticleListTile(
            article: a,
            onEdit: () => _openForm(a),
            onPreview: () => _openPreview(a),
            onDelete: () => _confirmDelete(a),
            onToggleFeatured: () =>
                notifier.updateFlags(a.id, isFeatured: !a.isFeatured),
            onToggleBreaking: () =>
                notifier.updateFlags(a.id, isBreaking: !a.isBreaking),
            onTogglePublish: () => notifier.updateFlags(
              a.id,
              status: a.isPublished
                  ? ArticleStatus.draft
                  : ArticleStatus.published,
            ),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!state.hasMore && state.articles.length > 20)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                '— Fin de la liste (${state.articles.length} articles) —',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ),
      ],
    );
  }

  // ─── NAVIGATION ───
  Future<void> _openForm(AdminArticle? article) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ArticleFormPage(article: article),
      ),
    );
    if (changed == true && mounted) {
      ref.read(articlesProvider.notifier).loadArticles(refresh: true);
    }
  }

  void _openPreview(AdminArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticlePreviewPage(article: article)),
    );
  }

  // ─── SUPPRESSION AVEC CONFIRMATION ───
  Future<void> _confirmDelete(AdminArticle article) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet article ?'),
        content: Text(
          '« ${article.title} » sera définitivement supprimé. Cette action est irréversible.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result =
        await ref.read(articlesProvider.notifier).deleteArticle(article.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '✅ Article supprimé'
            : '❌ ${result.error}'),
        backgroundColor: result.success ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

/// ⏳ Skeleton de ligne
class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                Container(height: 10, width: 180, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(height: 16, width: 120, color: Colors.grey.shade200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
