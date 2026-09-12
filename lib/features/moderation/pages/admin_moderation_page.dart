import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/moderation_item.dart';
import '../providers/moderation_provider.dart';

/// 🛡️ Page Modération
class AdminModerationPage extends ConsumerStatefulWidget {
  const AdminModerationPage({super.key});

  @override
  ConsumerState<AdminModerationPage> createState() =>
      _AdminModerationPageState();
}

class _AdminModerationPageState extends ConsumerState<AdminModerationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _snack(String msg, bool ok) {
    if (!mounted) return;
    final err = ref.read(moderationProvider).lastActionError;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? msg : (err ?? 'Échec de l\'opération')),
        backgroundColor: ok ? AppColors.success : AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationProvider);
    final notifier = ref.read(moderationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modération',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF101840),
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('Signalements de posts et commentaires',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: notifier.load,
                    icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('En attente (${notifier.pending.length})',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Traités (${notifier.handled.length})',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              )),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      _list(notifier.pending, notifier),
                      _list(notifier.handled, notifier),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<ModerationItem> items, ModerationNotifier n) {
    if (items.isEmpty) {
      return Center(
        child: Text('Aucun signalement dans cette file',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (_, i) => _tile(items[i], n),
    );
  }

  Widget _tile(ModerationItem item, ModerationNotifier n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: item.isHandled
                ? const Color(0xFFEEEEEE)
                : AppColors.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (item.contentType == 'post'
                          ? AppColors.info
                          : AppColors.secondary)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                    item.contentType == 'post'
                        ? Icons.article_outlined
                        : Icons.comment_outlined,
                    size: 17,
                    color: item.contentType == 'post'
                        ? AppColors.info
                        : AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${item.contentType == 'post' ? 'Post' : 'Commentaire'} signalé : ${item.reasonLabel}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        '${item.sourceTable} • ${item.relativeLabel}',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (item.isHandled)
                _badge(item.actionLabel, AppColors.success)
              else
                _badge('En attente', AppColors.warning),
            ],
          ),
          if (item.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.details,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('🔍 Détails', Colors.grey, () => _details(item)),
              if (!item.isHandled) ...[
                _btn('❌ Rejeter', AppColors.info, () => _dismiss(item, n)),
                _btn('🗑️ Supprimer le contenu', AppColors.danger,
                    () => _remove(item, n)),
                _btn('👤 Suspendre l\'auteur', AppColors.danger,
                    () => _suspend(item, n)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
        ),
      ),
    );
  }

  // ═══════════════ ACTIONS AVEC CONFIRMATION ═══════════════

  Future<bool?> _confirm(String title, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg, style: const TextStyle(fontSize: 13.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismiss(ModerationItem item, ModerationNotifier n) async {
    final ok = await _confirm('Rejeter le signalement ?',
        'Le contenu restera en ligne. Le signalement sera classé sans suite.');
    if (ok != true) return;
    _snack('Signalement rejeté', await n.dismiss(item));
  }

  Future<void> _remove(ModerationItem item, ModerationNotifier n) async {
    final ok = await _confirm('Supprimer le contenu ?',
        'Le ${item.contentType} signalé sera masqué de la plateforme.');
    if (ok != true) return;
    _snack('Contenu supprimé', await n.removeContent(item));
  }

  Future<void> _suspend(ModerationItem item, ModerationNotifier n) async {
    final ok = await _confirm('Suspendre l\'auteur ?',
        'Le compte auteur du contenu sera désactivé immédiatement.');
    if (ok != true) return;
    _snack('Auteur suspendu', await n.suspendAuthor(item));
  }

  void _details(ModerationItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détails du signalement'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _kv('Table source', item.sourceTable),
              _kv('ID signalement', item.id),
              _kv('Type de contenu', item.contentType),
              _kv('ID contenu', item.contentId ?? '—'),
              _kv('Signalé par', item.reporterId ?? '—'),
              _kv('Motif', item.reasonLabel),
              _kv('Détails', item.details.isEmpty ? '—' : item.details),
              _kv('Statut source', item.sourceStatus),
              _kv('Décision admin', item.actionLabel),
              const Divider(height: 20),
              const Text('Données brutes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 6),
              SelectableText(
                item.raw.toString(),
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(k,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600))),
          Expanded(
              child: SelectableText(v,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
