// lib/features/opportunities/widgets/opportunity_status_badge.dart
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_opportunity.dart';

class OpportunityStatusBadge extends StatelessWidget {
  final String status;
  final int daysLeft;

  const OpportunityStatusBadge({
    super.key,
    required this.status,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _pill(OpportunityStatus.label(status), color),
        if (OpportunityStatus.isVisible(status)) ...[
          if (daysLeft < 0)
            _pill('Clôturée', Colors.grey.shade600)
          else if (daysLeft <= 7)
            _pill('$daysLeft j restants', AppColors.danger)
          else
            _pill('$daysLeft j', AppColors.info),
        ],
      ],
    );
  }

  Color _color() {
    switch (status) {
      case OpportunityStatus.published:
      case OpportunityStatus.countdown:
        return AppColors.success;
      case OpportunityStatus.draft:
        return AppColors.warning;
      case OpportunityStatus.archived:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color)),
    );
  }
}
