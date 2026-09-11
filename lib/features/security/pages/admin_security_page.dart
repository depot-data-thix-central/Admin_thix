import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/security_event.dart';
import '../providers/security_provider.dart';

/// 🛡️ Page monitoring sécurité
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
    _tabCtrl = TabController(length: 3, vsync: this);
    // Auto-refresh toutes les 60 s
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => ref.read(securityProvider.notifier).refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);
    final notifier = ref.read(securityProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sécurité & Monitoring',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101840),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Attaques, accès forcés, erreurs applicatives — auto-refresh 60 s',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (state.lastRefresh != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 5),
                        Text(
                          '${state.lastRefresh!.hour.toString().padLeft(2, '0')}:${state.lastRefresh!.minute.toString().padLeft(2, '0')}:${state.lastRefresh!.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: state.isLoading ? null : () => notifier.refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),

          // ── Tabs ─
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
                    if (notifier.bruteForceThreats.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _countDot(notifier.bruteForceThreats.length),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list_alt_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Événements', style: _tabStyle()),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_maybe_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Menaces', style: _tabStyle()),
                    if (notifier.bruteForceThreats.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _countDot(notifier.bruteForceThreats.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // ── Contenu ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverview(state, notifier),
                _buildEvents(state, notifier),
                _buildThreats(state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tabStyle() =>
      const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);

  Widget _countDot(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$n',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📊 ONGLET 1 : VUE D'ENSEMBLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOverview(SecurityState state, SecurityNotifier notifier) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final threats = notifier.bruteForceThreats;
    final topErrors = notifier.topErrors;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── 4 cartes stats ──
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.7,
          children: [
            _statCard(
              'Échecs login 24 h',
              '${notifier.loginFailed24h}',
              Icons.lock_outline_rounded,
              notifier.loginFailed24h >= 5 ? AppColors.danger : AppColors.warning,
            ),
            _statCard(
              'Erreurs app 24 h',
              '${notifier.clientErrors24h}',
              Icons.bug_report_outlined,
              AppColors.info,
            ),
            _statCard(
              'Critiques 7 j',
              '${notifier.critical7d}',
              Icons.error_outline_rounded,
              notifier.critical7d > 0 ? AppColors.danger : AppColors.success,
            ),
            _statCard(
              'Menaces actives',
              '${threats.length}',
              Icons.gpp_maybe_outlined,
              threats.isNotEmpty ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Alertes menaces ──
        if (threats.isNotEmpty) ...[
          _sectionTitle('🔑 Comptes qui forcent l\'accès', AppColors.danger),
          const SizedBox(height: 10),
          for (final t in threats.take(3)) _threatTile(t),
          const SizedBox(height: 20),
        ],

        // ── Top erreurs ──
        _sectionTitle('🐛 Top erreurs applicatives (7 j)', AppColors.info),
        const SizedBox(height: 10),
        if (topErrors.isEmpty)
          _emptyBox('Aucune erreur remontée — application stable ✅')
        else
          for (final e in topErrors) _errorTile(e),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📋 ONGLET 2 : ÉVÉNEMENTS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEvents(SecurityState state, SecurityNotifier notifier) {
    final events = notifier.filteredEvents;

    return Column(
      children: [
        // ── Filtres ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 260,
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
            ],
          ),
        ),

        // ── Liste ──
        Expanded(
          child: state.isLoading && state.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          const Text('Aucun événement enregistré',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            'Les échecs de login, erreurs et actions admin apparaîtront ici',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: events.length,
                      itemBuilder: (_, i) => _eventTile(events[i]),
                    ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🚨 ONGLET 3 : MENACES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildThreats(SecurityState state, SecurityNotifier notifier) {
    final threats = notifier.bruteForceThreats;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withOpacity(0.25)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Détection automatique : ≥ 5 échecs de connexion en 24 h pour un même identifiant = menace de brute force.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (state.isLoading && state.events.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (threats.isEmpty)
          _emptyBox('Aucune menace détectée sur les dernières 24 h ✅')
        else
          for (final t in threats) ...[
            _threatTile(t),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🧩 WIDGETS INTERNES
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionTitle(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
    );
  }

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
          Row(
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
            ],
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _threatTile(BruteForceThreat t) {
    final color = SecuritySeverity.color(t.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
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
                Text(
                  t.identifier,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101840)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  t.description,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Dernière tentative : ${_fmtDate(t.lastAttempt)}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${t.attempts}x',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorTile(AggregatedError e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bug_report_outlined, size: 16, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.message,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Dernière occurrence : ${_fmtDate(e.lastOccurrence)}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${e.count}x',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(SecurityEvent e) {
    final color = SecuritySeverity.color(e.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      child: Text(
                        SecurityEventType.label(e.eventType),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        SecuritySeverity.label(e.severity),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  e.message,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (e.identifier != null) e.identifier!,
                    if (e.ipAddress != null) 'IP ${e.ipAddress}',
                    e.relativeLabel,
                  ].join(' • '),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ),
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

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m à $h:$min';
  }
}
