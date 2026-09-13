// lib/features/opportunities/widgets/opportunity_list_tile.dart
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_opportunity.dart';
import 'opportunity_status_badge.dart';

class OpportunityListTile extends StatelessWidget {
  final AdminOpportunity item;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onPublish;
  final VoidCallback onArchive;

  const OpportunityListTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
    required this.onPublish,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _catColor(item.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre d'accent ──
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // ── Vignette ──
          _thumbnail(accent),
          const SizedBox(width: 12),
          // ── Contenu ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101840),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    '${item.organizer} • ${item.location.isEmpty ? "—" : item.location} • ${item.formattedDate}',
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                OpportunityStatusBadge(
                    status: item.status, daysLeft: item.daysLeft),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Menu actions ──
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) {
              switch (v) {
                case 'edit':
                  onEdit();
                  break;
                case 'preview':
                  onPreview();
                  break;
                case 'publish':
                  onPublish();
                  break;
                case 'archive':
                  onArchive();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Modifier', style: TextStyle(fontSize: 13)),
                ]),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: Row(children: [
                  Icon(Icons.visibility_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Prévisualiser', style: TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'publish',
                child: Row(children: [
                  Icon(
                    item.isVisible
                        ? Icons.unpublished_outlined
                        : Icons.publish_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(item.isVisible ? 'Dépublier' : 'Publier',
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(children: [
                  const Icon(Icons.archive_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Archiver', style: TextStyle(fontSize: 13)),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Supprimer',
                      style: TextStyle(fontSize: 13, color: AppColors.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(Color accent) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(accent),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _placeholder(accent),
        ),
      );
    }
    return _placeholder(accent);
  }

  Widget _placeholder(Color accent) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.work_outline_rounded, color: accent, size: 28),
    );
  }

  Color _catColor(String c) {
    final l = c.toLowerCase();
    if (l.contains('bourse') || l.contains('formation')) return const Color(0xFF2563EB);
    if (l.contains('emploi') || l.contains('stage')) return const Color(0xFF059669);
    if (l.contains('subvention')) return const Color(0xFFD97706);
    if (l.contains('concours')) return const Color(0xFFDB2777);
    return AppColors.primary;
  }
}
