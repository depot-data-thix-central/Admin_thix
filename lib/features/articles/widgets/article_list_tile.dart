import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';
import 'article_status_badge.dart';

/// 📋 Ligne de liste d'un article avec actions
class ArticleListTile extends StatelessWidget {
  final AdminArticle article;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;
  final VoidCallback onToggleBreaking;
  final VoidCallback onTogglePublish;

  const ArticleListTile({
    super.key,
    required this.article,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
    required this.onToggleFeatured,
    required this.onToggleBreaking,
    required this.onTogglePublish,
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
          // ── Vignette ──
          _thumbnail(),
          const SizedBox(width: 12),

          // ── Contenu ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
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
                  '${article.category} • ${article.formattedDate} • 👁 ${article.viewsCount} vues',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ArticleStatusBadge(
                  status: article.status,
                  showFlags: true,
                  isFeatured: article.isFeatured,
                  isBreaking: article.isBreaking,
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
                case 'preview':
                  onPreview();
                  break;
                case 'featured':
                  onToggleFeatured();
                  break;
                case 'breaking':
                  onToggleBreaking();
                  break;
                case 'publish':
                  onTogglePublish();
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
                value: 'featured',
                child: Row(children: [
                  Icon(
                    article.isFeatured ? Icons.star : Icons.star_outline,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.isFeatured
                        ? 'Retirer de la une'
                        : 'Mettre à la une',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
              ),
              PopupMenuItem(
                value: 'breaking',
                child: Row(children: [
                  Icon(
                    article.isBreaking ? Icons.bolt : Icons.bolt_outlined,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.isBreaking
                        ? 'Retirer breaking'
                        : 'Marquer breaking',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
              ),
              PopupMenuItem(
                value: 'publish',
                child: Row(children: [
                  Icon(
                    article.isPublished
                        ? Icons.archive_outlined
                        : Icons.publish_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.isPublished ? 'Dépublier' : 'Publier',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  const Text('Supprimer',
                      style: TextStyle(fontSize: 13, color: AppColors.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          article.imageUrl!,
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
      child: const Icon(Icons.article_outlined, color: Colors.grey, size: 24),
    );
  }
}
