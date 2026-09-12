import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/features/certifications/pages/admin_enterprise_certifications_page.dart';
import 'package:thix_admin/features/dashboard/pages/admin_dashboard_page.dart';
import 'package:thix_admin/features/articles/pages/admin_articles_page.dart'; 
import 'package:thix_admin/features/users/pages/admin_users_page.dart';
import 'package:thix_admin/features/security/pages/admin_security_page.dart';
import 'package:thix_admin/features/audit/pages/admin_audit_page.dart';

class AdminModule {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  const AdminModule({required this.title, required this.icon, required this.builder});
}

/// Menu central — chaque futur module admin (modération, utilisateurs,
/// litiges de paiement...) s'ajoute ici comme une entrée de la liste,
/// sans toucher au reste de la structure.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selected = 0;

  static final _modules = <AdminModule>[
    AdminModule(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      builder: (_) => const AdminDashboardPage(),
    ),
    AdminModule(
      title: 'Utilisateurs',
      icon: Icons.people_rounded,
      builder: (_) => const AdminUsersPage(),
    ),
    AdminModule(
      title: 'Certifications Entreprise',
      icon: Icons.business_center_rounded,
      builder: (_) => const AdminEnterpriseCertificationsPage(),
    ),
    AdminModule(
      title: 'Articles & Annonces',
      icon: Icons.article_rounded,
      builder: (_) => const AdminArticlesPage(),
    ),
    AdminModule(
      title: 'Journal d\'audit',
      icon: Icons.receipt_long_rounded,
      builder: (_) => const AdminAuditPage(),
    ),
    AdminModule(
      title: 'Sécurité',
      icon: Icons.shield_rounded,
      builder: (_) => const AdminSecurityPage(),
    ),
    // Prochains modules à ajouter ici, ex :
    // AdminModule(title: 'Articles', icon: Icons.article_rounded, builder: (_) => const AdminArticlesPage()),
    // AdminModule(title: 'Utilisateurs', icon: Icons.people_rounded, builder: (_) => const AdminUsersPage()),
    // AdminModule(title: 'Modération', icon: Icons.flag_rounded, builder: (_) => const AdminModerationPage()),
    // AdminModule(title: 'Annonces', icon: Icons.campaign_rounded, builder: (_) => const AdminAnnouncementsPage()),
    // AdminModule(title: 'Statistiques', icon: Icons.bar_chart_rounded, builder: (_) => const AdminStatisticsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.enterprise,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'THIX ADMIN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    ),
                  ),
                  for (int i = 0; i < _modules.length; i++)
                    _MenuItem(
                      module: _modules[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton.icon(
                      onPressed: () => Supabase.instance.client.auth.signOut(),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      label: const Text('Déconnexion', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: _modules[_selected].builder),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final AdminModule module;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({required this.module, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(module.icon, size: 18, color: selected ? AppColors.primary : Colors.white60),
              const SizedBox(width: 12),
              Text(
                module.title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
