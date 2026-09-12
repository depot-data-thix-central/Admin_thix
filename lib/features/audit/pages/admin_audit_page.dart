import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/audit_event.dart';
import '../providers/audit_provider.dart';
import '../widgets/audit_event_tile.dart';

/// 📓 Page Journal d'audit
class AdminAuditPage extends ConsumerStatefulWidget {
  const AdminAuditPage({super.key});

  @override
  ConsumerState<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends ConsumerState<AdminAuditPage> {
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
      ref.read(auditProvider.notifier).loadMore();
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  Future<void> _exportCsv() async {
    final csv = ref.read(auditProvider.notifier).buildCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    _snack('📤 CSV copié dans le presse-papier (${ref.read(auditProvider).events.length} lignes)',
        AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditProvider);
    final notifier = ref.read(auditProvider.notifier);
    final counts = notifier.categoryCounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          // ── Header ─
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Journal d\'audit',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF101840),
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('Traçabilité des actions utilisateurs (immutable, 90 j)',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export CSV'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: state.isLoading ? null : notifier.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),

          // ── Stats rapides ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                _chip('${notifier.total24h}', 'événements 24 h', AppColors.primary),
                const SizedBox(width: 8),
                _chip('${notifier.activeUsers24h}', 'utilisateurs actifs 24 h',
                    AppColors.success),
                const SizedBox(width: 8),
                _chip('${state.events.length}', 'chargés (7 j)', AppColors.info),
              ],
            ),
          ),

          // ── Filtres ──
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
                    onChanged: (v) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350),
                          () => notifier.setSearch(v));
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher : THIX ID, utilisateur, action…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      FilterChip(
                        selected: state.category == null,
                        onSelected: (_) => notifier.setCategory(null),
                        label: const Text('Tout', style: TextStyle(fontSize: 11.5)),
                      ),
                      for (final c in AuditCategory.all)
                        if ((counts[c] ?? 0) > 0)
                          FilterChip(
                            selected: state.category == c,
                            onSelected: (_) =>
                                notifier.setCategory(state.category == c ? null : c),
                            avatar: Icon(AuditCategory.icon(c),
                                size: 13, color: AuditCategory.color(c)),
                            label: Text(
                                '${AuditCategory.label(c)} (${counts[c]})',
                                style: const TextStyle(fontSize: 11.5)),
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
              onRefresh: notifier.refresh,
              child: _buildList(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AuditState state, AuditNotifier notifier) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: List.generate(8, (_) => const _Skeleton()),
      );
    }
    if (state.error != null && state.events.isEmpty) {
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
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('Aucun événement d\'audit',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Intégrez AuditReporter dans l\'app mobile pour alimenter le journal',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: state.events.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= state.events.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final e = state.events[i];
        return AuditEventTile(
          event: e,
          onTap: () => showAuditDetails(context, e),
        );
      },
    );
  }

  Widget _chip(String value, String label, Color color) {
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
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
              width: 36, height: 36, color: const Color(0xFFF3F4F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 200, color: const Color(0xFFF3F4F6)),
                const SizedBox(height: 6),
                Container(height: 10, width: 260, color: const Color(0xFFF3F4F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
