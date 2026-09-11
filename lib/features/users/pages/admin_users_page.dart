import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import 'package:features/users/models/admin_user_profile.dart';
import '../providers/users_provider.dart';
import '../widgets/user_list_tile.dart';
import 'user_detail_page.dart';

/// 👥 Page monitoring des utilisateurs
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
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
      ref.read(usersProvider.notifier).loadMore();
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final f = ref.read(usersProvider).filters;
      ref.read(usersProvider.notifier).setFilters(f.copyWith(search: v));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersProvider);
    final notifier = ref.read(usersProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          // ── Header + stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utilisateurs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101840),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monitoring des comptes — lecture & sécurité uniquement',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statChip('Total', '${state.stats.total}', AppColors.primary),
                    const SizedBox(width: 8),
                    _statChip('Admins', '${state.stats.admins}', AppColors.enterprise),
                    const SizedBox(width: 8),
                    _statChip('Suspendus', '${state.stats.suspended}', AppColors.danger),
                    const SizedBox(width: 8),
                    _statChip('Suppr.', '${state.stats.pendingDeletion}', AppColors.warning),
                  ],
                ),
              ],
            ),
          ),

          // ── Recherche + filtres ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, THIX ID…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip('Actifs', 'active', state, notifier),
                      _filterChip('Suspendus', 'suspended', state, notifier),
                      _filterChip('Suppression', 'pending_deletion', state, notifier),
                      _filterChip('Admins', 'admins', state, notifier),
                      _dropdown(
                        value: state.filters.accountType,
                        hint: 'Type : tous',
                        items: const [
                          DropdownMenuItem(value: 'personal', child: Text('Particulier', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'enterprise', child: Text('Entreprise', style: TextStyle(fontSize: 12.5))),
                        ],
                        onChanged: (v) => notifier.setFilters(state.filters
                            .copyWith(accountType: v, clearAccountType: v == null)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Liste ──
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await notifier.loadUsers(refresh: true);
                await notifier.loadStats();
              },
              child: _buildList(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(UsersState state, UsersNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(6, (_) => const _SkeletonTile()),
      );
    }

    if (state.error != null && state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(state.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => notifier.loadUsers(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('Aucun utilisateur trouvé',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final u in state.users)
          UserListTile(
            user: u,
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => UserDetailPage(user: u)),
              );
              if (changed == true && mounted) {
                notifier.loadUsers(refresh: true);
                notifier.loadStats();
              }
            },
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, String group, UsersState state, UsersNotifier notifier) {
    final active = state.filters.statusGroup == group;
    return FilterChip(
      selected: active,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (_) => notifier.setFilters(state.filters.copyWith(
          statusGroup: active ? null : group, clearStatusGroup: active)),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12.5)),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

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
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 160, color: const Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                Container(height: 10, width: 220, color: const Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                Container(height: 16, width: 140, color: const Color(0xFFF3F4F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
