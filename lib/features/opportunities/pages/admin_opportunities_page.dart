// lib/features/opportunities/pages/admin_opportunities_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/admin_opportunity.dart';
import '../providers/opportunities_provider.dart';
import '../widgets/opportunity_filters_bar.dart';
import '../widgets/opportunity_list_tile.dart';
import 'opportunity_form_page.dart';

class AdminOpportunitiesPage extends ConsumerStatefulWidget {
  const AdminOpportunitiesPage({super.key});

  @override
  ConsumerState<AdminOpportunitiesPage> createState() =>
      _AdminOpportunitiesPageState();
}

class _AdminOpportunitiesPageState extends ConsumerState<AdminOpportunitiesPage> {
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
      ref.read(opportunitiesProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(opportunitiesProvider).filters;
      ref
          .read(opportunitiesProvider.notifier)
          .setFilters(current.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(opportunitiesProvider);
    final notifier = ref.read(opportunitiesProvider.notifier);
    final categories = ref.watch(opportunitiesCategoriesProvider);

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
                      Text('Opportunités',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101840),
                            letterSpacing: -0.5,
                          )),
                      SizedBox(height: 4),
                      Text('Gestion des bourses, emplois, subventions & concours',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle offre'),
                ),
              ],
            ),
          ),

          // ── Stats rapides ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _statsStrip(state.items),
          ),

          // ── Filtres ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: OpportunityFiltersBar(
              filters: state.filters,
              categories: categories,
              onSearch: _onSearch,
              onStatus: (v) => notifier.setFilters(
                  state.filters.copyWith(status: v, clearStatus: v == null)),
              onCategory: (v) => notifier.setFilters(state.filters
                  .copyWith(category: v, clearCategory: v == null)),
            ),
          ),

          // ── Liste ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.load(refresh: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsStrip(List<AdminOpportunity> items) {
    final pub = items.where((o) => o.isVisible).length;
    final draft = items.where((o) => o.isDraft).length;
    final closing = items.where((o) => o.isClosing).length;
    return Row(
      children: [
        _stat('Publiées', '$pub', Icons.check_circle_outline_rounded, AppColors.success),
        const SizedBox(width: 12),
        _stat('Brouillons', '$draft', Icons.edit_note_rounded, AppColors.warning),
        const SizedBox(width: 12),
        _stat('< 7 j', '$closing', Icons.schedule_rounded, AppColors.danger),
        const SizedBox(width: 12),
        _stat('Total', '${items.length}', Icons.layers_rounded, AppColors.info),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(OpportunitiesState state, OpportunitiesNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(5, (_) => const _ListTileSkeleton()),
      );
    }
    if (state.error != null && state.items.isEmpty) {
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
              onPressed: () => notifier.load(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucune opportunité',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101840))),
            const SizedBox(height: 4),
            Text(
                state.filters.isEmpty
                    ? 'Créez votre première offre (bourse, emploi, subvention…)'
                    : 'Aucun résultat pour ces filtres',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouvelle offre'),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final o in state.items)
          OpportunityListTile(
            item: o,
            onEdit: () => _openForm(o),
            onPreview: () => _openPreview(o),
            onDelete: () => _confirmDelete(o),
            onPublish: () => notifier.updateStatus(
              o.id,
              o.isVisible ? OpportunityStatus.draft : OpportunityStatus.published,
            ),
            onArchive: () => notifier.updateStatus(o.id, OpportunityStatus.archived),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!state.hasMore && state.items.length > 20)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                '— Fin de la liste (${state.items.length} offres) —',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openForm(AdminOpportunity? opportunity) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OpportunityFormPage(opportunity: opportunity),
      ),
    );
    if (changed == true && mounted) {
      ref.read(opportunitiesProvider.notifier).load(refresh: true);
    }
  }

  void _openPreview(AdminOpportunity o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(o.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${o.organizer} • ${o.location}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 8),
                if (o.imageUrl != null)
                  Image.network(o.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                const SizedBox(height: 12),
                Text('Catégorie : ${o.category}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Récompense : ${o.rewardLabel.isEmpty ? "—" : o.rewardLabel}'),
                Text('Échéance : ${o.deadlineLabel.isEmpty ? "—" : o.deadlineLabel}'),
                const SizedBox(height: 12),
                const Divider(),
                Text(o.description, style: const TextStyle(height: 1.5)),
                if (o.eligibility.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Éligibilité :',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  for (final e in o.eligibility) Text('• $e'),
                ],
                if (o.applyUrl != null) ...[
                  const SizedBox(height: 12),
                  Text('URL : ${o.applyUrl}',
                      style: const TextStyle(color: Colors.blue)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminOpportunity o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette offre ?'),
        content: Text(
          '« ${o.title} » sera définitivement supprimée. Cette action est irréversible.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
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
        await ref.read(opportunitiesProvider.notifier).delete(o.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '✅ Offre supprimée' : '❌ ${result.error}'),
        backgroundColor: result.success ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

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
          Container(width: 4, height: 64, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Container(width: 64, height: 64, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: Colors.grey.shade200),
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
