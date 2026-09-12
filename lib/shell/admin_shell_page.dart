import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../supabase/supabase_config.dart';
import '../features/dashboard/pages/admin_dashboard_page.dart';
import '../features/users/pages/admin_users_page.dart';
import '../features/certifications/pages/admin_certifications_page.dart';
import '../features/articles/pages/admin_articles_page.dart';
import '../features/audit/pages/admin_audit_page.dart';
import '../features/security/pages/admin_security_page.dart';
import '../features/certifications/providers/certifications_provider.dart';
import '../features/security/providers/security_provider.dart';

/// 🧩 Définition d'un module du shell
class AdminModule {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  const AdminModule({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

/// 🏠 Shell principal de l'admin (sidebar + contenu)
class AdminShellPage extends ConsumerStatefulWidget {
  const AdminShellPage({super.key});

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  int _index = 0;

  /// 📚 Les 6 modules de l'admin
  static const List<AdminModule> _modules = [
    AdminModule(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      builder: (_) => AdminDashboardPage(),
    ),
    AdminModule(
      title: 'Utilisateurs',
      icon: Icons.people_rounded,
      builder: (_) => AdminUsersPage(),
    ),
    AdminModule(
      title: 'Certifications',
      icon: Icons.verified_rounded,
      builder: (_) => AdminCertificationsPage(),
    ),
    AdminModule(
      title: 'Articles & Annonces',
      icon: Icons.article_rounded,
      builder: (_) => AdminArticlesPage(),
    ),
    AdminModule(
      title: 'Journal d\'audit',
      icon: Icons.receipt_long_rounded,
      builder: (_) => AdminAuditPage(),
    ),
    AdminModule(
      title: 'Sécurité',
      icon: Icons.shield_rounded,
      builder: (_) => AdminSecurityPage(),
    ),
  ];

  /// 🔢 Badges dynamiques par module
  int _badgeFor(int index) {
    switch (index) {
      case 2: // Certifications : demandes en attente
        return ref.watch(certificationsProvider).items
            .where((c) => c.state == CertState.pending)
            .length;
      case 5: // Sécurité : menaces actives
        return ref.watch(securityProvider.notifier).bruteForceThreats.length;
      default:
        return 0;
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous serez déconnecté du panneau d\'administration.',
            style: TextStyle(fontSize: 13.5)),
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
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await SupabaseConfig.client.auth.signOut();
    // L'AdminAuthGate redirige automatiquement vers le login
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      // ── Drawer pour mobile ──
      drawer: isDesktop ? null : Drawer(backgroundColor: AppColors.primary, child: _sidebar()),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const Text('THIX ADMIN',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
      body: Row(
        children: [
          // ── Sidebar fixe desktop ──
          if (isDesktop) _sidebar(),
          // ── Contenu (IndexedStack = état conservé) ──
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (final m in _modules) Builder(builder: m.builder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🧭 Sidebar commune (desktop + drawer)
  Widget _sidebar() {
    return Container(
      width: 240,
      color: AppColors.primary,
      child: Column(
        children: [
          // ── Logo ─
          Container(
            height: 72,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Row(
              children: [
                Icon(Icons.shield_moon_rounded, color: AppColors.secondary, size: 26),
                SizedBox(width: 10),
                Text(
                  'THIX ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // ── Navigation ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _modules.length,
              itemBuilder: (_, i) {
                final m = _modules[i];
                final selected = i == _index;
                final badge = _badgeFor(i);
                return InkWell(
                  onTap: () {
                    setState(() => _index = i);
                    if (!MediaQuery.of(context).size.width.isFinite ||
                        MediaQuery.of(context).size.width < 900) {
                      Navigator.pop(context); // ferme le drawer
                    }
                  },
                  child: Container(
                    color: selected ? Colors.white10 : Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(m.icon,
                            size: 18,
                            color: selected
                                ? AppColors.secondary
                                : Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.title,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (badge > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$badge',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Déconnexion ──
          const Divider(height: 1, color: Colors.white12),
          InkWell(
            onTap: _logout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Déconnexion',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
