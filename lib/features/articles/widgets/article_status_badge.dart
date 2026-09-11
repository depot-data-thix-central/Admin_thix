import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';

/// 🏷️ Badge de statut + chips "À la une" / "Breaking"
class ArticleStatusBadge extends StatelessWidget {
  final String status;
  final bool showFlags;
  final bool isFeatured;
  final bool isBreaking;

  const ArticleStatusBadge({
    super.key,
    required this.status,
    this.showFlags = false,
    this.isFeatured = false,
    this.isBreaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _chip(ArticleStatus.label(status), color, Icons.circle, filled: true),
        if (showFlags && isFeatured)
          _chip('À la une', AppColors.secondary, Icons.star_rounded),
        if (showFlags && isBreaking)
          _chip('Breaking', AppColors.danger, Icons.bolt_rounded),
      ],
    );
  }

  Widget _chip(String label, Color color, IconData icon,
      {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: filled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  static Color _color(String status) {
    switch (status) {
      case ArticleStatus.published:
        return AppColors.success;
      case ArticleStatus.archived:
        return Colors.grey;
      default:
        return AppColors.warning;
    }
  }
}
