// lib/features/mon_pays/pages/admin_provinces_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../providers/provinces_provider.dart';

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
        title: const Text('Provinces de la RDC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/mon-pays/provinces/form'),
          ),
        ],
      ),
      body: provincesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (provinces) {
          if (provinces.isEmpty) {
            return const Center(child: Text('Aucune province trouvée.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provinces.length,
            itemBuilder: (context, index) {
              final p = provinces[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(p.code.substring(0, 2), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('Capitale: ${p.capital} • Région: ${p.region}'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => context.push('/mon-pays/provinces/form', extra: p),
                ),
              );
 a            },
          );
        },
      ),
    );
  }
}
