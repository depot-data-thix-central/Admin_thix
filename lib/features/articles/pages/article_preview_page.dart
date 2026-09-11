import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';
import '../widgets/article_status_badge.dart';

/// 👁️ Prévisualisation d'un article (rendu proche de l'app mobile)
class ArticlePreviewPage extends StatelessWidget {
  final AdminArticle article;

  const ArticlePreviewPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final paragraphs = article.content
        .split(RegExp(r'\n{2,}'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Prévisualisation')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Badges ──
          ArticleStatusBadge(
            status: article.status,
            showFlags: true,
            isFeatured: article.isFeatured,
            isBreaking: article.isBreaking,
          ),
          const SizedBox(height: 12),

          // ── Titre ──
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF101840),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // ── Méta ──
          Text(
            '${article.category} • ${article.formattedDate}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // ── Image ──
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (article.imageUrl != null) const SizedBox(height: 16),

          // ── Résumé ──
          if (article.summary != null && article.summary!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                article.summary!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
          if (article.summary != null) const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 8),

          // ── Contenu ──
          for (final p in paragraphs) ...[
            Text(
              p,
              style: const TextStyle(fontSize: 15, height: 1.7),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 24),
          Center(
            child: Text(
              '— Fin de l\'article —',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
