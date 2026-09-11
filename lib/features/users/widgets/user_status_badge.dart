import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_user_profile.dart';

/// 🏷️ Badges de statut / rôle / certification d'un utilisateur
class UserStatusBadge extends StatelessWidget {
  final AdminUserProfile user;
  final bool showRole;

  const UserStatusBadge({super.key, required this.user, this.showRole = true});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _buildChips(),
    );
  }

  /// ✅ Construction par méthode : évite les pièges if/else dans les collections
  List<Widget> _buildChips() {
    final chips = <Widget>[];

    if (showRole && user.isAdmin) {
      chips.add(_chip('Admin', AppColors.primary, Icons.shield_rounded));
    }

    if (user.isPendingDeletion) {
      chips.add(_chip('Suppression', AppColors.danger, Icons.delete_forever_rounded));
    } else if (user.isSuspended) {
      chips.add(_chip('Suspendu', AppColors.danger, Icons.block_rounded));
    } else {
      chips.add(_chip('Actif', AppColors.success, Icons.check_circle_rounded));
    }

    if (user.isCertified) {
      chips.add(_chip(_tierLabel(), _tierColor(), Icons.verified_rounded));
    }

    if (user.isEnterprise) {
      chips.add(_chip('Entreprise', AppColors.enterprise, Icons.business_rounded));
    }

    return chips;
  }

  String _tierLabel() {
    switch (user.certificationTier) {
      case 'premium':
        return 'Premium';
      case 'entreprise':
        return 'Entreprise certifiée';
      default:
        return 'Certifié';
    }
  }

  Color _tierColor() {
    switch (user.certificationTier) {
      case 'premium':
        return AppColors.certGold;
      case 'entreprise':
        return AppColors.enterprise;
      default:
        return AppColors.info;
    }
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
