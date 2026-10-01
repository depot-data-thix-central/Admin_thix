import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../models/historical_figure.dart';
import '../providers/historical_figures_provider.dart';
import '../widgets/historical_figure_list_tile.dart';
import 'historical_figure_form_page.dart';

/// 📋 Page liste des figures historiques
class AdminHistoricalFiguresPage extends ConsumerStatefulWidget {
  const AdminHistoricalFiguresPage({super.key});

  @override
  ConsumerState<AdminHistoricalFiguresPage> createState() =>
      _AdminHistoricalFiguresPageState();
}

class _AdminHistoricalFiguresPageState
    extends ConsumerState<AdminHistoricalFiguresPage> {
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
      ref.read(historicalFiguresProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(historicalFiguresProvider).filters;
      ref
          .read(historicalFiguresProvider.notifier)
          .setFilters(current.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicalFiguresProvider);
    final notifier = ref.read(historicalFiguresProvider.notifier);
    final categories = ref.watch(historicalFiguresCategoriesProvider);

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
                        'Figures Historiques',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101840),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez les héros et figures marquantes de la RDC',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle figure'),
                ),
              ],
            ),
          ),

          // ── Filtres ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une figure…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.filters.category,
                      hint: const Text('Catégorie', style: TextStyle(fontSize: 13)),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Toutes', style: TextStyle(fontSize: 13)),
                        ),
                        ...categories.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (v) => notifier.setFilters(
                          state.filters.copyWith(category: v, clearCategory: v == null)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Liste ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.loadFigures(refresh: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HistoricalFiguresState state, HistoricalFiguresNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(5, (_) => const _ListTileSkeleton()),
      );
    }

    if (state.error != null && state.figures.isEmpty) {
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
              onPressed: () => notifier.loadFigures(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.figures.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_edu_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Aucune figure trouvée',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101840),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.filters.isEmpty
                  ? 'Ajoutez la première figure historique'
                  : 'Aucun résultat pour ces filtres',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouvelle figure'),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final f in state.figures)
          HistoricalFigureListTile(
            figure: f,
            onEdit: () => _openForm(f),
            onDelete: () => _confirmDelete(f),
            onToggleActive: () => notifier.toggleActive(f.id, !f.isActive),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!state.hasMore && state.figures.length > 20)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                '— Fin de la liste (${state.figures.length} figures) —',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openForm(HistoricalFigure? figure) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HistoricalFigureFormPage(figure: figure),
      ),
    );
    if (changed == true && mounted) {
      ref.read(historicalFiguresProvider.notifier).loadFigures(refresh: true);
    }
  }

  Future<void> _confirmDelete(HistoricalFigure figure) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette figure ?'),
        content: Text(
          '« ${figure.fullName} » sera définitivement supprimé. Cette action est irréversible.',
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

    final result = await ref
        .read(historicalFiguresProvider.notifier)
        .deleteFigure(figure.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '✅ Figure supprimée'
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
