// lib/features/opportunities/widgets/opportunity_filters_bar.dart
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/admin_opportunity.dart';
import '../providers/opportunities_provider.dart';

class OpportunityFiltersBar extends StatelessWidget {
  final OpportunitiesFilters filters;
  final List<String> categories;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onCategory;

  const OpportunityFiltersBar({
    super.key,
    required this.filters,
    required this.categories,
    required this.onSearch,
    required this.onStatus,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher par titre, organisateur…',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _dropdown(
          value: filters.status,
          hint: 'Statut',
          items: OpportunityStatus.all
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(OpportunityStatus.label(s),
                      style: const TextStyle(fontSize: 12.5))))
              .toList(),
          onChanged: onStatus,
        ),
        const SizedBox(width: 8),
        _dropdown(
          value: filters.category,
          hint: 'Catégorie',
          items: categories
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 12.5))))
              .toList(),
          onChanged: onCategory,
        ),
      ],
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
        color: Colors.white,
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
}
