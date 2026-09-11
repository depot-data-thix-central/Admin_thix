import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../models/admin_article.dart';
import '../providers/articles_provider.dart';

/// ✏️ Formulaire de création / édition d'article
class ArticleFormPage extends ConsumerStatefulWidget {
  final AdminArticle? article; // null = création

  const ArticleFormPage({super.key, this.article});

  @override
  ConsumerState<ArticleFormPage> createState() => _ArticleFormPageState();
}

class _ArticleFormPageState extends ConsumerState<ArticleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _videoCtrl;

  late String _category;
  late String _status;
  late bool _isFeatured;
  late bool _isBreaking;
  late DateTime _publishedAt;
  String? _imageUrl;

  bool get _isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _summaryCtrl = TextEditingController(text: a?.summary ?? '');
    _contentCtrl = TextEditingController(text: a?.content ?? '');
    _videoCtrl = TextEditingController(text: a?.videoUrl ?? '');
    _category = a?.category ?? 'Annonces officielles';
    _status = a?.status ?? ArticleStatus.draft;
    _isFeatured = a?.isFeatured ?? false;
    _isBreaking = a?.isBreaking ?? false;
    _publishedAt = a?.publishedAt ?? DateTime.now();
    _imageUrl = a?.imageUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  // ─── UPLOAD IMAGE ───
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

      final res = await ref.read(articlesProvider.notifier).uploadImage(
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

  // ─── DATE DE PUBLICATION ───
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_publishedAt),
    );
    if (time == null) return;

    setState(() {
      _publishedAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // ─── SAUVEGARDE ───
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = AdminArticle(
      id: widget.article?.id ?? '',
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim().isEmpty
          ? null
          : _summaryCtrl.text.trim(),
      content: _contentCtrl.text,
      category: _category,
      imageUrl: _imageUrl,
      videoUrl: _videoCtrl.text.trim().isEmpty
          ? null
          : _videoCtrl.text.trim(),
      viewsCount: widget.article?.viewsCount ?? 0,
      isFeatured: _isFeatured,
      isBreaking: _isBreaking,
      status: _status,
      publishedAt: _publishedAt,
      createdAt: widget.article?.createdAt ?? DateTime.now(),
      createdBy: widget.article?.createdBy,
    );

    final res = await ref.read(articlesProvider.notifier).saveArticle(
          draft: draft,
          existingId: widget.article?.id,
        );

    if (!mounted) return;
    if (res.success) {
      _snack(
        _isEditing ? '✅ Article mis à jour' : '✅ Article créé avec succès',
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
    final state = ref.watch(articlesProvider);
    final categories = ref.watch(articlesCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'article' : 'Nouvel article'),
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
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Le titre doit contenir au moins 5 caractères'
                  : null,
            ),
            const SizedBox(height: 12),

            // ── Résumé ──
            TextFormField(
              controller: _summaryCtrl,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Résumé (affiché dans les listes)',
              ),
            ),
            const SizedBox(height: 12),

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
                    items: ArticleStatus.all
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(ArticleStatus.label(s))))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Image de couverture ──
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
                  const Text(
                    'Image de couverture',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey),
                      ),
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
                                    strokeWidth: 2, color: Colors.white),
                              )
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

            // ── Contenu ──
            TextFormField(
              controller: _contentCtrl,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: 'Contenu de l\'article *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Le contenu doit contenir au moins 20 caractères'
                  : null,
            ),
            const SizedBox(height: 12),

            // ── Vidéo (optionnel) ──
            TextFormField(
              controller: _videoCtrl,
              decoration: const InputDecoration(
                labelText: 'URL vidéo (optionnel)',
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 16),

            // ── Options éditoriales ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    title: const Text('À la une',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Affiché en priorité sur l\'accueil',
                        style: TextStyle(fontSize: 11.5)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _isBreaking,
                    onChanged: (v) => setState(() => _isBreaking = v),
                    title: const Text('Breaking news',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alerte urgente mise en avant',
                        style: TextStyle(fontSize: 11.5)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  InkWell(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Publication : ${_publishedAt.day.toString().padLeft(2, '0')}/${_publishedAt.month.toString().padLeft(2, '0')}/${_publishedAt.year} à ${_publishedAt.hour.toString().padLeft(2, '0')}:${_publishedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_outlined, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Bouton principal ──
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _save,
                child: Text(
                  _isEditing ? 'Enregistrer les modifications' : 'Publier l\'article',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
