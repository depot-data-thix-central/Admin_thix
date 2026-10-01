import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../models/exemplary_citizen.dart';
import '../providers/citizens_provider.dart';
import '../widgets/citizen_list_tile.dart';
import 'citizen_form_page.dart';

/// 📋 Page liste des citoyens exemplaires
class AdminCitizensPage extends ConsumerStatefulWidget {
  const AdminCitizensPage({super.key});

  @override
  ConsumerState<AdminCitizensPage> createState() => _AdminCitizensPageState();
}

class _AdminCitizensPageState extends ConsumerState<AdminCitizensPage> {
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
      ref.read(citizensProvider.notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(citizensProvider).filters;
      ref
          .read(citizensProvider.notifier)
          .setFilters(current.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(citizensProvider);
    final notifier = ref.read(citizensProvider.notifier);
    final domains = ref.watch(citizensDomainsProvider);

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
                        'Fierté de la Nation',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101840),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez les citoyens exemplaires de la RDC',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau citoyen'),
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
                      hintText: 'Rechercher un citoyen…',
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
                      value: state.filters.domain,
                      hint: const Text('Domaine', style: TextStyle(fontSize: 13)),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous', style: TextStyle(fontSize: 13)),
                        ),
                        ...domains.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: const TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (v) => notifier.setFilters(
                          state.filters.copyWith(domain: v, clearDomain: v == null)),
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
              onRefresh: () => notifier.loadCitizens(refresh: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CitizensState state, CitizensNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(5, (_) => const _ListTileSkeleton()),
      );
    }

    if (state.error != null && state.citizens.isEmpty) {
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
              onPressed: () => notifier.loadCitizens(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.citizens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Aucun citoyen trouvé',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101840),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.filters.isEmpty
                  ? 'Ajoutez le premier citoyen exemplaire'
                  : 'Aucun résultat pour ces filtres',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouveau citoyen'),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final c in state.citizens)
          CitizenListTile(
            citizen: c,
            onEdit: () => _openForm(c),
            onDelete: () => _confirmDelete(c),
            onToggleActive: () =>
                notifier.toggleActive(c.id, !c.isActive),
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!state.hasMore && state.citizens.length > 20)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                '— Fin de la liste (${state.citizens.length} citoyens) —',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openForm(ExemplaryCitizen? citizen) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CitizenFormPage(citizen: citizen),
      ),
    );
    if (changed == true && mounted) {
      ref.read(citizensProvider.notifier).loadCitizens(refresh: true);
    }
  }

  Future<void> _confirmDelete(ExemplaryCitizen citizen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce citoyen ?'),
        content: Text(
          '« ${citizen.fullName} » sera définitivement supprimé. Cette action est irréversible.',
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
        await ref.read(citizensProvider.notifier).deleteCitizen(citizen.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '✅ Citoyen supprimé'
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
