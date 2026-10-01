import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../models/historical_figure.dart';

/// 📋 Ligne de liste d'une figure historique avec actions
class HistoricalFigureListTile extends StatelessWidget {
  final HistoricalFigure figure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const HistoricalFigureListTile({
    super.key,
    required this.figure,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
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
          // ── Photo ──
          _avatar(),
          const SizedBox(width: 12),

          // ── Contenu ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  figure.fullName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101840),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${figure.role} • ${figure.era}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: figure.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    figure.isActive ? '✓ Actif' : '✗ Inactif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: figure.isActive ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
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
                case 'toggle':
                  onToggleActive();
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
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    figure.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: figure.isActive ? Colors.grey : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    figure.isActive ? 'Désactiver' : 'Activer',
                    style: const TextStyle(fontSize: 13),
                  ),
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

  Widget _avatar() {
    if (figure.photoUrl != null && figure.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          figure.photoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.person_outline, color: Colors.grey, size: 32),
    );
  }
}
