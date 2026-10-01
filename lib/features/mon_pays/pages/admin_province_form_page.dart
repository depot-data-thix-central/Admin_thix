// lib/features/mon_pays/pages/admin_province_form_page.dart
//
// AdminProvinceFormPage — Production Enterprise (Admin_thix)
// Version Autonome : Pas de dépendance aux modèles enfants manquants
//
// ✅ Correctifs de cette version :
// - Plus d'erreur "ON CONFLICT DO UPDATE command cannot affect row a second time"
//   (dédoublonnage par id / url avant chaque upsert)
// - Les suppressions (croix rouge / corbeille) sont enregistrées en base
// - Conversion des champs numériques / dates avant envoi
// - Colonnes alignées sur le schéma réel (achievements, ministers)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/app_colors.dart';
import '../../../supabase/supabase_config.dart';
import '../models/province.dart';
import '../providers/provinces_provider.dart';

class AdminProvinceFormPage extends ConsumerStatefulWidget {
  final Province? province;
  const AdminProvinceFormPage({super.key, this.province});

  @override
  ConsumerState<AdminProvinceFormPage> createState() =>
      _AdminProvinceFormPageState();
}

class _AdminProvinceFormPageState extends ConsumerState<AdminProvinceFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabCtrl;

  // ── Champs texte ──
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _capitalCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _populationCtrl;
  late TextEditingController _territoriesCountCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _languagesCtrl;
  late TextEditingController _resourcesCtrl;
  late TextEditingController _historyCtrl;
  late TextEditingController _climateCtrl;
  late TextEditingController _infrastructureCtrl;
  late TextEditingController _educationCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _governorCtrl;
  late TextEditingController _viceGovernorCtrl;

  String _region = 'Centre';
  static const List<String> _regions = ['Centre', 'Est', 'Ouest', 'Nord', 'Sud'];

  // ── Images ──
  String? _coverImageUrl;
  String? _coatOfArmsUrl;
  String? _mapUrl;
  String? _governorPhotoUrl;
  String? _viceGovernorPhotoUrl;

  // ── Relations imbriquées (Stockage local temporaire en Map) ──
  List<Map<String, dynamic>> _ministers = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _economicSectors = [];
  List<Map<String, dynamic>> _tourismSites = [];
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _administrativeDivisions = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _tribes = [];
  List<Map<String, dynamic>> _galleryMedia = [];

  // ids supprimés par l'utilisateur pendant cette session (table -> ids)
  final Map<String, Set<String>> _deletedIds = {};

  bool _isEditing = false;
  String? _provinceId;
  bool _isBusy = false;
  bool _isLoadingFullData = false;

  int _keyCounter = 0;
  String _newKey() => 'k${_keyCounter++}_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
    final p = widget.province;
    _isEditing = p != null;
    _provinceId = p?.id;

    _initControllers();
    if (p != null) _populateData(p);
    if (_isEditing && _provinceId != null) _loadFullData();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _capitalCtrl = TextEditingController();
    _areaCtrl = TextEditingController();
    _populationCtrl = TextEditingController();
    _territoriesCountCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _languagesCtrl = TextEditingController();
    _resourcesCtrl = TextEditingController();
    _historyCtrl = TextEditingController();
    _climateCtrl = TextEditingController();
    _infrastructureCtrl = TextEditingController();
    _educationCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _governorCtrl = TextEditingController();
    _viceGovernorCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose(); _codeCtrl.dispose(); _capitalCtrl.dispose();
    _areaCtrl.dispose(); _populationCtrl.dispose(); _territoriesCountCtrl.dispose();
    _descriptionCtrl.dispose(); _languagesCtrl.dispose(); _resourcesCtrl.dispose();
    _historyCtrl.dispose(); _climateCtrl.dispose(); _infrastructureCtrl.dispose();
    _educationCtrl.dispose(); _websiteCtrl.dispose(); _governorCtrl.dispose();
    _viceGovernorCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS DE CONVERSION
  // ═══════════════════════════════════════════════════════════════
  static bool _hasText(Map<String, dynamic> m, String key) =>
      (m[key]?.toString().trim() ?? '').isNotEmpty;

  static String? _nullIfEmpty(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    final s = v.toString().trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    return int.tryParse(s) ?? double.tryParse(s)?.toInt();
  }

  static num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    final s = v.toString().trim().replaceAll(' ', '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  static String? _toDateString(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final d = DateTime.tryParse(s);
    return d == null ? null : d.toIso8601String().substring(0, 10);
  }

  /// Nettoie une liste de médias (retire _key, supprime les URL en double).
  static List<Map<String, dynamic>> _cleanMedia(dynamic media) {
    if (media is! List) return <Map<String, dynamic>>[];
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final m in media) {
      if (m is! Map) continue;
      final copy = Map<String, dynamic>.from(m)..remove('_key');
      final url = copy['url']?.toString().trim() ?? '';
      if (url.isEmpty || !seen.add(url)) continue;
      out.add(copy);
    }
    return out;
  }

  /// Garde la première occurrence de chaque id (évite les doublons de lignes).
  static List<Map<String, dynamic>> _uniqueById(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    return list.where((m) {
      final id = m['id']?.toString().trim() ?? '';
      if (id.isEmpty) return true;
      return seen.add(id);
    }).toList();
  }

  /// Retire un élément d'une liste et mémorise son id pour le supprimer en base.
  void _removeItem(String table, List<Map<String, dynamic>> list, int i) {
    final id = list[i]['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) {
      (_deletedIds[table] ??= <String>{}).add(id);
    }
    setState(() => list.removeAt(i));
  }

  // ═══════════════════════════════════════════════════════════════
  // DONNÉES
  // ═══════════════════════════════════════════════════════════════
  void _populateData(Province p) {
    _nameCtrl.text = p.name;
    _codeCtrl.text = p.code;
    _capitalCtrl.text = p.capital;

    String safeRegion = p.region.trim();
    if (safeRegion.isNotEmpty) {
      safeRegion = safeRegion[0].toUpperCase() + safeRegion.substring(1).toLowerCase();
    }
    if (!_regions.contains(safeRegion)) safeRegion = 'Centre';
    _region = safeRegion;

    _areaCtrl.text = p.area?.toString() ?? '';
    _populationCtrl.text = p.population?.toString() ?? '';
    _territoriesCountCtrl.text = p.territoriesCount?.toString() ?? '';
    _descriptionCtrl.text = p.description ?? '';
    _languagesCtrl.text = p.languages ?? '';
    _resourcesCtrl.text = p.resources ?? '';
    _historyCtrl.text = p.history ?? '';
    _climateCtrl.text = p.climate ?? '';
    _infrastructureCtrl.text = p.infrastructure ?? '';
    _educationCtrl.text = p.education ?? '';
    _websiteCtrl.text = p.website ?? '';
    _governorCtrl.text = p.governor ?? '';
    _viceGovernorCtrl.text = p.viceGovernor ?? '';

    _coverImageUrl = p.coverImageUrl;
    _coatOfArmsUrl = p.coatOfArmsUrl;
    _mapUrl = p.mapUrl;
    _governorPhotoUrl = p.governorPhotoUrl;
    _viceGovernorPhotoUrl = p.viceGovernorPhotoUrl;

    // Mapping sécurisé sans modèles externes (+ dédoublonnage par id)
    _ministers = _uniqueById(p.ministers.map<Map<String, dynamic>>((m) => <String, dynamic>{
      '_key': _newKey(),
      'id': m['id'],
      'name': m['name'] ?? '',
      'role': m['role'] ?? '',
      'photo_url': m['photoUrl'] ?? m['photo_url'] ?? '',
    }).toList());

    _cities = _uniqueById(p.cities.map<Map<String, dynamic>>((c) => <String, dynamic>{
      '_key': _newKey(),
      'id': c.id,
      'province_id': c.provinceId,
      'name': c.name,
      'population': c.population?.toString() ?? '',
      'is_capital': c.isCapital,
      'mayor': c.mayor ?? '',
      'mayor_photo_url': c.mayorPhotoUrl ?? '',
      'media': c.media != null ? List<Map<String, dynamic>>.from(c.media!) : <Map<String, dynamic>>[],
    }).toList());

    _economicSectors = _uniqueById(p.economicResources.map<Map<String, dynamic>>((e) => <String, dynamic>{
      '_key': _newKey(),
      'id': e.id,
      'province_id': e.provinceId,
      'name': e.name,
      'description': e.description ?? '',
      'media': e.media != null ? List<Map<String, dynamic>>.from(e.media!) : <Map<String, dynamic>>[],
    }).toList());

    _tourismSites = _uniqueById(p.tourismSites.map<Map<String, dynamic>>((t) => <String, dynamic>{
      '_key': _newKey(),
      'id': t.id,
      'province_id': t.provinceId,
      'name': t.name,
      'type': t.type,
      'description': t.description ?? '',
      'media': t.media != null ? List<Map<String, dynamic>>.from(t.media!) : <Map<String, dynamic>>[],
    }).toList());

    _emergencyContacts = _uniqueById(p.emergencyContacts.map<Map<String, dynamic>>((e) => <String, dynamic>{
      '_key': _newKey(),
      'id': e.id,
      'province_id': e.provinceId,
      'service': e.service,
      'phone': e.phone,
    }).toList());

    _administrativeDivisions = _uniqueById(p.administrativeDivisions.map<Map<String, dynamic>>((a) => <String, dynamic>{
      '_key': _newKey(),
      'id': a.id,
      'province_id': a.provinceId,
      'type': a.type,
      'name': a.name,
      'capital': a.capital ?? '',
      'population': a.population?.toString() ?? '',
      'area': a.area?.toString() ?? '',
      'administrator': a.administrator ?? '',
      'media': a.media != null ? List<Map<String, dynamic>>.from(a.media!) : <Map<String, dynamic>>[],
    }).toList());

    _achievements = _uniqueById(p.achievements.map<Map<String, dynamic>>((a) => <String, dynamic>{
      '_key': _newKey(),
      'id': a['id'],
      'title': a['title'] ?? '',
      'description': a['description'] ?? '',
      'date': a['date'] ?? '',
      'location': a['location'] ?? '',
      'media': a['media'] != null ? List<Map<String, dynamic>>.from(a['media']) : <Map<String, dynamic>>[],
    }).toList());

    _tribes = _uniqueById(p.tribes.map<Map<String, dynamic>>((tr) => <String, dynamic>{
      '_key': _newKey(),
      'id': tr['id'],
      'name': tr['name'] ?? '',
      'zone': tr['zone'] ?? '',
      'history': tr['history'] ?? '',
      'media': tr['media'] != null ? List<Map<String, dynamic>>.from(tr['media']) : <Map<String, dynamic>>[],
    }).toList());

    _galleryMedia = _uniqueById(p.galleryMedia.map<Map<String, dynamic>>((m) => <String, dynamic>{
      '_key': _newKey(),
      'id': m['id'],
      'url': m['url'],
      'type': m['type'],
    }).toList());
  }

  Future<void> _loadFullData() async {
    if (!mounted) return;
    setState(() => _isLoadingFullData = true);
    try {
      final fullProvince = await ref.read(provinceWithAllRelationsProvider(_provinceId!).future);
      if (!mounted) return;
      setState(() {
        _populateData(fullProvince);
        _isLoadingFullData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFullData = false);
      _snack('⚠️ Impossible de charger les détails complets : $e', AppColors.warning);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPLOAD SUPABASE STORAGE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _uploadSingleFile(String folderName, Function(String url) onUploaded) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.first.bytes == null) return;

      setState(() => _isBusy = true);
      final file = result.files.first;
      final path = '$folderName/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await SupabaseConfig.client.storage.from('provinces').uploadBinary(
        path, file.bytes!, fileOptions: const FileOptions(upsert: true),
      );
      final url = SupabaseConfig.client.storage.from('provinces').getPublicUrl(path);
      onUploaded(url);
      setState(() => _isBusy = false);
      if (mounted) _snack('✅ Image téléversée', AppColors.success);
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) _snack('❌ Upload : $e', AppColors.danger);
    }
  }

  Future<void> _uploadMultiFiles(String folderName, Function(String url, String type) onUploaded) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true, withData: true);
      if (result == null || result.files.isEmpty) return;

      setState(() => _isBusy = true);
      for (final file in result.files) {
        if (file.bytes == null) continue;
        final ext = file.extension?.toLowerCase() ?? '';
        final type = (ext == 'mp4' || ext == 'mov' || ext == 'avi') ? 'video' : 'photo';
        final path = '$folderName/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        await SupabaseConfig.client.storage.from('provinces').uploadBinary(
          path, file.bytes!, fileOptions: const FileOptions(upsert: true),
        );
        final url = SupabaseConfig.client.storage.from('provinces').getPublicUrl(path);
        onUploaded(url, type);
      }
      setState(() => _isBusy = false);
      if (mounted) _snack('✅ Médias ajoutés', AppColors.success);
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) _snack('❌ Upload : $e', AppColors.danger);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101840),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _isEditing ? 'Modifier la province' : 'Nouvelle province',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          if (_isBusy || _isLoadingFullData)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _save,
              tooltip: 'Enregistrer',
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(text: 'Identité'),
            Tab(text: 'Histoire'),
            Tab(text: 'Gouvernance'),
            Tab(text: 'Culture'),
            Tab(text: 'Villes'),
            Tab(text: 'Économie'),
            Tab(text: 'Tourisme'),
            Tab(text: 'Admin & Autres'),
          ],
        ),
      ),
      body: _isLoadingFullData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Récupération des données...', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : Stack(
              children: [
                Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildTabIdentity(),
                      _buildTabHistory(),
                      _buildTabGovernance(),
                      _buildTabCulture(),
                      _buildTabCities(),
                      _buildTabEconomy(),
                      _buildTabTourism(),
                      _buildTabAdminAndOthers(),
                    ],
                  ),
                ),
                if (_isBusy)
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isBusy || _isLoadingFullData) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isEditing ? 'Enregistrer les modifications' : 'Créer la province',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TABS CONTENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabIdentity() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.badge_rounded, title: 'Informations de base', children: [
      _textField(_nameCtrl, 'Nom de la province *', Icons.map_outlined, required: true),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _textField(_codeCtrl, 'Code (ex: KIN) *', Icons.tag, required: true, uppercase: true)),
        const SizedBox(width: 12),
        Expanded(child: _textField(_capitalCtrl, 'Capitale *', Icons.location_city, required: true)),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _region,
        decoration: _inputDeco('Région géographique *', Icons.explore),
        items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        onChanged: (v) => setState(() => _region = v ?? 'Centre'),
        validator: (v) => v == null ? 'Requis' : null,
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _textField(_areaCtrl, 'Superficie (km²)', Icons.map_outlined, isNumber: true)),
        const SizedBox(width: 12),
        Expanded(child: _textField(_populationCtrl, 'Population', Icons.groups_rounded, isNumber: true)),
      ]),
      const SizedBox(height: 12),
      _textField(_territoriesCountCtrl, 'Nombre de territoires', Icons.format_list_numbered_rounded, isNumber: true),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.image_rounded, title: 'Identité visuelle', children: [
      _imagePickerRow('Photo de couverture', _coverImageUrl, 'covers', (url) => setState(() => _coverImageUrl = url)),
      const SizedBox(height: 12),
      _imagePickerRow('Blason / Armoiries', _coatOfArmsUrl, 'emblems', (url) => setState(() => _coatOfArmsUrl = url)),
      const SizedBox(height: 12),
      _imagePickerRow('Carte géographique', _mapUrl, 'maps', (url) => setState(() => _mapUrl = url)),
      const SizedBox(height: 12),
      _textField(_websiteCtrl, 'Site web officiel', Icons.language_rounded),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.perm_media_rounded, title: 'Galerie média globale', children: [
      _multiMediaGallery('Tous les médias', _galleryMedia, 'gallery', () => setState(() {}), deleteTable: 'province_gallery_media'),
    ]),
  ]);

  Widget _buildTabHistory() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.history_edu_rounded, title: 'Histoire, Climat & Infrastructures', children: [
      _textField(_historyCtrl, 'Historique complet & Origines', Icons.menu_book_rounded, maxLines: 4),
      const SizedBox(height: 12),
      _textField(_climateCtrl, 'Climat, Relief & Environnement', Icons.wb_sunny_rounded, maxLines: 3),
      const SizedBox(height: 12),
      _textField(_infrastructureCtrl, 'Infrastructures, Transports & Énergie', Icons.bolt_rounded, maxLines: 3),
      const SizedBox(height: 12),
      _textField(_educationCtrl, 'Éducation, Recherche & Santé', Icons.school_rounded, maxLines: 3),
    ]),
  ]);

  Widget _buildTabGovernance() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.account_balance_rounded, title: 'Exécutif provincial', children: [
      _textField(_governorCtrl, 'Nom du Gouverneur', Icons.person_rounded),
      const SizedBox(height: 8),
      _imagePickerRow('Photo du Gouverneur', _governorPhotoUrl, 'governors', (url) => setState(() => _governorPhotoUrl = url)),
      const SizedBox(height: 16),
      _textField(_viceGovernorCtrl, 'Nom du Vice-Gouverneur', Icons.person_outline_rounded),
      const SizedBox(height: 8),
      _imagePickerRow('Photo du Vice-Gouverneur', _viceGovernorPhotoUrl, 'governors', (url) => setState(() => _viceGovernorPhotoUrl = url)),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.people_alt_rounded, title: 'Ministres', action: TextButton.icon(
      onPressed: () => setState(() => _ministers.add({'_key': _newKey(), 'id': null, 'name': '', 'role': '', 'photo_url': ''})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _ministers.length; i++) ...[_ministerCard(i), if (i < _ministers.length - 1) const SizedBox(height: 12)],
      if (_ministers.isEmpty) const _EmptyHint(icon: Icons.person_add_disabled_rounded, text: 'Aucun ministre ajouté'),
    ]),
  ]);

  Widget _buildTabCulture() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.forum_rounded, title: 'Langues & Culture', children: [
      _textField(_languagesCtrl, 'Langues parlées', Icons.forum_rounded),
      const SizedBox(height: 12),
      _textField(_resourcesCtrl, 'Ressources principales', Icons.diamond_rounded),
      const SizedBox(height: 12),
      _textField(_descriptionCtrl, 'Description générale & Traditions', Icons.description_rounded, maxLines: 3),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.groups_rounded, title: 'Peuples & Tribus', action: TextButton.icon(
      onPressed: () => setState(() => _tribes.add({'_key': _newKey(), 'id': null, 'name': '', 'zone': '', 'history': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _tribes.length; i++) ...[_tribeCard(i), if (i < _tribes.length - 1) const SizedBox(height: 12)],
      if (_tribes.isEmpty) const _EmptyHint(icon: Icons.groups_2_outlined, text: 'Aucune tribu ajoutée'),
    ]),
  ]);

  Widget _buildTabCities() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.location_city_rounded, title: 'Villes principales', action: TextButton.icon(
      onPressed: () => setState(() => _cities.add({'_key': _newKey(), 'id': null, 'province_id': _provinceId, 'name': '', 'population': '', 'is_capital': false, 'mayor': '', 'mayor_photo_url': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _cities.length; i++) ...[_cityCard(i), if (i < _cities.length - 1) const SizedBox(height: 12)],
      if (_cities.isEmpty) const _EmptyHint(icon: Icons.location_city_outlined, text: 'Aucune ville ajoutée'),
    ]),
  ]);

  Widget _buildTabEconomy() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.monetization_on_rounded, title: 'Économie & Secteurs clés', action: TextButton.icon(
      onPressed: () => setState(() => _economicSectors.add({'_key': _newKey(), 'id': null, 'province_id': _provinceId, 'name': '', 'description': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _economicSectors.length; i++) ...[_sectorCard(i), if (i < _economicSectors.length - 1) const SizedBox(height: 12)],
      if (_economicSectors.isEmpty) const _EmptyHint(icon: Icons.business_outlined, text: 'Aucun secteur ajouté'),
    ]),
  ]);

  Widget _buildTabTourism() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.landscape_rounded, title: 'Tourisme & Sites remarquables', action: TextButton.icon(
      onPressed: () => setState(() => _tourismSites.add({'_key': _newKey(), 'id': null, 'province_id': _provinceId, 'name': '', 'type': '', 'description': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _tourismSites.length; i++) ...[_tourismCard(i), if (i < _tourismSites.length - 1) const SizedBox(height: 12)],
      if (_tourismSites.isEmpty) const _EmptyHint(icon: Icons.landscape_outlined, text: 'Aucun site ajouté'),
    ]),
  ]);

  Widget _buildTabAdminAndOthers() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionCard(icon: Icons.dashboard_customize_rounded, title: 'Découpage administratif', action: TextButton.icon(
      onPressed: () => setState(() => _administrativeDivisions.add({'_key': _newKey(), 'id': null, 'province_id': _provinceId, 'type': 'Territoire', 'name': '', 'capital': '', 'population': '', 'area': '', 'administrator': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _administrativeDivisions.length; i++) ...[_divisionCard(i), if (i < _administrativeDivisions.length - 1) const SizedBox(height: 12)],
      if (_administrativeDivisions.isEmpty) const _EmptyHint(icon: Icons.account_tree_outlined, text: 'Aucune division ajoutée'),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.emoji_events_rounded, title: 'Réalisations majeures', action: TextButton.icon(
      onPressed: () => setState(() => _achievements.add({'_key': _newKey(), 'id': null, 'title': '', 'description': '', 'date': '', 'location': '', 'media': <Map<String, dynamic>>[]})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _achievements.length; i++) ...[_achievementCard(i), if (i < _achievements.length - 1) const SizedBox(height: 12)],
      if (_achievements.isEmpty) const _EmptyHint(icon: Icons.emoji_events_outlined, text: 'Aucune réalisation ajoutée'),
    ]),
    const SizedBox(height: 16),
    _sectionCard(icon: Icons.emergency_rounded, title: 'Urgences & Contacts', action: TextButton.icon(
      onPressed: () => setState(() => _emergencyContacts.add({'_key': _newKey(), 'id': null, 'province_id': _provinceId, 'service': '', 'phone': ''})),
      icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Ajouter'),
    ), children: [
      for (int i = 0; i < _emergencyContacts.length; i++) ...[_emergencyCard(i), if (i < _emergencyContacts.length - 1) const SizedBox(height: 8)],
      if (_emergencyContacts.isEmpty) const _EmptyHint(icon: Icons.emergency_outlined, text: 'Aucun contact d\'urgence'),
    ]),
  ]);

  // ═══════════════════════════════════════════════════════════════
  // WIDGETS DE CARTES DYNAMIQUES
  // ═══════════════════════════════════════════════════════════════
  Widget _ministerCard(int i) {
    final m = _ministers[i];
    return Container(key: ValueKey(m['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [
        const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(child: Text('Ministre ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => setState(() => _ministers.removeAt(i))),
      ]),
      const SizedBox(height: 8),
      TextFormField(initialValue: m['name'], onChanged: (v) => _ministers[i]['name'] = v, decoration: _inputDeco('Nom complet', Icons.person_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: m['role'], onChanged: (v) => _ministers[i]['role'] = v, decoration: _inputDeco('Portefeuille', Icons.work_outline_rounded)),
      const SizedBox(height: 8),
      _imagePickerRow('Photo du ministre', m['photo_url'], 'ministers', (url) => setState(() => _ministers[i]['photo_url'] = url)),
    ]));
  }

  Widget _tribeCard(int i) {
    final t = _tribes[i];
    return Container(key: ValueKey(t['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [Text('Tribu ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('province_tribes', _tribes, i))]),
      TextFormField(initialValue: t['name'], onChanged: (v) => _tribes[i]['name'] = v, decoration: _inputDeco('Nom de la tribu', Icons.group_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: t['zone'], onChanged: (v) => _tribes[i]['zone'] = v, decoration: _inputDeco('Zone / Territoire', Icons.place_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: t['history'], onChanged: (v) => _tribes[i]['history'] = v, maxLines: 2, decoration: _inputDeco('Histoire & coutumes', Icons.menu_book_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', t['media'], 'tribes', () => setState(() {})),
    ]));
  }

  Widget _cityCard(int i) {
    final c = _cities[i];
    return Container(key: ValueKey(c['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Ville ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), Switch(value: c['is_capital'] ?? false, onChanged: (v) => setState(() => _cities[i]['is_capital'] = v), activeColor: AppColors.secondary), const Text('Chef-lieu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('cities', _cities, i))]),
      TextFormField(initialValue: c['name'], onChanged: (v) => _cities[i]['name'] = v, decoration: _inputDeco('Nom de la ville', Icons.location_city_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: c['population'], onChanged: (v) => _cities[i]['population'] = v, keyboardType: TextInputType.number, decoration: _inputDeco('Population', Icons.groups_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', c['media'], 'cities', () => setState(() {})),
      const Divider(height: 20),
      TextFormField(initialValue: c['mayor'], onChanged: (v) => _cities[i]['mayor'] = v, decoration: _inputDeco('Maire / Bourgmestre', Icons.person_rounded)),
      const SizedBox(height: 8),
      _imagePickerRow("Photo de l'autorité", c['mayor_photo_url'], 'mayors', (url) => setState(() => _cities[i]['mayor_photo_url'] = url)),
    ]));
  }

  Widget _sectorCard(int i) {
    final s = _economicSectors[i];
    return Container(key: ValueKey(s['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [Text('Secteur ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('province_economic_resources', _economicSectors, i))]),
      TextFormField(initialValue: s['name'], onChanged: (v) => _economicSectors[i]['name'] = v, decoration: _inputDeco('Nom du secteur', Icons.business_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: s['description'], onChanged: (v) => _economicSectors[i]['description'] = v, maxLines: 2, decoration: _inputDeco('Détails', Icons.notes_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', s['media'], 'economy', () => setState(() {})),
    ]));
  }

  Widget _tourismCard(int i) {
    final t = _tourismSites[i];
    return Container(key: ValueKey(t['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [Text('Site ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('province_tourism_sites', _tourismSites, i))]),
      TextFormField(initialValue: t['name'], onChanged: (v) => _tourismSites[i]['name'] = v, decoration: _inputDeco('Nom du site', Icons.place_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: t['type'], onChanged: (v) => _tourismSites[i]['type'] = v, decoration: _inputDeco('Type (Parc, Cascade...)', Icons.category_rounded)),
      const SizedBox(height: 8),
      TextFormField(initialValue: t['description'], onChanged: (v) => _tourismSites[i]['description'] = v, maxLines: 2, decoration: _inputDeco('Description', Icons.description_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', t['media'], 'tourism', () => setState(() {})),
    ]));
  }

  Widget _divisionCard(int i) {
    final d = _administrativeDivisions[i];
    return Container(key: ValueKey(d['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [Text('Division ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('province_administrative_divisions', _administrativeDivisions, i))]),
      Row(children: [Expanded(child: TextFormField(initialValue: d['type'], onChanged: (v) => _administrativeDivisions[i]['type'] = v, decoration: _inputDeco('Type', Icons.category_rounded))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: d['name'], onChanged: (v) => _administrativeDivisions[i]['name'] = v, decoration: _inputDeco('Nom', Icons.place_rounded)))]),
      const SizedBox(height: 8),
      TextFormField(initialValue: d['capital'], onChanged: (v) => _administrativeDivisions[i]['capital'] = v, decoration: _inputDeco('Chef-lieu', Icons.star_rounded)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: TextFormField(initialValue: d['population'], onChanged: (v) => _administrativeDivisions[i]['population'] = v, keyboardType: TextInputType.number, decoration: _inputDeco('Population', Icons.groups_rounded))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: d['area'], onChanged: (v) => _administrativeDivisions[i]['area'] = v, keyboardType: TextInputType.number, decoration: _inputDeco('Superficie (km²)', Icons.map_rounded)))]),
      const SizedBox(height: 8),
      TextFormField(initialValue: d['administrator'], onChanged: (v) => _administrativeDivisions[i]['administrator'] = v, decoration: _inputDeco('Administrateur', Icons.person_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', d['media'], 'admin_divisions', () => setState(() {})),
    ]));
  }

  Widget _achievementCard(int i) {
    final a = _achievements[i];
    return Container(key: ValueKey(a['_key']), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [
      Row(children: [Text('Projet ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), onPressed: () => _removeItem('province_achievements', _achievements, i))]),
      TextFormField(initialValue: a['title'], onChanged: (v) => _achievements[i]['title'] = v, decoration: _inputDeco('Titre du projet', Icons.title_rounded)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: TextFormField(initialValue: a['date'], onChanged: (v) => _achievements[i]['date'] = v, decoration: _inputDeco('Date (AAAA-MM-JJ)', Icons.calendar_today_rounded))), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: a['location'], onChanged: (v) => _achievements[i]['location'] = v, decoration: _inputDeco('Lieu', Icons.location_on_rounded)))]),
      const SizedBox(height: 8),
      TextFormField(initialValue: a['description'], onChanged: (v) => _achievements[i]['description'] = v, maxLines: 2, decoration: _inputDeco('Description', Icons.description_rounded)),
      const SizedBox(height: 8),
      _multiMediaGallery('Galerie', a['media'], 'achievements', () => setState(() {})),
    ]));
  }

  Widget _emergencyCard(int i) {
    final e = _emergencyContacts[i];
    return Container(key: ValueKey(e['_key']), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children: [
      Expanded(child: Padding(padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4), child: TextFormField(initialValue: e['service'], onChanged: (v) => _emergencyContacts[i]['service'] = v, decoration: _inputDeco('Service', Icons.local_hospital_rounded)))),
      const SizedBox(width: 8),
      Expanded(child: Padding(padding: const EdgeInsets.only(right: 4, top: 4, bottom: 4), child: TextFormField(initialValue: e['phone'], onChanged: (v) => _emergencyContacts[i]['phone'] = v, keyboardType: TextInputType.phone, decoration: _inputDeco('Numéro', Icons.phone_rounded)))),
      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () => _removeItem('province_emergency_contacts', _emergencyContacts, i)),
    ]));
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGETS RÉUTILISABLES
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionCard({required IconData icon, required String title, Widget? action, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF101840)))),
          if (action != null) action,
        ]),
        const Divider(height: 24, thickness: 1),
        ...children,
      ]),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {bool required = false, bool isNumber = false, bool uppercase = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: [if (isNumber) FilteringTextInputFormatter.digitsOnly, if (uppercase) TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()))],
      decoration: _inputDeco(required ? '$label *' : label, icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20), filled: true, fillColor: const Color(0xFFF7F8FB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _imagePickerRow(String label, String? currentUrl, String folder, Function(String url) onUpdated) {
    final hasImg = currentUrl != null && currentUrl.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF7F8FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(
          width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: hasImg ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: currentUrl!, fit: BoxFit.cover, placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20))) : const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(hasImg ? 'Image chargée ✓' : 'Aucune image', style: TextStyle(fontSize: 11, color: hasImg ? AppColors.success : Colors.grey.shade600)),
        ])),
        ElevatedButton.icon(onPressed: () => _uploadSingleFile(folder, onUpdated), icon: const Icon(Icons.upload_rounded, size: 16), label: const Text('Choisir'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
      ]),
    );
  }

  /// [deleteTable] : si renseigné, la suppression d'un média qui a un `id`
  /// est mémorisée pour être appliquée en base à l'enregistrement.
  Widget _multiMediaGallery(String label, List<dynamic> mediaList, String folder, VoidCallback onUpdate, {String? deleteTable}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...mediaList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value as Map;
          final isVideo = m['type'] == 'video';
          final url = m['url']?.toString() ?? '';
          return Stack(children: [
            Container(
              width: 70, height: 70, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: isVideo ? Container(color: AppColors.primary, child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28)) : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24))),
            ),
            Positioned(right: 0, top: 0, child: GestureDetector(onTap: () {
              final removed = mediaList.removeAt(idx);
              if (deleteTable != null && removed is Map) {
                final id = removed['id']?.toString().trim() ?? '';
                if (id.isNotEmpty) (_deletedIds[deleteTable] ??= <String>{}).add(id);
              }
              onUpdate();
            }, child: Container(decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close_rounded, size: 12, color: Colors.white)))),
          ]);
        }),
        InkWell(onTap: () => _uploadMultiFiles(folder, (url, type) { mediaList.add({'url': url, 'type': type, '_key': _newKey()}); onUpdate(); }), borderRadius: BorderRadius.circular(8), child: Container(width: 70, height: 70, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withOpacity(0.3))), child: Icon(Icons.add_a_photo_rounded, color: AppColors.primary))),
      ]),
    ]);
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  // ═══════════════════════════════════════════════════════════════
  // SAUVEGARDE
  // ═══════════════════════════════════════════════════════════════

  /// Synchronise une table liée à la province :
  /// 1. supprime les lignes retirées par l'utilisateur,
  /// 2. dédoublonne (id, et clé métier si [dedupeBy]) pour éviter l'erreur
  ///    "ON CONFLICT DO UPDATE command cannot affect row a second time",
  /// 3. insère les nouvelles lignes, met à jour les existantes.
  Future<void> _syncTable({
    required String table,
    required String provinceId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> Function(Map<String, dynamic> item) toRow,
    bool Function(Map<String, dynamic> item)? isValid,
    String Function(Map<String, dynamic> item)? dedupeBy,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // 1. Suppressions demandées par l'utilisateur
      final deleted = _deletedIds[table];
      if (deleted != null && deleted.isNotEmpty) {
        await client
            .from(table)
            .delete()
            .eq('province_id', provinceId)
            .inFilter('id', deleted.toList());
      }

      // 2. Préparation + dédoublonnage
      final toInsert = <Map<String, dynamic>>[];
      final toUpdate = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      final seenKeys = <String>{};

      for (final item in items) {
        if (isValid != null && !isValid(item)) continue;

        final id = item['id']?.toString().trim() ?? '';
        final hasId = id.isNotEmpty;

        if (hasId && !seenIds.add(id)) continue; // même id déjà dans le lot
        if (dedupeBy != null && !seenKeys.add(dedupeBy(item))) continue;

        final row = toRow(item);
        row['province_id'] = provinceId;

        if (hasId) {
          row['id'] = id;
          toUpdate.add(row);
        } else {
          row.remove('id');
          toInsert.add(row);
        }
      }

      // 3. Écriture
      if (toInsert.isNotEmpty) await client.from(table).insert(toInsert);
      if (toUpdate.isNotEmpty) await client.from(table).upsert(toUpdate);
    } catch (e) {
      throw Exception('[$table] $e');
    }
  }

  Future<void> _saveRelations(String provinceId) async {
    await _syncTable(
      table: 'cities',
      provinceId: provinceId,
      items: _cities,
      isValid: (c) => _hasText(c, 'name'),
      toRow: (c) => <String, dynamic>{
        'name': c['name'].toString().trim(),
        'is_capital': c['is_capital'] == true,
        'population': _toInt(c['population']),
        'mayor': _nullIfEmpty(c['mayor']),
        'mayor_photo_url': _nullIfEmpty(c['mayor_photo_url']),
        'media': _cleanMedia(c['media']),
      },
    );

    await _syncTable(
      table: 'province_economic_resources',
      provinceId: provinceId,
      items: _economicSectors,
      isValid: (s) => _hasText(s, 'name'),
      toRow: (s) => <String, dynamic>{
        'name': s['name'].toString().trim(),
        'description': _nullIfEmpty(s['description']),
        'media': _cleanMedia(s['media']),
      },
    );

    await _syncTable(
      table: 'province_tourism_sites',
      provinceId: provinceId,
      items: _tourismSites,
      isValid: (t) => _hasText(t, 'name'),
      toRow: (t) => <String, dynamic>{
        'name': t['name'].toString().trim(),
        'type': _nullIfEmpty(t['type']),
        'description': _nullIfEmpty(t['description']),
        'media': _cleanMedia(t['media']),
      },
    );

    await _syncTable(
      table: 'province_emergency_contacts',
      provinceId: provinceId,
      items: _emergencyContacts,
      isValid: (e) => _hasText(e, 'service'),
      toRow: (e) => <String, dynamic>{
        'service': e['service'].toString().trim(),
        'phone': _nullIfEmpty(e['phone']),
      },
    );

    await _syncTable(
      table: 'province_administrative_divisions',
      provinceId: provinceId,
      items: _administrativeDivisions,
      isValid: (d) => _hasText(d, 'name'),
      toRow: (d) => <String, dynamic>{
        'type': _nullIfEmpty(d['type']),
        'name': d['name'].toString().trim(),
        'capital': _nullIfEmpty(d['capital']),
        'population': _toInt(d['population']),
        'area': _toNum(d['area']),
        'administrator': _nullIfEmpty(d['administrator']),
        'media': _cleanMedia(d['media']),
      },
    );

    // La table province_achievements n'a pas de colonnes `location` ni `media`
    await _syncTable(
      table: 'province_achievements',
      provinceId: provinceId,
      items: _achievements,
      isValid: (a) => _hasText(a, 'title'),
      toRow: (a) {
        final media = _cleanMedia(a['media']);
        return <String, dynamic>{
          'title': a['title'].toString().trim(),
          'description': _nullIfEmpty(a['description']),
          'date': _toDateString(a['date']),
          'cover_image_url': media.isNotEmpty ? media.first['url'] : null,
        };
      },
    );

    await _syncTable(
      table: 'province_tribes',
      provinceId: provinceId,
      items: _tribes,
      isValid: (t) => _hasText(t, 'name'),
      toRow: (t) => <String, dynamic>{
        'name': t['name'].toString().trim(),
        'zone': _nullIfEmpty(t['zone']),
        'history': _nullIfEmpty(t['history']),
        'media': _cleanMedia(t['media']),
      },
    );

    // Galerie globale : une URL ne peut apparaître qu'une fois
    await _syncTable(
      table: 'province_gallery_media',
      provinceId: provinceId,
      items: _galleryMedia,
      isValid: (m) => _hasText(m, 'url'),
      dedupeBy: (m) => m['url'].toString().trim(),
      toRow: (m) => <String, dynamic>{
        'url': m['url'].toString().trim(),
        'type': _nullIfEmpty(m['type']) ?? 'photo',
      },
    );

    // NB : province_ministers est liée à un gouvernement (government_id) et
    // n'a ni `name` ni `province_id` : elle n'est pas enregistrée depuis ce
    // formulaire (voir le formulaire Gouvernement).
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('⚠️ Veuillez remplir les champs obligatoires (avec *)', AppColors.warning);
      return;
    }

    setState(() => _isBusy = true);
    try {
      // 1. Préparer les données de la province principale
      final provinceData = {
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'capital': _capitalCtrl.text.trim(),
        'region': _region,
        'area': int.tryParse(_areaCtrl.text.trim()),
        'population': int.tryParse(_populationCtrl.text.trim()),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'history': _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
        'climate': _climateCtrl.text.trim().isEmpty ? null : _climateCtrl.text.trim(),
        'infrastructure': _infrastructureCtrl.text.trim().isEmpty ? null : _infrastructureCtrl.text.trim(),
        'education': _educationCtrl.text.trim().isEmpty ? null : _educationCtrl.text.trim(),
        'cover_image_url': _coverImageUrl,
        'coat_of_arms_url': _coatOfArmsUrl,
        'map_url': _mapUrl,
        'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'governor': _governorCtrl.text.trim().isEmpty ? null : _governorCtrl.text.trim(),
        'governor_photo_url': _governorPhotoUrl,
        'vice_governor': _viceGovernorCtrl.text.trim().isEmpty ? null : _viceGovernorCtrl.text.trim(),
        'vice_governor_photo_url': _viceGovernorPhotoUrl,
        'languages': _languagesCtrl.text.trim().isEmpty ? null : _languagesCtrl.text.trim(),
        'resources': _resourcesCtrl.text.trim().isEmpty ? null : _resourcesCtrl.text.trim(),
        'territories_count': int.tryParse(_territoriesCountCtrl.text.trim()),
      };

      String savedProvinceId;

      // 2. Sauvegarder la province principale
      if (_provinceId == null) {
        final res = await SupabaseConfig.client.from('provinces').insert(provinceData).select();
        savedProvinceId = (res as List).first['id'].toString();
      } else {
        await SupabaseConfig.client.from('provinces').update(provinceData).eq('id', _provinceId!);
        savedProvinceId = _provinceId!;
      }

      // 3. Sauvegarder toutes les relations (dédoublonnées)
      await _saveRelations(savedProvinceId);

      // 4. Rafraîchir les providers
      ref.invalidate(provincesProvider);
      ref.invalidate(adminProvincesProvider);
      if (_provinceId != null) ref.invalidate(provinceWithAllRelationsProvider(_provinceId!));

      if (!mounted) return;
      setState(() => _isBusy = false);

      final hasMinisters = _ministers.any((m) => _hasText(m, 'name'));
      _snack(
        hasMinisters
            ? '✅ Province enregistrée (les ministres ne sont pas enregistrés depuis ce formulaire)'
            : '✅ Province enregistrée avec succès',
        hasMinisters ? AppColors.warning : AppColors.success,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _snack('❌ Erreur : $e', AppColors.danger);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIAIRES
// ═══════════════════════════════════════════════════════════════
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ]),
    );
  }
}
