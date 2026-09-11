import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';
import '../providers/articles_provider.dart';

/// 🔍 Barre de recherche + filtres
class ArticleFiltersBar extends StatelessWidget {
  final ArticlesFilters filters;
  final List<String> categories;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onCategory;
  final VoidCallback onToggleFeatured;
  final VoidCallback onToggleBreaking;

  const ArticleFiltersBar({
    super.key,
    required this.filters,
    required this.categories,
    required this.onSearch,
    required this.onStatus,
    required this.onCategory,
    required this.onToggleFeatured,
    required this.onToggleBreaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // ── Recherche ──
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher un article par titre…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Filtres ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dropdown(
                value: filters.status,
                hint: 'Statut : tous',
                items: ArticleStatus.all
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(ArticleStatus.label(s),
                              style: const TextStyle(fontSize: 12.5)),
                        ))
                    .toList(),
                onChanged: onStatus,
              ),
              _dropdown(
                value: filters.category,
                hint: 'Catégorie : toutes',
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 12.5)),
                        ))
                    .toList(),
                onChanged: onCategory,
              ),
              _filterChip(
                label: 'À la une',
                icon: Icons.star_rounded,
                active: filters.featured == true,
                onTap: onToggleFeatured,
              ),
              _filterChip(
                label: 'Breaking',
                icon: Icons.bolt_rounded,
                active: filters.breaking == true,
                onTap: onToggleBreaking,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12.5)),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: active,
      onSelected: (_) => onTap(),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 14),
      selectedColor: AppColors.secondary.withOpacity(0.25),
    );
  }
}
