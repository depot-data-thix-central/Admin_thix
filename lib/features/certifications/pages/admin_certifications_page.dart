import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/admin_certification.dart';
import '../providers/certifications_provider.dart';

/// 🏅 Page Certifications complète
class AdminCertificationsPage extends ConsumerStatefulWidget {
  const AdminCertificationsPage({super.key});

  @override
  ConsumerState<AdminCertificationsPage> createState() =>
      _AdminCertificationsPageState();
}

class _AdminCertificationsPageState
    extends ConsumerState<AdminCertificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = CertStateFilter.values;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _snack(String msg, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.danger));
  }

  String _tabLabel(CertStateFilter f) {
    switch (f) {
      case CertStateFilter.pending:
        return 'À valider';
      case CertStateFilter.active:
        return 'Actives';
      case CertStateFilter.expiring:
        return 'Expire bientôt';
      case CertStateFilter.suspended:
        return 'Suspendues';
      case CertStateFilter.expired:
        return 'Expirées';
      case CertStateFilter.history:
        return 'Historique';
      case CertStateFilter.all:
        return 'Toutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certificationsProvider);
    final notifier = ref.read(certificationsProvider.notifier);

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
                      Text('Certifications',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF101840),
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text(
                          'Demandes, types, encours, suspensions temporaires, révocations',
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

          // ── Recherche + filtre type ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: notifier.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Nom ou THIX ID…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.tierFilter,
                      hint: const Text('Type : tous',
                          style: TextStyle(fontSize: 12.5)),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                            value: CertTier.premium,
                            child: Text('Premium',
                                style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(
                            value: CertTier.entreprise,
                            child: Text('Entreprise',
                                style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(
                            value: CertTier.gratuit,
                            child: Text('Gratuit',
                                style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: notifier.setTier,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Onglets avec compteurs ──
          TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              for (final f in _tabs)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_tabLabel(f),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: f == CertStateFilter.pending &&
                                  notifier.countOf(f) > 0
                              ? AppColors.danger
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${notifier.countOf(f)}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: f == CertStateFilter.pending &&
                                        notifier.countOf(f) > 0
                                    ? Colors.white
                                    : Colors.grey.shade700)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      for (final f in _tabs) _buildList(notifier.byState(f), notifier),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AdminCertification> items, CertificationsNotifier n) {
    if (items.isEmpty) {
      return Center(
        child: Text('Aucune certification dans cette catégorie',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (_, i) => _tile(items[i], n),
    );
  }

  Widget _tile(AdminCertification c, CertificationsNotifier n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF3F4F6),
                backgroundImage: c.avatarUrl != null
                    ? NetworkImage(c.avatarUrl!)
                    : null,
                child: c.avatarUrl == null
                    ? Text(c.displayName.isNotEmpty
                        ? c.displayName[0].toUpperCase()
                        : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.displayName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${c.thixId} • ${c.accountType == 'enterprise' ? 'Entreprise' : 'Particulier'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _badge(c.tier, CertTier.color(c.tier)),
              const SizedBox(width: 6),
              _badge(c.stateLabel, c.stateColor),
            ],
          ),
          const Divider(height: 20),

          // ── Dates & infos ──
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _info('Début', c.fmt(c.startsAt)),
              _info('Expiration', c.fmt(c.expiresAt)),
              if (c.expiresAt != null && !c.isExpired)
                _info('Jours restants', '${c.daysLeft} j',
                    color: c.daysLeft <= 30 ? AppColors.warning : AppColors.success),
              if (c.isSuspended)
                _info(
                    'Suspension',
                    c.suspendedUntil == null
                        ? 'Définitive'
                        : 'Jusqu\'au ${c.fmt(c.suspendedUntil)}',
                    color: AppColors.danger),
              if (c.autoRenew) _info('Renouvellement', 'Auto'),
            ],
          ),
          if (c.suspensionReason != null && c.suspensionReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Motif : ${c.suspensionReason}',
                  style: TextStyle(fontSize: 11, color: AppColors.danger)),
            ),
          const SizedBox(height: 10),

          // ── ACTIONS ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _actions(c, n),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(AdminCertification c, CertificationsNotifier n) {
    final acts = <Widget>[];

    if (c.state == CertState.pending) {
      acts.add(_btn('✅ Approuver', AppColors.success,
          () => _approveDialog(c, n)));
      acts.add(_btn('❌ Refuser', AppColors.danger,
          () => _reasonDialog(c, n, 'Refuser la demande', n.reject)));
      acts.add(_btn('🗑️ Supprimer la demande', Colors.grey, () async {
        final ok = await _confirm('Supprimer cette demande ?',
            'La demande de ${c.displayName} sera définitivement supprimée.');
        if (ok == true) {
          _snack('Demande supprimée', await n.deleteRequest(c.userId));
        }
      }));
    }

    if (c.state == CertState.active || c.state == CertState.expiring) {
      acts.add(_btn('⏸️ Suspendre', AppColors.warning,
          () => _suspendDialog(c, n)));
      acts.add(_btn('⏱️ Prolonger', AppColors.info,
          () => _extendDialog(c, n)));
      acts.add(_btn('🗑️ Révoquer', AppColors.danger,
          () => _reasonDialog(c, n, 'Révoquer la certification', n.revoke)));
    }

    if (c.state == CertState.suspended) {
      acts.add(_btn('▶️ Réactiver', AppColors.success, () async {
        _snack('Certification réactivée', await n.reactivate(c.userId));
      }));
      acts.add(_btn('🗑️ Révoquer', AppColors.danger,
          () => _reasonDialog(c, n, 'Révoquer la certification', n.revoke)));
    }

    if (c.state == CertState.expired) {
      acts.add(_btn('🔄 Renouveler', AppColors.primary,
          () => _approveDialog(c, n, renew: true));
      );
      acts.add(_btn('🗑️ Révoquer', AppColors.danger,
          () => _reasonDialog(c, n, 'Révoquer la certification', n.revoke)));
    }

    if (c.state == CertState.revoked || c.state == CertState.rejected) {
      acts.add(_btn('♻️ Rétablir', AppColors.primary,
          () => _approveDialog(c, n, renew: true)));
    }

    return acts;
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

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _info(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label : ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color ?? const Color(0xFF101840))),
      ],
    );
  }

  // ═══════════════ DIALOGUES ═══════════════

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

  Future<void> _approveDialog(AdminCertification c, CertificationsNotifier n,
      {bool renew = false}) async {
    int months = CertTier.defaultMonths(c.tier);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(renew ? 'Renouveler' : 'Approuver la certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${c.displayName} — type ${CertTier.label(c.tier)}',
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: months,
                decoration: const InputDecoration(labelText: 'Durée'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 mois')),
                  DropdownMenuItem(value: 3, child: Text('3 mois')),
                  DropdownMenuItem(value: 6, child: Text('6 mois')),
                  DropdownMenuItem(value: 12, child: Text('12 mois')),
                ],
                onChanged: (v) => setSt(() => months = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _snack('Certification approuvée',
                    await n.approve(c.userId, c.tier, months));
              },
              child: const Text('Approuver'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendDialog(
      AdminCertification c, CertificationsNotifier n) async {
    int? days = 30;
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('⏸️ Suspendre la certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.displayName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: days,
                decoration: const InputDecoration(labelText: 'Durée'),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 jours')),
                  DropdownMenuItem(value: 30, child: Text('30 jours')),
                  DropdownMenuItem(value: 90, child: Text('90 jours')),
                  DropdownMenuItem(value: null, child: Text('Définitive')),
                ],
                onChanged: (v) => setSt(() => days = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Motif'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                _snack(
                    'Certification suspendue',
                    await n.suspend(c.userId, days,
                        reasonCtrl.text.trim()));
              },
              child: const Text('Suspendre'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extendDialog(
      AdminCertification c, CertificationsNotifier n) async {
    int days = 30;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('⏱️ Prolonger'),
          content: DropdownButtonFormField<int>(
            initialValue: days,
            items: const [
              DropdownMenuItem(value: 30, child: Text('+30 jours')),
              DropdownMenuItem(value: 90, child: Text('+90 jours')),
              DropdownMenuItem(value: 180, child: Text('+180 jours')),
              DropdownMenuItem(value: 365, child: Text('+1 an')),
            ],
            onChanged: (v) => setSt(() => days = v!),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _snack('Certification prolongée',
                    await n.extend(c.userId, c.expiresAt ?? DateTime.now(), days));
              },
              child: const Text('Prolonger'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reasonDialog(
    AdminCertification c,
    CertificationsNotifier n,
    String title,
    Future<bool> Function(String, String) action,
  ) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Motif (obligatoire)'),
        ),
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
    if (ok == true) {
      _snack(title, await action(c.userId, ctrl.text.trim()));
    }
  }
}
