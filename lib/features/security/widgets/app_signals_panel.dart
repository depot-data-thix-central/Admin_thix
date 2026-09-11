import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../providers/security_provider.dart';

/// 📱 Panneau "État de l'application" — traque PROD, pas l'admin
class AppSignalsPanel extends StatelessWidget {
  final AppSignals signals;

  const AppSignalsPanel({super.key, required this.signals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android_rounded,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Application THIX (mobile) — 24 dernières heures',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101840)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _cell(
                'Événements sécurité',
                '${signals.mobileEvents24h}',
                signals.mobileEvents24h > 20
                    ? AppColors.danger
                    : AppColors.info,
              ),
              _cell(
                'Accès forcés',
                '${signals.mobileLoginFailures24h}',
                signals.mobileLoginFailures24h >= 5
                    ? AppColors.danger
                    : AppColors.warning,
              ),
              _cell(
                'Crashs remontés',
                '${signals.mobileErrors24h}',
                signals.mobileErrors24h > 10
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _cell('Nouveaux comptes', '${signals.newAccounts24h}',
                  AppColors.primary),
              _cell('Suspendus', '${signals.suspended}', AppColors.danger),
              _cell('Suppr. programmée', '${signals.pendingDeletion}',
                  AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
