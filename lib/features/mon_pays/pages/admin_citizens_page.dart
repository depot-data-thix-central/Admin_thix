// lib/features/mon_pays/pages/admin_citizens_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_colors.dart';
import '../providers/citizens_provider.dart'; // ✅ Décommenté et corrigé

class AdminCitizensPage extends ConsumerWidget {
  const AdminCitizensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizensAsync = ref.watch(citizensProvider); // ✅ Utilise le vrai provider
    
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
            onPressed: () => context.push('/mon-pays/citizens/form'),
            tooltip: 'Ajouter un citoyen',
          ),
        ],
      ),
      body: citizensAsync.when(
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
                onPressed: () => ref.invalidate(citizensProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (citizens) {
          if (citizens.isEmpty) {
            return const Center(
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
            );
          }
          return ListView.builder(
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
                      (c.fullName ?? 'C').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 16),
                    ),
                  ),
                  title: Text(c.fullName ?? 'Nom inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(c.domain ?? 'Domaine non spécifié', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => context.push('/mon-pays/citizens/form', extra: c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
