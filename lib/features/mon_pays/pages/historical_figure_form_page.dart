import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../models/historical_figure.dart';
import '../providers/historical_figures_provider.dart';

/// ✏️ Formulaire de création / édition de figure historique
class HistoricalFigureFormPage extends ConsumerStatefulWidget {
  final HistoricalFigure? figure;

  const HistoricalFigureFormPage({super.key, this.figure});

  @override
  ConsumerState<HistoricalFigureFormPage> createState() =>
      _HistoricalFigureFormPageState();
}

class _HistoricalFigureFormPageState
    extends ConsumerState<HistoricalFigureFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _eraCtrl;
  late final TextEditingController _quoteCtrl;
  late final TextEditingController _biographyCtrl;

  late String _category;
  late bool _isActive;
  String? _photoUrl;

  bool get _isEditing => widget.figure != null;

  @override
  void initState() {
    super.initState();
    final f = widget.figure;
    _fullNameCtrl = TextEditingController(text: f?.fullName ?? '');
    _roleCtrl = TextEditingController(text: f?.role ?? '');
    _eraCtrl = TextEditingController(text: f?.era ?? '');
    _quoteCtrl = TextEditingController(text: f?.quote ?? '');
    _biographyCtrl = TextEditingController(text: f?.biography ?? '');
    _category = f?.category ?? 'Politique';
    _isActive = f?.isActive ?? true;
    _photoUrl = f?.photoUrl;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _roleCtrl.dispose();
    _eraCtrl.dispose();
    _quoteCtrl.dispose();
    _biographyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack('❌ Impossible de lire le fichier', AppColors.danger);
        return;
      }
      final res = await ref.read(historicalFiguresProvider.notifier).uploadImage(
            bytes: bytes,
            fileName: file.name,
            extension: file.extension,
          );
      if (!mounted) return;
      if (res.success && res.id != null) {
        setState(() => _photoUrl = res.id);
        _snack('✅ Image téléversée', AppColors.success);
      } else {
        _snack('❌ ${res.error}', AppColors.danger);
      }
    } catch (e) {
      if (mounted) _snack('❌ Erreur : $e', AppColors.danger);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = HistoricalFigure(
      id: widget.figure?.id ?? '',
      fullName: _fullNameCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      category: _category,
      era: _eraCtrl.text.trim(),
      quote: _quoteCtrl.text.trim().isEmpty ? null : _quoteCtrl.text.trim(),
      biography: _biographyCtrl.text,
      photoUrl: _photoUrl,
      isActive: _isActive,
      createdAt: widget.figure?.createdAt ?? DateTime.now(),
    );

    final res = await ref.read(historicalFiguresProvider.notifier).saveFigure(
          draft: draft,
          existingId: widget.figure?.id,
        );

    if (!mounted) return;
    if (res.success) {
      _snack(
        _isEditing ? '✅ Figure mise à jour' : '✅ Figure créée avec succès',
        AppColors.success,
      );
      Navigator.of(context).pop(true);
    } else {
      _snack('❌ ${res.error}', AppColors.danger);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicalFiguresProvider);
    final categories = ref.watch(historicalFiguresCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la figure' : 'Nouvelle figure'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _save,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nom complet *'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Le nom doit contenir au moins 3 caractères'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roleCtrl,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Rôle / Fonction *',
                hintText: 'Ex: 1er Premier ministre de la RDC',
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Le rôle est requis'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: categories.contains(_category) ? _category : null,
                    hint: Text(_category),
                    decoration: const InputDecoration(labelText: 'Catégorie *'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                    validator: (v) => v == null ? 'Catégorie requise' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _eraCtrl,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Époque *',
                      hintText: 'Ex: 1925 – 1961',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'L\'époque est requise'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── PHOTO ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo de la figure',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (_photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_photoUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: state.isUploading ? null : _pickImage,
                        icon: state.isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_rounded, size: 16),
                        label: Text(state.isUploading
                            ? 'Envoi…'
                            : (_photoUrl == null
                                ? 'Choisir une photo'
                                : 'Remplacer')),
                      ),
                      if (_photoUrl != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _photoUrl = null),
                          child: const Text('Retirer'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── CITATION ──
            TextFormField(
              controller: _quoteCtrl,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Citation célèbre (optionnel)',
                alignLabelWithHint: true,
                hintText: 'Ex: « Le peuple d\'abord... »',
              ),
            ),
            const SizedBox(height: 12),

            // ── BIOGRAPHIE ──
            TextFormField(
              controller: _biographyCtrl,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: 'Biographie complète *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 50)
                  ? 'La biographie doit contenir au moins 50 caractères'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── OPTIONS ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Figure active',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Visible dans l\'application publique',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _save,
                child: Text(
                  _isEditing
                      ? 'Enregistrer les modifications'
                      : 'Ajouter la figure',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
