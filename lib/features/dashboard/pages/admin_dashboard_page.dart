import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/activity_chart.dart';
import '../widgets/alerts_panel.dart';
import '../widgets/stat_card.dart';

/// 🏠 Page Dashboard Admin
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📍 Header
              _buildHeader(state, notifier),
              const SizedBox(height: 24),

              // ⚠️ Erreur
              if (state.error != null) _buildError(state.error!, notifier),
              if (state.error != null) const SizedBox(height: 16),

              // ⏳ Premier chargement (skeleton)
              if (state.isFirstLoad) _buildSkeletonGrid(),

              // 📊 Cartes de statistiques
              if (state.stats != null && !state.isFirstLoad) ...[
                _buildStatsGrid(state.stats!),
                const SizedBox(height: 24),

                // 📈 Graphique + Alertes
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: ActivityChart(
                              activities: state.stats!.weeklyActivity,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: AlertsPanel(
                              alerts: state.stats!.alerts,
                              onRefresh: notifier.refresh,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        ActivityChart(
                          activities: state.stats!.weeklyActivity,
                        ),
                        const SizedBox(height: 16),
                        AlertsPanel(
                          alerts: state.stats!.alerts,
                          onRefresh: notifier.refresh,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ── Footer : dernière mise à jour (formatage SÉCURISÉ) ──
                if (state.lastRefresh != null)
                  Center(
                    child: Text(
                      'Dernière mise à jour : ${_formatLastRefresh(state.lastRefresh!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📍 HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(DashboardState state, DashboardNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF101840),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Vue d\'ensemble de la plateforme THIX',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (state.isPullToRefresh) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mise à jour…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (state.lastRefresh != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'À jour',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: state.isLoading ? null : notifier.refresh,
          icon: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text('Rafraîchir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ⏳ SKELETON (premier chargement)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSkeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 768;
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.6 : 1.4,
          // ✅ CORRECTION : const sur chaque élément, pas sur List.generate
          children: List.generate(4, (_) => const StatCardSkeleton()),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📊 GRILLE DE STATISTIQUES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsGrid(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 768;
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.6 : 1.4,
          children: [
            StatCard(
              title: 'Total Utilisateurs',
              value: _formatNumber(stats.totalUsers),
              icon: Icons.people_rounded,
              color: AppColors.primary,
              subtitle: '+${stats.newUsersToday} aujourd\'hui',
              change: stats.newUsersToday > 0 ? 12 : null,
            ),
            StatCard(
              title: 'Articles Publiés',
              value: _formatNumber(stats.totalArticles),
              icon: Icons.article_rounded,
              color: AppColors.enterprise,
              subtitle: '+${stats.newArticlesThisWeek} cette semaine',
              change: stats.newArticlesThisWeek > 0 ? 8 : null,
            ),
            StatCard(
              title: 'Posts Réseau',
              value: _formatNumber(stats.totalPosts),
              icon: Icons.forum_rounded,
              color: const Color(0xFF8B5CF6),
              subtitle: '+${stats.newPostsThisWeek} cette semaine',
              change: stats.newPostsThisWeek > 0 ? 15 : null,
            ),
            StatCard(
              title: 'Signalements',
              value: _formatNumber(stats.pendingReports),
              icon: Icons.flag_rounded,
              color: stats.pendingReports > 10
                  ? AppColors.danger
                  : AppColors.warning,
              subtitle: stats.pendingReports > 0 ? 'À traiter' : 'Aucun',
              change: stats.pendingReports > 10 ? -5 : null,
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚠️ BANNIÈRE D'ERREUR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildError(String error, DashboardNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.danger.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🛠️ HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// 🔢 Formatage des grands nombres (1.2K, 3.4M)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// 📅 CORRECTION : Formatage de date SÉCURISÉ
  /// (fallback manuel si la locale fr_FR n'est pas initialisée)
  String _formatLastRefresh(DateTime dt) {
    try {
      return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(dt);
    } catch (_) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/${dt.year} à $h:$min';
    }
  }
}
