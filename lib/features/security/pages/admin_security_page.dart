import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/security_event.dart';
import '../providers/security_provider.dart';
import '../widgets/app_signals_panel.dart';
import '../services/error_analyzer.dart';     
import 'error_detail_page.dart';              

/// 🛡️ Page monitoring sécurité + ACTIONS
class AdminSecurityPage extends ConsumerStatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  ConsumerState<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends ConsumerState<AdminSecurityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => ref.read(securityProvider.notifier).refresh(silent: true),
    );
  }

  // _fmtDate est maintenant une méthode de la classe, accessible partout dans _AdminSecurityPageState
  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m à $h:$min';
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _autoRefresh?.cancel();
    super.dispose();
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);
    final notifier = ref.read(securityProvider.notifier);
    final threats = notifier.bruteForceThreats;
    final activeBlocks = state.blocklist.length;

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
                      Text('Sécurité & Monitoring',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF101840),
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('Détection + actions : blocage, suspension, traitement',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: state.isLoading ? null : () => notifier.refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Vue d\'ensemble', style: _tabStyle()),
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Événements', style: _tabStyle()),
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gpp_maybe_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Menaces', style: _tabStyle()),
                  if (threats.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _dot(threats.length),
                  ],
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Liste noire', style: _tabStyle()),
                  if (activeBlocks > 0) ...[
                    const SizedBox(width: 6),
                    _dot(activeBlocks),
                  ],
                ],
              )),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverview(state, notifier),
                _buildEvents(state, notifier),
                _buildThreats(state, notifier),
                _buildBlocklist(state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tabStyle() =>
      const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);

  Widget _dot(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
        child: Text('$n',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  // ═══════════════ ONGLET 1 : VUE D'ENSEMBLE ═══════════════
  Widget _buildOverview(SecurityState state, SecurityNotifier notifier) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final threats = notifier.bruteForceThreats;
    final topErrors = notifier.topErrors;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.7,
          children: [
            _statCard('Échecs login 24 h', '${notifier.loginFailed24h}',
                Icons.lock_outline_rounded,
                notifier.loginFailed24h >= 5
                    ? AppColors.danger
                    : AppColors.warning),
            _statCard('Erreurs app 24 h', '${notifier.clientErrors24h}',
                Icons.bug_report_outlined, AppColors.info),
            _statCard('Critiques 7 j', '${notifier.critical7d}',
                Icons.error_outline_rounded,
                notifier.critical7d > 0 ? AppColors.danger : AppColors.success),
            _statCard('Blocages actifs', '${state.blocklist.length}',
                Icons.block_rounded,
                state.blocklist.isNotEmpty
                    ? AppColors.danger
                    : AppColors.success),
          ],
        ),
        const SizedBox(height: 20),
        AppSignalsPanel(signals: notifier.appSignals),
        const SizedBox(height: 20),
        if (threats.isNotEmpty) ...[
          _sectionTitle('🔑 Comptes qui forcent l\'accès', AppColors.danger),
          const SizedBox(height: 10),
          for (final t in threats.take(3)) _threatTile(t, notifier, state),
          const SizedBox(height: 20),
        ],
        _sectionTitle('🐛 Top erreurs applicatives (7 j)', AppColors.info),
        const SizedBox(height: 10),
        if (topErrors.isEmpty)
          _emptyBox('Aucune erreur remontée — application stable ✅')
        else
          for (final e in topErrors) _errorTile(e),
      ],
    );
  }

  // ═══════════════ ONGLET 2 : ÉVÉNEMENTS ═══════════════
  Widget _buildEvents(SecurityState state, SecurityNotifier notifier) {
    final events = notifier.filteredEvents;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  onChanged: (v) => notifier.setFilters(search: v),
                  decoration: InputDecoration(
                    hintText: 'Identifiant, IP, message…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
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
              ),
              _dropdown(
                value: state.filterSeverity,
                hint: 'Sévérité',
                items: SecuritySeverity.all
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(SecuritySeverity.label(s),
                            style: const TextStyle(fontSize: 12.5))))
                    .toList(),
                onChanged: (v) => notifier.setFilters(severity: v),
              ),
              _dropdown(
                value: state.filterType,
                hint: 'Type',
                items: SecurityEventType.all
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(SecurityEventType.label(t),
                            style: const TextStyle(fontSize: 12.5))))
                    .toList(),
                onChanged: (v) => notifier.setFilters(type: v),
              ),
              FilterChip(
                selected: state.filterSource == null,
                onSelected: (_) => notifier.setSourceFilter(null),
                label: const Text('Toutes sources',
                    style: TextStyle(fontSize: 12)),
              ),
              FilterChip(
                selected: state.filterSource == 'mobile_app',
                onSelected: (_) => notifier.setSourceFilter('mobile_app'),
                avatar: const Icon(Icons.phone_android_rounded, size: 14),
                label: const Text('Application',
                    style: TextStyle(fontSize: 12)),
              ),
              FilterChip(
                selected: state.filterSource == 'admin_web',
                onSelected: (_) => notifier.setSourceFilter('admin_web'),
                avatar: const Icon(Icons.computer_rounded, size: 14),
                label: const Text('Admin', style: TextStyle(fontSize: 12)),
              ),
              FilterChip(
                selected: state.hideHandled,
                onSelected: notifier.setHideHandled,
                avatar: const Icon(Icons.visibility_off_outlined, size: 14),
                label: const Text('Masquer traités',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading && state.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? Center(
                      child: Icon(Icons.shield_outlined,
                          size: 56, color: Colors.grey.shade300))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: events.length,
                      itemBuilder: (_, i) => _eventTile(events[i], notifier),
                    ),
        ),
      ],
    );
  }

  // ═══════════════ ONGLET 3 : MENACES ═══════════════
  Widget _buildThreats(SecurityState state, SecurityNotifier notifier) {
    final threats = notifier.bruteForceThreats;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (state.isLoading && state.events.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (threats.isEmpty)
          _emptyBox('Aucune menace détectée sur les dernières 24 h ✅')
        else
          for (final t in threats) ...[
            _threatTile(t, notifier, state),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  // ═══════════════ ONGLET 4 : LISTE NOIRE ═══════════════
  Widget _buildBlocklist(SecurityState state, SecurityNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (state.blocklist.isEmpty)
          _emptyBox('Aucun blocage actif — aucune entrée en liste noire ✅')
        else
          for (final b in state.blocklist) ...[
            _blockTile(b, notifier),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  // ═══════════════ WIDGETS + ACTIONS ═══════════════

  Widget _threatTile(
      BruteForceThreat t, SecurityNotifier notifier, SecurityState state) {
    final color = SecuritySeverity.color(t.severity);
    final isBlocked = state.blocklist
        .any((b) => b.type == 'identifier' && b.value == t.identifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.password_rounded, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.identifier,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101840))),
                    const SizedBox(height: 3),
                    Text(t.description,
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                child: Text('${t.attempts}x',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isBlocked) ...[
                _actionBtn('⛔ Bloquer 24 h', AppColors.warning, () async {
                  final r = await notifier.blockValue(
                      type: 'identifier',
                      value: t.identifier,
                      reason: 'Brute force : ${t.attempts} tentatives',
                      duration: const Duration(hours: 24));
                  _snack(r.success ? '⛔ Bloqué 24 h' : '❌ ${r.error}',
                      r.success ? AppColors.success : AppColors.danger);
                }),
                _actionBtn('⛔ Bloquer 7 j', AppColors.warning, () async {
                  final r = await notifier.blockValue(
                      type: 'identifier',
                      value: t.identifier,
                      reason: 'Brute force : ${t.attempts} tentatives',
                      duration: const Duration(days: 7));
                  _snack(r.success ? '⛔ Bloqué 7 jours' : '❌ ${r.error}',
                      r.success ? AppColors.success : AppColors.danger);
                }),
                _actionBtn('⛔ Définitif', AppColors.danger, () async {
                  final r = await notifier.blockValue(
                      type: 'identifier',
                      value: t.identifier,
                      reason: 'Brute force : ${t.attempts} tentatives');
                  _snack(
                      r.success
                          ? '⛔ Bloqué définitivement'
                          : '❌ ${r.error}',
                      r.success ? AppColors.success : AppColors.danger);
                }),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: AppColors.success),
                      SizedBox(width: 5),
                      Text('Déjà bloqué',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ],
                  ),
                ),
              if (t.userId != null)
                _actionBtn('👤 Suspendre le compte', AppColors.danger,
                    () async {
                  final r = await notifier.suspendUser(t.userId!);
                  _snack(r.success ? '✅ Compte suspendu' : '❌ ${r.error}',
                      r.success ? AppColors.success : AppColors.danger);
                }),
              _actionBtn('✅ Marquer traité', AppColors.success, () async {
                final r = await notifier.acknowledgeByIdentifier(t.identifier);
                _snack(r.success ? '✅ Menace traitée' : '❌ ${r.error}',
                    r.success ? AppColors.success : AppColors.danger);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blockTile(SecurityBlock b, SecurityNotifier notifier) {
    final isIp = b.type == 'ip';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                isIp ? Icons.wifi_off_rounded : Icons.person_off_rounded,
                size: 20,
                color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101840))),
                const SizedBox(height: 2),
                Text(b.reason.isEmpty ? 'Blocage manuel' : b.reason,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(b.expiryLabel,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: b.isPermanent
                            ? AppColors.danger
                            : AppColors.warning)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) async {
              if (v == 'extend') {
                final r = await notifier.extendBlock(b.id, 7);
                _snack(r.success ? '⏱️ Prolongé de 7 j' : '❌ ${r.error}',
                    r.success ? AppColors.success : AppColors.danger);
              } else if (v == 'unblock') {
                final r = await notifier.unblock(b.id);
                _snack(r.success ? '🔓 Débloqué' : '❌ ${r.error}',
                    r.success ? AppColors.success : AppColors.danger);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'extend',
                  child: Text('Prolonger +7 jours',
                      style: TextStyle(fontSize: 13))),
              PopupMenuItem(
                  value: 'unblock',
                  child: Text('Débloquer',
                      style: TextStyle(fontSize: 13, color: AppColors.danger))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventTile(SecurityEvent e, SecurityNotifier notifier) {
    final color = SecuritySeverity.color(e.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: e.isHandled ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: e.isHandled
                ? const Color(0xFFEEEEEE)
                : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(SecurityEventType.icon(e.eventType),
                size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(SecurityEventType.label(e.eventType),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                    if (e.isHandled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Traité',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(SecuritySeverity.label(e.severity),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(e.message,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  [
                    if (e.identifier != null) e.identifier!,
                    if (e.ipAddress != null) 'IP ${e.ipAddress}',
                    e.source == 'mobile_app' ? '📱 APP' : '🖥️ ADMIN',
                    e.relativeLabel,
                  ].join(' • '),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── MENU D'ACTION PAR ÉVÉNEMENT ──
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (v) => _handleEventAction(v, e, notifier),
            itemBuilder: (_) => [
              if (!e.isHandled)
                const PopupMenuItem(
                    value: 'ack',
                    child: Text('✅ Marquer traité',
                        style: TextStyle(fontSize: 13))),
              // ⬇️ AJOUT : analyse d'erreur
              if (e.eventType == SecurityEventType.clientError)
                const PopupMenuItem(
                    value: 'analyze',
                    child: Text('🔬 Voir l\'analyse détaillée',
                        style: TextStyle(fontSize: 13))),
              if (e.identifier != null)
                const PopupMenuItem(
                    value: 'block_id',
                    child: Text('⛔ Bloquer l\'identifiant',
                        style: TextStyle(fontSize: 13))),
              if (e.ipAddress != null)
                const PopupMenuItem(
                    value: 'block_ip',
                    child: Text('⛔ Bloquer l\'IP',
                        style: TextStyle(fontSize: 13))),
              if (e.userId != null)
                const PopupMenuItem(
                    value: 'suspend',
                    child: Text('👤 Suspendre le compte',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.danger))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleEventAction(
      String action, SecurityEvent e, SecurityNotifier notifier) async {
    switch (action) {
      // ⬇️ AJOUT : case analyse d'erreur
      case 'analyze':
        final agg = AggregatedError(
          message: e.message.length > 90
              ? e.message.substring(0, 90)
              : e.message,
          count: 1,
          lastOccurrence: e.createdAt,
        );
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                ErrorDetailPage(error: agg, occurrences: [e])));
        return;
      case 'ack':
        final r1 = await notifier.acknowledgeEvents([e.id]);
        _snack(r1.success ? '✅ Événement traité' : '❌ ${r1.error}',
            r1.success ? AppColors.success : AppColors.danger);
        break;
      case 'block_id':
        final r2 = await notifier.blockValue(
            type: 'identifier',
            value: e.identifier!,
            reason: e.message,
            duration: const Duration(days: 7));
        _snack(r2.success ? '⛔ Identifiant bloqué 7 j' : '❌ ${r2.error}',
            r2.success ? AppColors.success : AppColors.danger);
        break;
      case 'block_ip':
        final r3 = await notifier.blockValue(
            type: 'ip',
            value: e.ipAddress!,
            reason: e.message,
            duration: const Duration(days: 7));
        _snack(r3.success ? '⛔ IP bloquée 7 j' : '❌ ${r3.error}',
            r3.success ? AppColors.success : AppColors.danger);
        break;
      case 'suspend':
        final r4 = await notifier.suspendUser(e.userId!);
        _snack(r4.success ? '✅ Compte suspendu' : '❌ ${r4.error}',
            r4.success ? AppColors.success : AppColors.danger);
        break;
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, Color color) => Text(label,
      style:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color));

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ═══════════════ 🐛 ERREUR CLIQUABLE AVEC ANALYSEUR ═══════════════
  Widget _errorTile(AggregatedError e) {
    final insight = ErrorAnalyzer.analyze(e.message);
    final color = ErrorAnalyzer.color(insight.category);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openErrorAnalysis(e),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ErrorAnalyzer.icon(insight.category),
                    size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.message,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${e.count}x',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.info)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniBadge(
                            ErrorAnalyzer.label(insight.category), color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Dernière : ${_fmtDate(e.lastOccurrence)} • toucher pour l\'analyse',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
    );
  }

  void _openErrorAnalysis(AggregatedError e) {
    final occurrences = ref
        .read(securityProvider)
        .events
        .where((ev) => ev.eventType == SecurityEventType.clientError)
        .where((ev) =>
            (ev.message.length > 90
                    ? ev.message.substring(0, 90)
                    : ev.message) ==
            e.message)
        .toList();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ErrorDetailPage(error: e, occurrences: occurrences)));
  }

  Widget _emptyBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
          child: Text(msg,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
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
        color: Colors.white,
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
