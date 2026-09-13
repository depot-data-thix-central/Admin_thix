// lib/features/opportunities/pages/opportunity_form_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/admin_opportunity.dart';
import '../providers/opportunities_provider.dart';

class OpportunityFormPage extends ConsumerStatefulWidget {
  final AdminOpportunity? opportunity;

  const OpportunityFormPage({super.key, this.opportunity});

  @override
  ConsumerState<OpportunityFormPage> createState() => _OpportunityFormPageState();
}

class _OpportunityFormPageState extends ConsumerState<OpportunityFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _organizerCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _rewardCtrl;
  late final TextEditingController _deadlineLabelCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _eligibilityCtrl;
  late final TextEditingController _applyUrlCtrl;

  late String _category;
  late String _status;
  late DateTime _deadline;
  String? _imageUrl;

  bool get _isEditing => widget.opportunity != null;

  @override
  void initState() {
    super.initState();
    final o = widget.opportunity;
    _titleCtrl = TextEditingController(text: o?.title ?? '');
    _organizerCtrl = TextEditingController(text: o?.organizer ?? '');
    _locationCtrl = TextEditingController(text: o?.location ?? '');
    _rewardCtrl = TextEditingController(text: o?.rewardLabel ?? '');
    _deadlineLabelCtrl = TextEditingController(text: o?.deadlineLabel ?? '');
    _descriptionCtrl = TextEditingController(text: o?.description ?? '');
    _eligibilityCtrl = TextEditingController(
        text: (o?.eligibility ?? const <String>[]).join('\n'));
    _applyUrlCtrl = TextEditingController(text: o?.applyUrl ?? '');

    final cats = ref.read(opportunitiesCategoriesProvider);
    _category = cats.contains(o?.category) ? o!.category : cats.first;
    _status = o?.status ?? OpportunityStatus.draft;
    _deadline = o?.deadline ?? DateTime.now().add(const Duration(days: 30));
    _imageUrl = o?.imageUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _organizerCtrl.dispose();
    _locationCtrl.dispose();
    _rewardCtrl.dispose();
    _deadlineLabelCtrl.dispose();
    _descriptionCtrl.dispose();
    _eligibilityCtrl.dispose();
    _applyUrlCtrl.dispose();
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
      final res = await ref.read(opportunitiesProvider.notifier).uploadImage(
            bytes: bytes,
            fileName: file.name,
            extension: file.extension,
          );
      if (!mounted) return;
      if (res.success && res.id != null) {
        setState(() => _imageUrl = res.id);
        _snack('✅ Image téléversée', AppColors.success);
      } else {
        _snack('❌ ${res.error}', AppColors.danger);
      }
    } catch (e) {
      if (mounted) _snack('❌ Erreur : $e', AppColors.danger);
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = AdminOpportunity(
      id: widget.opportunity?.id ?? '',
      title: _titleCtrl.text.trim(),
      organizer: _organizerCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      category: _category,
      rewardLabel: _rewardCtrl.text.trim(),
      deadlineLabel: _deadlineLabelCtrl.text.trim(),
      deadline: _deadline,
      description: _descriptionCtrl.text,
      eligibility: _eligibilityCtrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      applyUrl: _applyUrlCtrl.text.trim().isEmpty ? null : _applyUrlCtrl.text.trim(),
      imageUrl: _imageUrl,
      status: _status,
      createdAt: widget.opportunity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final res = await ref.read(opportunitiesProvider.notifier).save(
          draft: draft,
          existingId: widget.opportunity?.id,
        );

    if (!mounted) return;
    if (res.success) {
      _snack(
        _isEditing ? '✅ Offre mise à jour' : '✅ Offre créée avec succès',
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
    final state = ref.watch(opportunitiesProvider);
    final categories = ref.watch(opportunitiesCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'offre' : 'Nouvelle offre'),
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
            // ── Titre ──
            TextFormField(
              controller: _titleCtrl,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Titre de l\'offre *'),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Le titre doit contenir au moins 5 caractères'
                  : null,
            ),
            const SizedBox(height: 12),
            // ── Organisateur ──
            TextFormField(
              controller: _organizerCtrl,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Organisateur *',
                hintText: 'ex : UNESCO, Fondation Gates',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Organisateur requis'
                  : null,
            ),
            const SizedBox(height: 12),
            // ── Lieu ──
            TextFormField(
              controller: _locationCtrl,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Lieu',
                hintText: 'ex : Kinshasa, RDC / En ligne',
              ),
            ),
            const SizedBox(height: 16),

            // ── Catégorie + Statut ──
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
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: OpportunityStatus.all
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(OpportunityStatus.label(s))))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Récompense + deadline label ──
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rewardCtrl,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Récompense',
                      hintText: 'ex : 10 000 USD, Stage rémunéré',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _deadlineLabelCtrl,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Libellé échéance',
                      hintText: 'ex : 30 avril 2026',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Date deadline ──
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date limite *',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(_fmtDate(_deadline),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Image ──
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
                  const Text('Image de couverture',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (_imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_imageUrl!,
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
                            : (_imageUrl == null
                                ? 'Choisir une image'
                                : 'Remplacer')),
                      ),
                      if (_imageUrl != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _imageUrl = null),
                          child: const Text('Retirer'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Description complète *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Minimum 20 caractères'
                  : null,
            ),
            const SizedBox(height: 12),

            // ── Éligibilité ──
            TextFormField(
              controller: _eligibilityCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Critères d\'éligibilité (1 par ligne)',
                alignLabelWithHint: true,
                hintText: 'Être âgé de 18 à 35 ans\nÊtre résident d\'un pays africain',
              ),
            ),
            const SizedBox(height: 12),

            // ── URL candidature ──
            TextFormField(
              controller: _applyUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de candidature',
                hintText: 'https://site-officiel.com/apply',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _save,
                child: Text(
                  _isEditing ? 'Enregistrer les modifications' : 'Publier l\'offre',
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

  String _fmtDate(DateTime d) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
