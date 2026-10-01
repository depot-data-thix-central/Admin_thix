// lib/features/mon_pays/pages/admin_citizens_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_colors.dart';

// Note: Remplace cet import par ton vrai provider de citoyens quand il sera créé
// import '../providers/citizens_provider.dart';

class AdminCitizensPage extends ConsumerWidget {
  const AdminCitizensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remplace 'citizensProvider' par ton vrai provider
    // final citizensAsync = ref.watch(citizensProvider);
    
    // Pour l'instant, on utilise une liste vide pour que le build passe
    final citizens = <Map<String, dynamic>>[]; 

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101840),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Fierté de la Nation',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              // context.push('/mon-pays/citizens/form');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Formulaire citoyen à implémenter')),
              );
            },
            tooltip: 'Ajouter un citoyen',
          ),
        ],
      ),
      body: citizens.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun citoyen enregistré.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cliquez sur + pour ajouter un profil.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: citizens.length,
              itemBuilder: (context, index) {
                final c = citizens[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.gold.withOpacity(0.1),
                      child: Text(
                        (c['full_name'] ?? 'C').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 16),
                      ),
                    ),
                    title: Text(c['full_name'] ?? 'Nom inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(c['domain'] ?? 'Domaine non spécifié', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {
                      // context.push('/mon-pays/citizens/form', extra: c);
                    },
                  ),
                );
              },
            ),
    );
  }
}
