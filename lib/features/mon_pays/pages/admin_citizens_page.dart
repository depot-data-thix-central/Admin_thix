// lib/features/mon_pays/pages/admin_citizens_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';

class AdminCitizensPage extends ConsumerWidget {
  const AdminCitizensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Liste temporaire pour tester l'interface
    final citizens = <Map<String, dynamic>>[
      {'fullName': 'Fally Ipupa', 'domain': 'Musique & Culture'},
      {'fullName': 'Jean Kabeya', 'domain': 'Médecine'},
      {'fullName': 'Marie Tshibangu', 'domain': 'Éducation'},
      {'fullName': 'Pierre Mbuyi', 'domain': 'Technologie'},
    ];

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
          // ✅ Bouton + maintenant cliquable
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              _showAddCitizenDialog(context);
            },
            tooltip: 'Ajouter un citoyen',
          ),
        ],
      ),
      body: citizens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun citoyen enregistré.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
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
                  child: InkWell(
                    // ✅ Rend toute la carte cliquable
                    onTap: () {
                      _showEditCitizenDialog(context, c);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.gold.withOpacity(0.1),
                        child: Text(
                          (c['fullName'] ?? 'C').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 16),
                        ),
                      ),
                      title: Text(c['fullName'] ?? 'Nom inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(c['domain'] ?? 'Domaine non spécifié', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ✅ Dialogue pour ajouter un citoyen
  void _showAddCitizenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un citoyen'),
        content: const Text('Formulaire d\'ajout à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Citoyen ajouté avec succès')),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // ✅ Dialogue pour éditer un citoyen
  void _showEditCitizenDialog(BuildContext context, Map<String, dynamic> citizen) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le citoyen'),
        content: Text('Édition de ${citizen['fullName']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${citizen['fullName']} modifié avec succès')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
