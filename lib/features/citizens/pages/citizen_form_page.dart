import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../models/exemplary_citizen.dart';
import '../providers/citizens_provider.dart';

/// ✏️ Formulaire de création / édition de citoyen
class CitizenFormPage extends ConsumerStatefulWidget {
  final ExemplaryCitizen? citizen;

  const CitizenFormPage({super.key, this.citizen});

  @override
  ConsumerState<CitizenFormPage> createState() => _CitizenFormPageState();
}

class _CitizenFormPageState extends ConsumerState<CitizenFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _shortDescCtrl;
  late final TextEditingController _biographyCtrl;

  late String _domain;
  late bool _isActive;
  late DateTime _recognitionDate;
  String? _photoUrl;

  bool get _isEditing => widget.citizen != null;

  @override
  void initState() {
    super.initState();
    final c = widget.citizen;
    _fullNameCtrl = TextEditingController(text: c?.fullName ?? '');
    _shortDescCtrl = TextEditingController(text: c?.shortDescription ?? '');
    _biographyCtrl = TextEditingController(text: c?.biography ?? '');
    _domain = c?.domain ?? 'Général';
    _isActive = c?.isActive ?? true;
    _recognitionDate = c?.recognitionDate ?? DateTime.now();
    _photoUrl = c?.photoUrl;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _shortDescCtrl.dispose();
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
      final res = await ref.read(citizensProvider.notifier).uploadImage(
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recognitionDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _recognitionDate = date);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = ExemplaryCitizen(
      id: widget.citizen?.id ?? '',
      fullName: _fullNameCtrl.text.trim(),
      domain: _domain,
      shortDescription: _shortDescCtrl.text.trim().isEmpty
          ? null
          : _shortDescCtrl.text.trim(),
      biography: _biographyCtrl.text,
      photoUrl: _photoUrl,
      recognitionDate: _recognitionDate,
      media: widget.citizen?.media ?? const [],
      isActive: _isActive,
      createdAt: widget.citizen?.createdAt ?? DateTime.now(),
    );

    final res = await ref.read(citizensProvider.notifier).saveCitizen(
          draft: draft,
          existingId: widget.citizen?.id,
        );

    if (!mounted) return;
    if (res.success) {
      _snack(
        _isEditing ? '✅ Citoyen mis à jour' : '✅ Citoyen créé avec succès',
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
    final state = ref.watch(citizensProvider);
    final domains = ref.watch(citizensDomainsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le citoyen' : 'Nouveau citoyen'),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: domains.contains(_domain) ? _domain : null,
                    hint: Text(_domain),
                    decoration: const InputDecoration(labelText: 'Domaine *'),
                    items: domains
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _domain = v!),
                    validator: (v) => v == null ? 'Domaine requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de reconnaissance',
                      ),
                      child: Text(
                        '${_recognitionDate.day.toString().padLeft(2, '0')}/${_recognitionDate.month.toString().padLeft(2, '0')}/${_recognitionDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
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
                  const Text('Photo du citoyen',
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

            // ── DESCRIPTION COURTE ──
            TextFormField(
              controller: _shortDescCtrl,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description courte (affiché dans la carte)',
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
                title: const Text('Citoyen actif',
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
                      : 'Ajouter le citoyen',
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
