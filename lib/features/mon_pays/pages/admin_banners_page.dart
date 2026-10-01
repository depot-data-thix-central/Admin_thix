import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_colors.dart';
import '../../../supabase/supabase_config.dart';

/// 🎠 Gestion des bannières hero du module Mon Pays
class AdminBannersPage extends ConsumerStatefulWidget {
  const AdminBannersPage({super.key});

  @override
  ConsumerState<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends ConsumerState<AdminBannersPage> {
  static const String kTable = 'mon_pays_banners';
  static const String kBucket = 'mon_pays_banners';

  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupabaseConfig.client
          .from(kTable)
          .select('*')
          .order('position', ascending: true);
      if (!mounted) return;
      setState(() {
        _banners = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save(Map<String, dynamic> data, [String? id]) async {
    try {
      if (id == null) {
        await SupabaseConfig.client.from(kTable).insert(data);
      } else {
        await SupabaseConfig.client.from(kTable).update(data).eq('id', id);
      }
      await _load();
      _snack('✅ Bannière enregistrée', AppColors.success);
    } catch (e) {
      _snack('❌ $e', AppColors.danger);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette bannière ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseConfig.client.from(kTable).delete().eq('id', id);
      await _load();
      _snack('✅ Bannière supprimée', AppColors.success);
    } catch (e) {
      _snack('❌ $e', AppColors.danger);
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return null;

      final path = 'banners/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await SupabaseConfig.client.storage.from(kBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
          );
      return SupabaseConfig.client.storage.from(kBucket).getPublicUrl(path);
    } catch (e) {
      _snack('❌ Upload : $e', AppColors.danger);
      return null;
    }
  }

  void _openForm([Map<String, dynamic>? banner]) async {
    final tagCtrl = TextEditingController(text: banner?['tag'] ?? 'PATRIOTISME');
    final titleCtrl = TextEditingController(text: banner?['title'] ?? '');
    final subCtrl = TextEditingController(text: banner?['subtitle'] ?? '');
    final posCtrl = TextEditingController(text: '${banner?['position'] ?? 0}');
    String? imgUrl = banner?['image_url']?.toString();
    bool active = banner?['is_active'] ?? true;
    bool uploading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner == null ? 'Nouvelle bannière' : 'Modifier la bannière',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(controller: tagCtrl, maxLength: 30,
                    decoration: const InputDecoration(labelText: 'Tag (ex: PATRIOTISME)')),
                TextField(controller: titleCtrl, maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Titre *')),
                TextField(controller: subCtrl, maxLength: 90,
                    decoration: const InputDecoration(labelText: 'Sous-titre')),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: posCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Position'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        value: active,
                        onChanged: (v) => setSheetState(() => active = v),
                        title: const Text('Active', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Image
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (imgUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imgUrl, height: 110, width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40)),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: uploading
                                ? null
                                : () async {
                                    setSheetState(() => uploading = true);
                                    final url = await _uploadImage();
                                    setSheetState(() {
                                      uploading = false;
                                      if (url != null) imgUrl = url;
                                    });
                                  },
                            icon: uploading
                                ? const SizedBox(width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.upload_rounded, size: 16),
                            label: const Text('Image'),
                          ),
                          if (imgUrl != null) ...[
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => setSheetState(() => imgUrl = null),
                              child: const Text('Retirer'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Sans image = dégradé premium automatique',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) {
                        _snack('❌ Titre requis', AppColors.danger);
                        return;
                      }
                      Navigator.pop(ctx);
                      _save({
                        'tag': tagCtrl.text.trim().isEmpty ? 'PATRIOTISME' : tagCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'subtitle': subCtrl.text.trim(),
                        'image_url': imgUrl,
                        'position': int.tryParse(posCtrl.text) ?? 0,
                        'is_active': active,
                      }, banner?['id']?.toString());
                    },
                    child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bannières Hero',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF101840))),
                      SizedBox(height: 4),
                      Text('Carrousel d\'accueil du module Mon Pays',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                            const SizedBox(height: 10),
                            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _banners.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.panorama_outlined, size: 52, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                const Text('Aucune bannière — l\'app affiche les slides par défaut',
                                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              itemCount: _banners.length,
                              itemBuilder: (_, i) {
                                final b = _banners[i];
                                final url = b['image_url']?.toString();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: const Color(0xFF12234F),
                                        ),
                                        child: url != null && url.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(url, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                        Icons.gradient_rounded, color: Colors.white38)),
                                              )
                                            : const Icon(Icons.gradient_rounded, color: Colors.white38),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${b['title']}',
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text('#${b['position']} • ${b['tag']} • ${b['is_active'] == true ? 'Active' : 'Inactive'}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        onPressed: () => _openForm(b),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                        onPressed: () => _delete('${b['id']}'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
