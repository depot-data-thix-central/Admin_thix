// lib/features/mon_pays/pages/admin_provinces_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../providers/provinces_provider.dart';
import 'admin_province_form_page.dart'; // ✅ Ajouté

class AdminProvincesPage extends ConsumerWidget {
  const AdminProvincesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provincesAsync = ref.watch(provincesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101840),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Provinces de la RDC',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProvinceFormPage(),
                ),
              );
            },
            tooltip: 'Ajouter une province',
          ),
        ],
      ),
      body: provincesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: $e', style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(provincesProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (provinces) {
          if (provinces.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune province trouvée.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provinces.length,
            itemBuilder: (context, index) {
              final p = provinces[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      p.code.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14),
                    ),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Capitale: ${p.capital} • Région: ${p.region}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    // ✅ Navigation vers le formulaire d'édition
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProvinceFormPage(province: p),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
