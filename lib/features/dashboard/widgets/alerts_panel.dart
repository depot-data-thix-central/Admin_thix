// lib/features/dashboard/widgets/alerts_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_stats.dart';

/// ⚠️ Panneau d'alertes système
class AlertsPanel extends StatelessWidget {
  final List<SystemAlert> alerts;
  final VoidCallback? onRefresh;

  const AlertsPanel({
    super.key,
    required this.alerts,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Alertes Récentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101840),
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                  tooltip: 'Rafraîchir',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, 
                         size: 48, 
                         color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune alerte',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...alerts.map(_buildAlertItem),
        ],
      ),
    );
  }

  Widget _buildAlertItem(SystemAlert alert) {
    final colors = _getSeverityColors(alert.severity);
    final icon = _getAlertIcon(alert.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.icon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101840),
                  ),
                ),
                if (alert.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    alert.message!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM à HH:mm').format(alert.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.badge,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${alert.count}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SeverityColors _getSeverityColors(String severity) {
    switch (severity) {
      case 'critical':
        return _SeverityColors(
          background: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          icon: const Color(0xFFDC2626),
          badge: const Color(0xFFDC2626),
          text: Colors.white,
        );
      case 'high':
        return _SeverityColors(
          background: const Color(0xFFFFF7ED),
          border: const Color(0xFFFED7AA),
          icon: const Color(0xFFEA580C),
          badge: const Color(0xFFEA580C),
          text: Colors.white,
        );
      case 'medium':
        return _SeverityColors(
          background: const Color(0xFFFEFCE8),
          border: const Color(0xFFFEF08A),
          icon: const Color(0xFFCA8A04),
          badge: const Color(0xFFCA8A04),
          text: Colors.white,
        );
      default:
        return _SeverityColors(
          background: const Color(0xFFF0F9FF),
          border: const Color(0xFFBAE6FD),
          icon: const Color(0xFF0284C7),
          badge: const Color(0xFF0284C7),
          text: Colors.white,
        );
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'report':
        return Icons.flag_rounded;
      case 'certification':
        return Icons.verified_user_rounded;
      case 'user_deletion':
        return Icons.person_remove_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _SeverityColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color badge;
  final Color text;

  const _SeverityColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.badge,
    required this.text,
  });
}
