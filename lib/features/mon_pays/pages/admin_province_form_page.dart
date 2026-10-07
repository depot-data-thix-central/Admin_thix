// lib/features/mon_pays/pages/admin_province_form_page.dart
//
// AdminProvinceFormPage — v3 (Admin_thix) : TOUS les champs + uploads locaux
//
// ✅ Champs ajoutés : devise, drapeau, hymne (audio + instrumental + paroles),
//    actualités, projets, services, engagement citoyen, budget, démographie,
//    documents officiels, médiathèque (vidéos), personnalités, gastronomie,
//    proverbes, entreprises, produits, quiz, photo des villes, ministres, réalisations
// ✅ Photos / vidéos / audio / documents choisis SUR L'APPAREIL (file picker) puis
//    envoyés dans le bucket Supabase « provinces »
//    (extensions autorisées, taille max, nom de fichier généré : jamais le nom d'origine)
// ✅ Corrigé : un 2e clic sur « Enregistrer » après une erreur ne crée plus de doublons
//    (la province et les lignes déjà insérées gardent leur id)
// ✅ Validation avant envoi, confirmation avant de quitter avec des modifications
//
// ⚠️ Exécuter le SQL fourni à la fin AVANT d'utiliser cette version.

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_colors.dart';
import '../../../supabase/supabase_config.dart';
import '../models/province.dart';
import '../providers/provinces_provider.dart';

// ═══════════════════════════════════════════════════════════════
// CONSTANTES UPLOAD
// ═══════════════════════════════════════════════════════════════
const String _kBucket = 'provinces';
const int _kMaxImageBytes = 10 * 1024 * 1024; // 10 Mo
const int _kMaxVideoBytes = 50 * 1024 * 1024; // 50 Mo (limite par défaut Supabase)
const int _kMaxAudioBytes = 30 * 1024 * 1024; // 30 Mo
const int _kMaxDocBytes = 25 * 1024 * 1024; // 25 Mo
const int _kMaxPickAtOnce = 20;

const List<String> _kImageExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
const List<String> _kVideoExt = ['mp4', 'mov', 'webm', 'mkv'];
const List<String> _kAudioExt = ['mp3', 'm4a', 'wav', 'ogg', 'aac'];
const List<String> _kDocExt = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];

const Map<String, String> _kMime = {
  'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp', 'gif': 'image/gif',
  'mp4': 'video/mp4', 'mov': 'video/quicktime', 'webm': 'video/webm', 'mkv': 'video/x-matroska',
  'mp3': 'audio/mpeg', 'm4a': 'audio/mp4', 'wav': 'audio/wav', 'ogg': 'audio/ogg', 'aac': 'audio/aac',
  'pdf': 'application/pdf', 'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
};

enum _Kind { image, video, audio, document }

extension _KindX on _Kind {
  List<String> get exts {
    switch (this) {
      case _Kind.image:
        return _kImageExt;
      case _Kind.video:
        return _kVideoExt;
      case _Kind.audio:
        return _kAudioExt;
      case _Kind.document:
        return _kDocExt;
    }
  }

  int get maxBytes {
    switch (this) {
      case _Kind.image:
        return _kMaxImageBytes;
      case _Kind.video:
        return _kMaxVideoBytes;
      case _Kind.audio:
        return _kMaxAudioBytes;
      case _Kind.document:
        return _kMaxDocBytes;
    }
  }

  IconData get icon {
    switch (this) {
      case _Kind.image:
        return Icons.image_outlined;
      case _Kind.video:
        return Icons.videocam_rounded;
      case _Kind.audio:
        return Icons.audiotrack_rounded;
      case _Kind.document:
        return Icons.description_rounded;
    }
  }

  String get pickLabel {
    switch (this) {
      case _Kind.image:
        return 'Choisir une photo';
      case _Kind.video:
        return 'Choisir une vidéo';
      case _Kind.audio:
        return 'Choisir un audio';
      case _Kind.document:
        return 'Choisir un document';
    }
  }
}

class AdminProvinceFormPage extends ConsumerStatefulWidget {
  final Province? province;
  const AdminProvinceFormPage({super.key, this.province});

  @override
  ConsumerState<AdminProvinceFormPage> createState() => _AdminProvinceFormPageState();
}

class _AdminProvinceFormPageState extends ConsumerState<AdminProvinceFormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabCtrl;

  // ── Champs texte ──
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _capitalCtrl;
  late TextEditingController _mottoCtrl;
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
  late TextEditingController _hymnTitleCtrl;
  late TextEditingController _hymnLyricsCtrl;

  String _region = 'Centre';
  static const List<String> _regions = ['Centre', 'Est', 'Ouest', 'Nord', 'Sud'];

  // ── Images / fichiers uniques ──
  String? _coverImageUrl;
  String? _coatOfArmsUrl;
  String? _flagUrl;
  String? _mapUrl;
  String? _governorPhotoUrl;
  String? _viceGovernorPhotoUrl;

  // ── Hymne (1 ligne par province) ──
  String? _hymnId;
  String? _hymnAudioUrl;
  String? _hymnInstrumentalUrl;

  // ── Listes éditables ──
  List<Map<String, dynamic>> _ministers = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _economicSectors = [];
  List<Map<String, dynamic>> _tourismSites = [];
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _administrativeDivisions = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _tribes = [];
  List<Map<String, dynamic>> _galleryMedia = [];
  // nouvelles sections
  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _engagements = [];
  List<Map<String, dynamic>> _budget = [];
  List<Map<String, dynamic>> _demographics = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _mediaItems = [];
  List<Map<String, dynamic>> _famous = [];
  List<Map<String, dynamic>> _gastronomy = [];
  List<Map<String, dynamic>> _proverbs = [];
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _quiz = [];

  // ids supprimés par l'utilisateur pendant cette session (table -> ids)
  final Map<String, Set<String>> _deletedIds = {};
  final List<String> _loadErrors = [];

  bool _isEditing = false;
  String? _provinceId;
  bool _isBusy = false;
  String? _busyLabel;
  bool _isLoadingFullData = false;
  bool _dirty = false;

  int _keyCounter = 0;
  String _newKey() => 'k${_keyCounter++}_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 11, vsync: this);
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
    _mottoCtrl = TextEditingController();
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
    _hymnTitleCtrl = TextEditingController();
    _hymnLyricsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [
      _nameCtrl, _codeCtrl, _capitalCtrl, _mottoCtrl, _areaCtrl, _populationCtrl, _territoriesCountCtrl,
      _descriptionCtrl, _languagesCtrl, _resourcesCtrl, _historyCtrl, _climateCtrl, _infrastructureCtrl,
      _educationCtrl, _websiteCtrl, _governorCtrl, _viceGovernorCtrl, _hymnTitleCtrl, _hymnLyricsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS DE CONVERSION
  // ═══════════════════════════════════════════════════════════════
  static bool _hasText(Map<String, dynamic> m, String key) => (m[key]?.toString().trim() ?? '').isNotEmpty;

  static String? _nullIfEmpty(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    final s = v.toString().trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    return int.tryParse(s) ?? double.tryParse(s.replaceAll(',', '.'))?.toInt();
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

  static String _tsOrNow(dynamic v) {
    final d = DateTime.tryParse(v?.toString().trim() ?? '');
    return (d?.toUtc() ?? DateTime.now().toUtc()).toIso8601String();
  }

  static bool _bool(Map<String, dynamic> m, String key, {bool def = true}) {
    final v = m[key];
    return v is bool ? v : def;
  }

  static bool _isHttp(String s) {
    final u = Uri.tryParse(s.trim());
    return u != null && u.hasAuthority && (u.scheme == 'http' || u.scheme == 'https');
  }

  static String _cleanErr(Object e) => e.toString().replaceFirst('Exception: ', '');

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

  static List<Map<String, dynamic>> _uniqueById(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    return list.where((m) {
      final id = m['id']?.toString().trim() ?? '';
      if (id.isEmpty) return true;
      return seen.add(id);
    }).toList();
  }

  void _touch() {
    if (_dirty || !mounted) return;
    setState(() => _dirty = true);
  }

  void _removeItem(String table, List<Map<String, dynamic>> list, int i) {
    final id = list[i]['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) (_deletedIds[table] ??= <String>{}).add(id);
    setState(() => list.removeAt(i));
    _touch();
  }

  /// Ligne Supabase → map éditable (nombres en texte, dates en AAAA-MM-JJ, null → '').
  Map<String, dynamic> _edit(Map r) {
    final m = <String, dynamic>{'_key': _newKey()};
    r.forEach((k, v) {
      final key = k.toString();
      if (v == null) {
        m[key] = '';
      } else if (v is num) {
        m[key] = v.toString();
      } else if (v is String && key.endsWith('_at') && v.length >= 10) {
        m[key] = v.substring(0, 10);
      } else {
        m[key] = v;
      }
    });
    return m;
  }

  // ═══════════════════════════════════════════════════════════════
  // DONNÉES
  // ═══════════════════════════════════════════════════════════════
  void _populateData(Province p) {
    _nameCtrl.text = p.name;
    _codeCtrl.text = p.code;
    _capitalCtrl.text = p.capital;
    _mottoCtrl.text = p.motto ?? '';

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
    _flagUrl = p.flagUrl;
    _mapUrl = p.mapUrl;
    _governorPhotoUrl = p.governorPhotoUrl;
    _viceGovernorPhotoUrl = p.viceGovernorPhotoUrl;

    _ministers = _uniqueById(p.ministers
        .map<Map<String, dynamic>>((m) => <String, dynamic>{
              '_key': _newKey(),
              'id': m['id'],
              'name': m['name'] ?? '',
              'role': m['role'] ?? '',
              'photo_url': m['photoUrl'] ?? m['photo_url'] ?? '',
            })
        .toList());

    _cities = _uniqueById(p.cities.map<Map<String, dynamic>>((c) {
      final dyn = c as dynamic;
      return <String, dynamic>{
        '_key': _newKey(),
        'id': c.id,
        'name': c.name,
        'population': c.population?.toString() ?? '',
        'is_capital': c.isCapital,
        'mayor': c.mayor ?? '',
        'mayor_photo_url': c.mayorPhotoUrl ?? '',
        'image_url': (dyn.imageUrl ?? '').toString(),
        'media': c.media != null ? List<Map<String, dynamic>>.from(c.media!) : <Map<String, dynamic>>[],
      };
    }).toList());

    _economicSectors = _uniqueById(p.economicResources
        .map<Map<String, dynamic>>((e) => <String, dynamic>{
              '_key': _newKey(),
              'id': e.id,
              'name': e.name,
              'description': e.description ?? '',
              'media': e.media != null ? List<Map<String, dynamic>>.from(e.media!) : <Map<String, dynamic>>[],
            })
        .toList());

    _tourismSites = _uniqueById(p.tourismSites
        .map<Map<String, dynamic>>((t) => <String, dynamic>{
              '_key': _newKey(),
              'id': t.id,
              'name': t.name,
              'type': t.type,
              'description': t.description ?? '',
              'media': t.media != null ? List<Map<String, dynamic>>.from(t.media!) : <Map<String, dynamic>>[],
            })
        .toList());

    _emergencyContacts = _uniqueById(p.emergencyContacts
        .map<Map<String, dynamic>>((e) => <String, dynamic>{
              '_key': _newKey(),
              'id': e.id,
              'service': e.service,
              'phone': e.phone,
            })
        .toList());

    _administrativeDivisions = _uniqueById(p.administrativeDivisions
        .map<Map<String, dynamic>>((a) => <String, dynamic>{
              '_key': _newKey(),
              'id': a.id,
              'type': a.type,
              'name': a.name,
              'capital': a.capital ?? '',
              'population': a.population?.toString() ?? '',
              'area': a.area?.toString() ?? '',
              'administrator': a.administrator ?? '',
              'media': a.media != null ? List<Map<String, dynamic>>.from(a.media!) : <Map<String, dynamic>>[],
            })
        .toList());

    _achievements = _uniqueById(p.achievements
        .map<Map<String, dynamic>>((a) => <String, dynamic>{
              '_key': _newKey(),
              'id': a['id'],
              'title': a['title'] ?? '',
              'description': a['description'] ?? '',
              'date': a['date'] ?? '',
              'location': a['location'] ?? '',
              'media': a['media'] != null ? List<Map<String, dynamic>>.from(a['media']) : <Map<String, dynamic>>[],
            })
        .toList());

    _tribes = _uniqueById(p.tribes
        .map<Map<String, dynamic>>((tr) => <String, dynamic>{
              '_key': _newKey(),
              'id': tr['id'],
              'name': tr['name'] ?? '',
              'zone': tr['zone'] ?? '',
              'history': tr['history'] ?? '',
              'media': tr['media'] != null ? List<Map<String, dynamic>>.from(tr['media']) : <Map<String, dynamic>>[],
            })
        .toList());

    _galleryMedia = _uniqueById(p.galleryMedia
        .map<Map<String, dynamic>>((m) => <String, dynamic>{
              '_key': _newKey(),
              'id': m['id'],
              'url': m['url'],
              'type': m['type'],
            })
        .toList());
  }

  Future<List<Map<String, dynamic>>> _fetchRows(String table, String? orderBy, {bool asc = true}) async {
    try {
      final base = SupabaseConfig.client.from(table).select().eq('province_id', _provinceId!);
      final List<dynamic> rows = orderBy == null ? await base : await base.order(orderBy, ascending: asc);
      return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[AdminProvince] load $table: $e');
      _loadErrors.add(table);
      return <Map<String, dynamic>>[];
    }
  }

  /// Charge les sections qui ne font pas partie du modèle Province.
  Future<void> _loadExtras() async {
    final id = _provinceId;
    if (id == null) return;
    _loadErrors.clear();

    final r = await Future.wait<List<Map<String, dynamic>>>([
      _fetchRows('province_news', 'published_at', asc: false), // 0
      _fetchRows('province_projects', 'created_at'), // 1
      _fetchRows('province_services', 'name'), // 2
      _fetchRows('province_engagements', 'created_at', asc: false), // 3
      _fetchRows('province_budget', 'percentage', asc: false), // 4
      _fetchRows('province_demographics', 'year'), // 5
      _fetchRows('province_documents', 'published_at', asc: false), // 6
      _fetchRows('province_media', 'published_at', asc: false), // 7
      _fetchRows('province_famous_people', 'name'), // 8
      _fetchRows('province_gastronomy', 'name'), // 9
      _fetchRows('province_proverbs', 'created_at', asc: false), // 10
      _fetchRows('province_businesses', 'name'), // 11
      _fetchRows('province_products', 'name'), // 12
      _fetchRows('province_quiz_questions', 'order_index'), // 13
    ]);

    Map<String, dynamic>? hymn;
    try {
      final h = await SupabaseConfig.client.from('province_hymns').select().eq('province_id', id).limit(1);
      final list = (h as List).whereType<Map>().toList();
      if (list.isNotEmpty) hymn = Map<String, dynamic>.from(list.first);
    } catch (e) {
      _loadErrors.add('province_hymns');
    }

    if (!mounted) return;
    setState(() {
      _news = r[0].map(_edit).toList();
      _projects = r[1].map((row) {
        final m = _edit(row);
        final raw = double.tryParse(m['progress']?.toString() ?? '') ?? 0;
        m['progress'] = (raw > 1 ? raw : raw * 100).round().toString();
        return m;
      }).toList();
      _services = r[2].map(_edit).toList();
      _engagements = r[3].map(_edit).toList();
      _budget = r[4].map(_edit).toList();
      _demographics = r[5].map(_edit).toList();
      _documents = r[6].map(_edit).toList();
      _mediaItems = r[7].map(_edit).toList();
      _famous = r[8].map(_edit).toList();
      _gastronomy = r[9].map((row) {
        final m = _edit(row);
        final ing = row['ingredients'];
        m['ingredients'] = ing is List ? ing.map((e) => e.toString()).join(', ') : (ing?.toString() ?? '');
        return m;
      }).toList();
      _proverbs = r[10].map(_edit).toList();
      _businesses = r[11].map(_edit).toList();
      _products = r[12].map(_edit).toList();
      _quiz = r[13].map((row) {
        final m = _edit(row);
        final opts = (row['options'] is List) ? (row['options'] as List).map((e) => e.toString()).toList() : <String>[];
        while (opts.length < 4) {
          opts.add('');
        }
        m['opts'] = opts;
        m['correct'] = _toInt(row['correct_answer']) ?? 0;
        return m;
      }).toList();

      if (hymn != null) {
        _hymnId = hymn['id']?.toString();
        _hymnTitleCtrl.text = hymn['title']?.toString() ?? '';
        _hymnLyricsCtrl.text = hymn['lyrics']?.toString() ?? '';
        _hymnAudioUrl = _nullIfEmpty(hymn['audio_url']);
        _hymnInstrumentalUrl = _nullIfEmpty(hymn['instrumental_url']);
      }
    });

    if (_loadErrors.isNotEmpty) {
      _snack('⚠️ Tables non lisibles : ${_loadErrors.join(', ')}. Exécutez le SQL fourni.', AppColors.warning);
    }
  }

  Future<void> _loadFullData() async {
    if (!mounted) return;
    setState(() => _isLoadingFullData = true);
    try {
      final fullProvince = await ref.read(provinceWithAllRelationsProvider(_provinceId!).future);
      if (!mounted) return;
      setState(() => _populateData(fullProvince));
      await _loadExtras();
      if (!mounted) return;
      setState(() => _isLoadingFullData = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFullData = false);
      _snack('⚠️ Impossible de charger les détails complets : ${_cleanErr(e)}', AppColors.warning);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPLOAD LOCAL → SUPABASE STORAGE
  // ═══════════════════════════════════════════════════════════════
  static final math.Random _rng = math.Random.secure();
  String _rand() => _rng.nextInt(0x7fffffff).toRadixString(36);

  /// Envoie un fichier choisi sur l'appareil. Le nom d'origine n'est jamais utilisé.
  Future<String> _uploadPicked(PlatformFile f, _Kind kind, String folder) async {
    final ext = (f.extension ?? '').toLowerCase();
    if (!kind.exts.contains(ext)) {
      throw Exception('Format .$ext non accepté (${kind.exts.join(', ')})');
    }
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) throw Exception('Fichier illisible ou vide');
    if (bytes.length > kind.maxBytes) {
      throw Exception('Fichier trop lourd (max ${kind.maxBytes ~/ (1024 * 1024)} Mo)');
    }
    final safeFolder = folder.replaceAll(RegExp(r'[^a-z0-9_/]'), '');
    final path = '$safeFolder/${DateTime.now().millisecondsSinceEpoch}_${_rand()}.$ext';
    final storage = SupabaseConfig.client.storage.from(_kBucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _kMime[ext], upsert: false),
    );
    return storage.getPublicUrl(path);
  }

  Future<String?> _pickSingle(_Kind kind, String folder) async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kind.exts,
        withData: true,
      );
      if (r == null || r.files.isEmpty) return null;
      if (!mounted) return null;
      setState(() {
        _isBusy = true;
        _busyLabel = 'Téléversement en cours…';
      });
      final url = await _uploadPicked(r.files.first, kind, folder);
      if (mounted) _snack('✅ Fichier téléversé', AppColors.success);
      return url;
    } catch (e) {
      if (mounted) _snack('❌ ${_cleanErr(e)}', AppColors.danger);
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = null;
        });
      }
    }
  }

  /// Photos ET vidéos (sélection multiple) pour les galeries.
  Future<void> _pickMulti(String folder, void Function(String url, String type) onItem) async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [..._kImageExt, ..._kVideoExt],
        allowMultiple: true,
        withData: true,
      );
      if (r == null || r.files.isEmpty) return;
      final files = r.files.take(_kMaxPickAtOnce).toList();
      if (!mounted) return;
      setState(() => _isBusy = true);
      int ok = 0, fail = 0;
      String? lastErr;
      for (var n = 0; n < files.length; n++) {
        if (!mounted) return;
        setState(() => _busyLabel = 'Téléversement ${n + 1}/${files.length}…');
        final f = files[n];
        final isVideo = _kVideoExt.contains((f.extension ?? '').toLowerCase());
        try {
          final url = await _uploadPicked(f, isVideo ? _Kind.video : _Kind.image, folder);
          onItem(url, isVideo ? 'video' : 'photo');
          ok++;
        } catch (e) {
          fail++;
          lastErr = _cleanErr(e);
        }
      }
      if (mounted) {
        _snack(
          fail == 0 ? '✅ $ok média(s) ajouté(s)' : '⚠️ $ok ajouté(s), $fail refusé(s) : $lastErr',
          fail == 0 ? AppColors.success : AppColors.warning,
        );
      }
    } catch (e) {
      if (mounted) _snack('❌ ${_cleanErr(e)}', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = null;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        content: const Text('Les modifications non enregistrées seront perdues.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _leave();
  }

  void _leave() {
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
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
              IconButton(icon: const Icon(Icons.check_rounded), onPressed: _save, tooltip: 'Enregistrer'),
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
              Tab(text: 'Actualités & Projets'),
              Tab(text: 'Citoyen & Quiz'),
              Tab(text: 'Médias & Docs'),
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
                    onChanged: _touch,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _tabIdentity(),
                        _tabHistory(),
                        _tabGovernance(),
                        _tabCulture(),
                        _tabCities(),
                        _tabEconomy(),
                        _tabTourism(),
                        _tabAdminOthers(),
                        _tabNewsProjects(),
                        _tabCitizenQuiz(),
                        _tabMediaDocs(),
                      ],
                    ),
                  ),
                  if (_isBusy)
                    Container(
                      color: Colors.black.withOpacity(0.45),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            if (_busyLabel != null) ...[
                              const SizedBox(height: 14),
                              Text(_busyLabel!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ],
                          ],
                        ),
                      ),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ONGLETS
  // ═══════════════════════════════════════════════════════════════
  static const SizedBox _gap = SizedBox(height: 16);

  Widget _tabIdentity() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionCard(icon: Icons.badge_rounded, title: 'Informations de base', children: [
          _textField(_nameCtrl, 'Nom de la province *', Icons.map_outlined, required: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _textField(_codeCtrl, 'Code (ex: KIN) *', Icons.tag, required: true, uppercase: true, maxLength: 6)),
            const SizedBox(width: 12),
            Expanded(child: _textField(_capitalCtrl, 'Capitale *', Icons.location_city, required: true)),
          ]),
          const SizedBox(height: 12),
          _textField(_mottoCtrl, 'Devise de la province', Icons.format_quote_rounded),
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
        _gap,
        _sectionCard(icon: Icons.image_rounded, title: 'Identité visuelle (depuis votre appareil)', children: [
          _fileRow('Photo de couverture', _coverImageUrl, 'covers', _Kind.image,
              (u) => setState(() => _coverImageUrl = u), onClear: () => setState(() => _coverImageUrl = null)),
          const SizedBox(height: 12),
          _fileRow('Blason / Armoiries', _coatOfArmsUrl, 'emblems', _Kind.image,
              (u) => setState(() => _coatOfArmsUrl = u), onClear: () => setState(() => _coatOfArmsUrl = null)),
          const SizedBox(height: 12),
          _fileRow('Drapeau', _flagUrl, 'flags', _Kind.image, (u) => setState(() => _flagUrl = u),
              onClear: () => setState(() => _flagUrl = null)),
          const SizedBox(height: 12),
          _fileRow('Carte géographique', _mapUrl, 'maps', _Kind.image, (u) => setState(() => _mapUrl = u),
              onClear: () => setState(() => _mapUrl = null)),
          const SizedBox(height: 12),
          _textField(_websiteCtrl, 'Site web officiel (https://…)', Icons.language_rounded),
        ]),
        _gap,
        _sectionCard(icon: Icons.perm_media_rounded, title: 'Galerie média globale (photos & vidéos)', children: [
          _multiMediaGallery('Tous les médias', _galleryMedia, 'gallery', () => setState(() {}),
              deleteTable: 'province_gallery_media'),
        ]),
      ]);

  Widget _tabHistory() => ListView(padding: const EdgeInsets.all(16), children: [
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

  Widget _tabGovernance() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionCard(icon: Icons.account_balance_rounded, title: 'Exécutif provincial', children: [
          _textField(_governorCtrl, 'Nom du Gouverneur', Icons.person_rounded),
          const SizedBox(height: 8),
          _fileRow('Photo du Gouverneur', _governorPhotoUrl, 'governors', _Kind.image,
              (u) => setState(() => _governorPhotoUrl = u), onClear: () => setState(() => _governorPhotoUrl = null)),
          const SizedBox(height: 16),
          _textField(_viceGovernorCtrl, 'Nom du Vice-Gouverneur', Icons.person_outline_rounded),
          const SizedBox(height: 8),
          _fileRow('Photo du Vice-Gouverneur', _viceGovernorPhotoUrl, 'governors', _Kind.image,
              (u) => setState(() => _viceGovernorPhotoUrl = u),
              onClear: () => setState(() => _viceGovernorPhotoUrl = null)),
        ]),
        _gap,
        _listSection(
          icon: Icons.people_alt_rounded,
          title: 'Ministres provinciaux',
          table: 'province_ministers',
          list: _ministers,
          itemLabel: 'Ministre',
          blank: () => {'name': '', 'role': '', 'photo_url': ''},
          emptyText: 'Aucun ministre ajouté',
          emptyIcon: Icons.person_add_disabled_rounded,
          fields: (i) => [
            _tf(_ministers, i, 'name', 'Nom complet', Icons.person_rounded),
            _tf(_ministers, i, 'role', 'Portefeuille', Icons.work_outline_rounded),
            _fileF(_ministers, i, 'photo_url', 'Photo du ministre', 'ministers', _Kind.image),
          ],
        ),
      ]);

  Widget _tabCulture() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionCard(icon: Icons.forum_rounded, title: 'Langues & Culture', children: [
          _textField(_languagesCtrl, 'Langues parlées', Icons.forum_rounded),
          const SizedBox(height: 12),
          _textField(_resourcesCtrl, 'Ressources principales', Icons.diamond_rounded),
          const SizedBox(height: 12),
          _textField(_descriptionCtrl, 'Description générale & Traditions', Icons.description_rounded, maxLines: 3),
        ]),
        _gap,
        _sectionCard(icon: Icons.music_note_rounded, title: 'Hymne provincial', children: [
          _textField(_hymnTitleCtrl, 'Titre de l\'hymne', Icons.title_rounded),
          const SizedBox(height: 12),
          _fileRow('Version officielle (audio)', _hymnAudioUrl, 'hymns', _Kind.audio,
              (u) => setState(() => _hymnAudioUrl = u), onClear: () => setState(() => _hymnAudioUrl = null)),
          const SizedBox(height: 12),
          _fileRow('Version instrumentale (audio)', _hymnInstrumentalUrl, 'hymns', _Kind.audio,
              (u) => setState(() => _hymnInstrumentalUrl = u),
              onClear: () => setState(() => _hymnInstrumentalUrl = null)),
          const SizedBox(height: 12),
          _textField(_hymnLyricsCtrl, 'Paroles', Icons.lyrics_rounded, maxLines: 6, maxLength: 5000),
        ]),
        _gap,
        _listSection(
          icon: Icons.groups_rounded,
          title: 'Peuples & Tribus',
          table: 'province_tribes',
          list: _tribes,
          itemLabel: 'Tribu',
          blank: () => {'name': '', 'zone': '', 'history': '', 'media': <Map<String, dynamic>>[]},
          emptyText: 'Aucune tribu ajoutée',
          emptyIcon: Icons.groups_2_outlined,
          fields: (i) => [
            _tf(_tribes, i, 'name', 'Nom de la tribu', Icons.group_rounded),
            _tf(_tribes, i, 'zone', 'Zone / Territoire', Icons.place_rounded),
            _tf(_tribes, i, 'history', 'Histoire & coutumes', Icons.menu_book_rounded, lines: 3),
            _multiMediaGallery('Galerie', _tribes[i]['media'], 'tribes', () => setState(() {})),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.emoji_events_rounded,
          title: 'Personnalités célèbres',
          table: 'province_famous_people',
          list: _famous,
          itemLabel: 'Personnalité',
          blank: () => {'name': '', 'field': '', 'achievement': '', 'bio': '', 'photo_url': '', 'is_active': true},
          emptyText: 'Aucune personnalité ajoutée',
          emptyIcon: Icons.star_outline_rounded,
          fields: (i) => [
            _tf(_famous, i, 'name', 'Nom', Icons.person_rounded),
            _tf(_famous, i, 'field', 'Domaine (musique, sport, politique…)', Icons.category_rounded),
            _tf(_famous, i, 'achievement', 'Distinction / réalisation', Icons.workspace_premium_rounded),
            _tf(_famous, i, 'bio', 'Biographie', Icons.notes_rounded, lines: 3),
            _fileF(_famous, i, 'photo_url', 'Photo', 'famous', _Kind.image),
            _sw(_famous, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.restaurant_rounded,
          title: 'Gastronomie',
          table: 'province_gastronomy',
          list: _gastronomy,
          itemLabel: 'Plat',
          blank: () => {'name': '', 'description': '', 'ingredients': '', 'image_url': '', 'is_active': true},
          emptyText: 'Aucun plat ajouté',
          emptyIcon: Icons.restaurant_menu_rounded,
          fields: (i) => [
            _tf(_gastronomy, i, 'name', 'Nom du plat', Icons.restaurant_rounded),
            _tf(_gastronomy, i, 'description', 'Description', Icons.notes_rounded, lines: 2),
            _tf(_gastronomy, i, 'ingredients', 'Ingrédients (séparés par des virgules)', Icons.list_alt_rounded, lines: 2),
            _fileF(_gastronomy, i, 'image_url', 'Photo du plat', 'gastronomy', _Kind.image),
            _sw(_gastronomy, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.format_quote_rounded,
          title: 'Proverbes & Contes',
          table: 'province_proverbs',
          list: _proverbs,
          itemLabel: 'Proverbe',
          blank: () => {'text': '', 'translation': '', 'meaning': '', 'language': 'Lingala', 'is_active': true},
          emptyText: 'Aucun proverbe ajouté',
          emptyIcon: Icons.format_quote_outlined,
          fields: (i) => [
            _tf(_proverbs, i, 'text', 'Texte original', Icons.format_quote_rounded, lines: 2),
            _dd(_proverbs, i, 'language', 'Langue',
                const ['Lingala', 'Swahili', 'Tshiluba', 'Kikongo', 'Français', 'Autre'], Icons.translate_rounded),
            _tf(_proverbs, i, 'translation', 'Traduction française', Icons.translate_rounded, lines: 2),
            _tf(_proverbs, i, 'meaning', 'Signification / explication', Icons.lightbulb_outline_rounded, lines: 3),
            _sw(_proverbs, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
      ]);

  Widget _tabCities() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.location_city_rounded,
          title: 'Villes principales',
          table: 'cities',
          list: _cities,
          itemLabel: 'Ville',
          blank: () => {
            'name': '',
            'population': '',
            'is_capital': false,
            'mayor': '',
            'mayor_photo_url': '',
            'image_url': '',
            'media': <Map<String, dynamic>>[],
          },
          emptyText: 'Aucune ville ajoutée',
          emptyIcon: Icons.location_city_outlined,
          fields: (i) => [
            _tf(_cities, i, 'name', 'Nom de la ville', Icons.location_city_rounded),
            _tf(_cities, i, 'population', 'Population', Icons.groups_rounded, number: true),
            _sw(_cities, i, 'is_capital', 'Chef-lieu de la province', def: false),
            _fileF(_cities, i, 'image_url', 'Photo de la ville', 'cities', _Kind.image),
            _multiMediaGallery('Galerie photos & vidéos', _cities[i]['media'], 'cities', () => setState(() {})),
            _tf(_cities, i, 'mayor', 'Maire / Bourgmestre', Icons.person_rounded),
            _fileF(_cities, i, 'mayor_photo_url', "Photo de l'autorité", 'mayors', _Kind.image),
          ],
        ),
      ]);

  Widget _tabEconomy() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.monetization_on_rounded,
          title: 'Économie & Secteurs clés',
          table: 'province_economic_resources',
          list: _economicSectors,
          itemLabel: 'Secteur',
          blank: () => {'name': '', 'description': '', 'media': <Map<String, dynamic>>[]},
          emptyText: 'Aucun secteur ajouté',
          emptyIcon: Icons.business_outlined,
          fields: (i) => [
            _tf(_economicSectors, i, 'name', 'Nom du secteur', Icons.business_rounded),
            _tf(_economicSectors, i, 'description', 'Détails', Icons.notes_rounded, lines: 3),
            _multiMediaGallery('Galerie', _economicSectors[i]['media'], 'economy', () => setState(() {})),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.apartment_rounded,
          title: 'Entreprises',
          table: 'province_businesses',
          list: _businesses,
          itemLabel: 'Entreprise',
          blank: () => {
            'name': '', 'sector': '', 'employees': '', 'description': '', 'website': '', 'logo_url': '', 'is_active': true,
          },
          emptyText: 'Aucune entreprise ajoutée',
          emptyIcon: Icons.apartment_outlined,
          fields: (i) => [
            _tf(_businesses, i, 'name', 'Nom', Icons.business_rounded),
            _tf(_businesses, i, 'sector', 'Secteur d\'activité', Icons.category_rounded),
            _tf(_businesses, i, 'employees', 'Nombre d\'employés', Icons.groups_rounded, number: true),
            _tf(_businesses, i, 'description', 'Description', Icons.notes_rounded, lines: 2),
            _tf(_businesses, i, 'website', 'Site web (https://…)', Icons.language_rounded),
            _fileF(_businesses, i, 'logo_url', 'Logo', 'businesses', _Kind.image),
            _sw(_businesses, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.shopping_basket_rounded,
          title: 'Produits du terroir',
          table: 'province_products',
          list: _products,
          itemLabel: 'Produit',
          blank: () => {'name': '', 'description': '', 'image_url': '', 'is_active': true},
          emptyText: 'Aucun produit ajouté',
          emptyIcon: Icons.shopping_basket_outlined,
          fields: (i) => [
            _tf(_products, i, 'name', 'Nom du produit', Icons.shopping_bag_rounded),
            _tf(_products, i, 'description', 'Description', Icons.notes_rounded, lines: 2),
            _fileF(_products, i, 'image_url', 'Photo du produit', 'products', _Kind.image),
            _sw(_products, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Budget provincial (USD)',
          table: 'province_budget',
          list: _budget,
          itemLabel: 'Poste',
          blank: () => {'sector': '', 'amount': ''},
          emptyText: 'Aucun poste budgétaire',
          emptyIcon: Icons.account_balance_wallet_outlined,
          note: const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Saisissez les montants : les pourcentages sont calculés automatiquement.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          fields: (i) => [
            _tf(_budget, i, 'sector', 'Secteur (Santé, Éducation…)', Icons.category_rounded),
            _tf(_budget, i, 'amount', 'Montant (USD)', Icons.payments_rounded, number: true),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.analytics_rounded,
          title: 'Démographie (par année)',
          table: 'province_demographics',
          list: _demographics,
          itemLabel: 'Année',
          blank: () => {'year': '', 'population': ''},
          emptyText: 'Aucune donnée démographique',
          emptyIcon: Icons.analytics_outlined,
          fields: (i) => [
            Row(children: [
              Expanded(child: _tf(_demographics, i, 'year', 'Année', Icons.event_rounded, number: true)),
              const SizedBox(width: 8),
              Expanded(child: _tf(_demographics, i, 'population', 'Population', Icons.groups_rounded, number: true)),
            ]),
          ],
        ),
      ]);

  Widget _tabTourism() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.landscape_rounded,
          title: 'Tourisme & Sites remarquables',
          table: 'province_tourism_sites',
          list: _tourismSites,
          itemLabel: 'Site',
          blank: () => {'name': '', 'type': '', 'description': '', 'media': <Map<String, dynamic>>[]},
          emptyText: 'Aucun site ajouté',
          emptyIcon: Icons.landscape_outlined,
          fields: (i) => [
            _tf(_tourismSites, i, 'name', 'Nom du site', Icons.place_rounded),
            _tf(_tourismSites, i, 'type', 'Type (Parc, Cascade...)', Icons.category_rounded),
            _tf(_tourismSites, i, 'description', 'Description', Icons.description_rounded, lines: 3),
            _multiMediaGallery('Galerie photos & vidéos', _tourismSites[i]['media'], 'tourism', () => setState(() {})),
          ],
        ),
      ]);

  Widget _tabAdminOthers() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.dashboard_customize_rounded,
          title: 'Découpage administratif',
          table: 'province_administrative_divisions',
          list: _administrativeDivisions,
          itemLabel: 'Division',
          blank: () => {
            'type': 'Territoire', 'name': '', 'capital': '', 'population': '', 'area': '', 'administrator': '',
            'media': <Map<String, dynamic>>[],
          },
          emptyText: 'Aucune division ajoutée',
          emptyIcon: Icons.account_tree_outlined,
          fields: (i) => [
            _dd(_administrativeDivisions, i, 'type', 'Type',
                const ['Territoire', 'Ville', 'Commune', 'Secteur', 'Chefferie', 'Autre'], Icons.category_rounded),
            _tf(_administrativeDivisions, i, 'name', 'Nom', Icons.place_rounded),
            _tf(_administrativeDivisions, i, 'capital', 'Chef-lieu', Icons.star_rounded),
            Row(children: [
              Expanded(child: _tf(_administrativeDivisions, i, 'population', 'Population', Icons.groups_rounded, number: true)),
              const SizedBox(width: 8),
              Expanded(child: _tf(_administrativeDivisions, i, 'area', 'Superficie (km²)', Icons.map_rounded, number: true)),
            ]),
            _tf(_administrativeDivisions, i, 'administrator', 'Administrateur', Icons.person_rounded),
            _multiMediaGallery('Galerie', _administrativeDivisions[i]['media'], 'admin_divisions', () => setState(() {})),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.emoji_events_rounded,
          title: 'Réalisations majeures',
          table: 'province_achievements',
          list: _achievements,
          itemLabel: 'Réalisation',
          blank: () => {'title': '', 'description': '', 'date': '', 'location': '', 'media': <Map<String, dynamic>>[]},
          emptyText: 'Aucune réalisation ajoutée',
          emptyIcon: Icons.emoji_events_outlined,
          fields: (i) => [
            _tf(_achievements, i, 'title', 'Titre', Icons.title_rounded),
            _dateF(_achievements, i, 'date', 'Date'),
            _tf(_achievements, i, 'location', 'Lieu', Icons.location_on_rounded),
            _tf(_achievements, i, 'description', 'Description', Icons.description_rounded, lines: 3),
            _multiMediaGallery('Galerie', _achievements[i]['media'], 'achievements', () => setState(() {})),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.emergency_rounded,
          title: 'Urgences & Contacts',
          table: 'province_emergency_contacts',
          list: _emergencyContacts,
          itemLabel: 'Contact',
          blank: () => {'service': '', 'phone': ''},
          emptyText: 'Aucun contact d\'urgence',
          emptyIcon: Icons.emergency_outlined,
          fields: (i) => [
            _tf(_emergencyContacts, i, 'service', 'Service', Icons.local_hospital_rounded),
            _tf(_emergencyContacts, i, 'phone', 'Numéro', Icons.phone_rounded, phone: true),
          ],
        ),
      ]);

  Widget _tabNewsProjects() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.newspaper_rounded,
          title: 'Actualités',
          table: 'province_news',
          list: _news,
          itemLabel: 'Actualité',
          blank: () => {
            'title': '', 'summary': '', 'category': 'INFO', 'url': '', 'image_url': '',
            'is_alert': false, 'is_published': true, 'published_at': _todayStr(),
          },
          emptyText: 'Aucune actualité',
          emptyIcon: Icons.newspaper_outlined,
          fields: (i) => [
            _tf(_news, i, 'title', 'Titre', Icons.title_rounded),
            _tf(_news, i, 'summary', 'Résumé', Icons.notes_rounded, lines: 2),
            _tf(_news, i, 'category', 'Catégorie (INFO, SANTÉ…)', Icons.label_rounded),
            _tf(_news, i, 'url', 'Lien de l\'article (https://…)', Icons.link_rounded),
            _fileF(_news, i, 'image_url', 'Image', 'news', _Kind.image),
            _dateF(_news, i, 'published_at', 'Date de publication'),
            _sw(_news, i, 'is_alert', 'Alerte importante (badge rouge)', def: false),
            _sw(_news, i, 'is_published', 'Publié'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.construction_rounded,
          title: 'Projets en cours',
          table: 'province_projects',
          list: _projects,
          itemLabel: 'Projet',
          blank: () => {
            'name': '', 'description': '', 'category': '', 'image_url': '', 'progress': '0', 'budget': '', 'deadline': '',
          },
          emptyText: 'Aucun projet',
          emptyIcon: Icons.construction_outlined,
          fields: (i) => [
            _tf(_projects, i, 'name', 'Nom du projet', Icons.title_rounded),
            _tf(_projects, i, 'category', 'Catégorie (Route, École…)', Icons.category_rounded),
            _tf(_projects, i, 'description', 'Description', Icons.notes_rounded, lines: 3),
            _tf(_projects, i, 'budget', 'Budget (texte libre, ex : 2,5 M USD)', Icons.payments_rounded),
            _dateF(_projects, i, 'deadline', 'Échéance'),
            _progressF(_projects, i),
            _fileF(_projects, i, 'image_url', 'Image', 'projects', _Kind.image),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.badge_rounded,
          title: 'Services publics',
          table: 'province_services',
          list: _services,
          itemLabel: 'Service',
          blank: () => {
            'name': '', 'description': '', 'category': '', 'hours': '', 'address': '', 'phone': '', 'is_active': true,
          },
          emptyText: 'Aucun service',
          emptyIcon: Icons.badge_outlined,
          fields: (i) => [
            _tf(_services, i, 'name', 'Nom du service', Icons.title_rounded),
            _tf(_services, i, 'category', 'Catégorie', Icons.category_rounded),
            _tf(_services, i, 'description', 'Description', Icons.notes_rounded, lines: 2),
            _tf(_services, i, 'hours', 'Horaires (ex : Lun-Ven 8h-16h)', Icons.access_time_rounded),
            _tf(_services, i, 'address', 'Adresse', Icons.location_on_rounded),
            _tf(_services, i, 'phone', 'Téléphone', Icons.phone_rounded, phone: true),
            _sw(_services, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
      ]);

  Widget _tabCitizenQuiz() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.how_to_vote_rounded,
          title: 'Engagement citoyen',
          table: 'province_engagements',
          list: _engagements,
          itemLabel: 'Consultation',
          blank: () => {'type': 'Sondage', 'title': '', 'description': '', 'participants_count': '0', 'is_active': true},
          emptyText: 'Aucune consultation',
          emptyIcon: Icons.how_to_vote_outlined,
          fields: (i) => [
            _dd(_engagements, i, 'type', 'Type', const ['Sondage', 'Vote', 'Pétition'], Icons.category_rounded),
            _tf(_engagements, i, 'title', 'Titre', Icons.title_rounded),
            _tf(_engagements, i, 'description', 'Description', Icons.notes_rounded, lines: 3),
            _tf(_engagements, i, 'participants_count', 'Participants (initial)', Icons.people_rounded, number: true),
            _sw(_engagements, i, 'is_active', 'Ouverte aux citoyens'),
          ],
        ),
        _gap,
        _listSection(
          icon: Icons.quiz_rounded,
          title: 'Quiz de la province',
          table: 'province_quiz_questions',
          list: _quiz,
          itemLabel: 'Question',
          blank: () => {
            'question': '', 'opts': <String>['', '', '', ''], 'correct': 0, 'is_active': true,
          },
          emptyText: 'Aucune question',
          emptyIcon: Icons.quiz_outlined,
          note: const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Touchez ✓ à gauche d\'une réponse pour la définir comme bonne réponse.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          fields: (i) => [
            _tf(_quiz, i, 'question', 'Question', Icons.help_outline_rounded, lines: 2),
            ..._quizOptions(i),
            _sw(_quiz, i, 'is_active', 'Visible dans l\'application'),
          ],
        ),
      ]);

  Widget _tabMediaDocs() => ListView(padding: const EdgeInsets.all(16), children: [
        _listSection(
          icon: Icons.play_circle_rounded,
          title: 'Médiathèque (vidéos, audios, photos)',
          table: 'province_media',
          list: _mediaItems,
          itemLabel: 'Média',
          blank: () => {
            'title': '', 'type': 'video', 'url': '', 'thumbnail_url': '', 'duration': '',
            'is_published': true, 'published_at': _todayStr(),
          },
          emptyText: 'Aucun média',
          emptyIcon: Icons.play_circle_outline_rounded,
          fields: (i) {
            final type = _mediaItems[i]['type']?.toString() ?? 'video';
            final kind = type == 'audio' ? _Kind.audio : (type == 'photo' ? _Kind.image : _Kind.video);
            return [
              _tf(_mediaItems, i, 'title', 'Titre', Icons.title_rounded),
              _ddCb(_mediaItems, i, 'type', 'Type', const ['video', 'audio', 'photo'], Icons.category_rounded,
                  onChanged: () => setState(() => _mediaItems[i]['url'] = '')),
              _fileF(_mediaItems, i, 'url', 'Fichier ($type) depuis l\'appareil', 'media', kind),
              _fileF(_mediaItems, i, 'thumbnail_url', 'Miniature', 'media_thumbs', _Kind.image),
              _tf(_mediaItems, i, 'duration', 'Durée (ex : 03:45)', Icons.timer_outlined),
              _dateF(_mediaItems, i, 'published_at', 'Date de publication'),
              _sw(_mediaItems, i, 'is_published', 'Publié'),
            ];
          },
        ),
        _gap,
        _listSection(
          icon: Icons.description_rounded,
          title: 'Documents officiels',
          table: 'province_documents',
          list: _documents,
          itemLabel: 'Document',
          blank: () => {
            'title': '', 'type': 'Autre', 'file_url': '', 'is_published': true, 'published_at': _todayStr(),
          },
          emptyText: 'Aucun document',
          emptyIcon: Icons.description_outlined,
          fields: (i) => [
            _tf(_documents, i, 'title', 'Titre', Icons.title_rounded),
            _dd(_documents, i, 'type', 'Type',
                const ['Loi', 'Décret', 'Arrêté', 'Rapport', 'Budget', 'Autre'], Icons.category_rounded),
            _fileF(_documents, i, 'file_url', 'Fichier (PDF, Word, Excel…)', 'documents', _Kind.document),
            _dateF(_documents, i, 'published_at', 'Date de publication'),
            _sw(_documents, i, 'is_published', 'Publié'),
          ],
        ),
      ]);

  String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);

  List<Widget> _quizOptions(int i) {
    final q = _quiz[i];
    final opts = (q['opts'] as List).cast<String>();
    final correct = (q['correct'] as int?) ?? 0;
    return [
      for (int k = 0; k < opts.length; k++)
        Row(children: [
          IconButton(
            tooltip: 'Bonne réponse',
            icon: Icon(
              correct == k ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: correct == k ? AppColors.success : Colors.grey,
            ),
            onPressed: () {
              setState(() => _quiz[i]['correct'] = k);
              _touch();
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: opts[k],
              maxLength: 200,
              onChanged: (v) => opts[k] = v,
              decoration: _inputDeco('Réponse ${String.fromCharCode(65 + k)}', Icons.short_text_rounded),
            ),
          ),
        ]),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // CHAMPS GÉNÉRIQUES POUR LES LISTES
  // ═══════════════════════════════════════════════════════════════
  Widget _listSection({
    required IconData icon,
    required String title,
    required String table,
    required List<Map<String, dynamic>> list,
    required Map<String, dynamic> Function() blank,
    required String itemLabel,
    required List<Widget> Function(int i) fields,
    String emptyText = 'Aucun élément',
    IconData emptyIcon = Icons.inbox_outlined,
    Widget? note,
  }) {
    return _sectionCard(
      icon: icon,
      title: title,
      action: TextButton.icon(
        onPressed: () {
          setState(() => list.add({...blank(), '_key': _newKey(), 'id': null}));
          _touch();
        },
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Ajouter'),
      ),
      children: [
        if (note != null) note,
        for (int i = 0; i < list.length; i++) ...[
          _itemCard(itemLabel, table, list, i, fields(i)),
          const SizedBox(height: 12),
        ],
        if (list.isEmpty) _EmptyHint(icon: emptyIcon, text: emptyText),
      ],
    );
  }

  Widget _itemCard(String label, String table, List<Map<String, dynamic>> list, int i, List<Widget> children) {
    return Container(
      key: ValueKey(list[i]['_key']),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('$label ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
            onPressed: () => _removeItem(table, list, i),
          ),
        ]),
        for (final w in children) ...[w, const SizedBox(height: 8)],
      ]),
    );
  }

  Widget _tf(List<Map<String, dynamic>> list, int i, String key, String label, IconData icon,
      {int lines = 1, bool number = false, bool phone = false}) {
    return TextFormField(
      initialValue: list[i][key]?.toString() ?? '',
      maxLines: lines,
      maxLength: lines > 1 ? 5000 : 300,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : (phone ? TextInputType.phone : (lines > 1 ? TextInputType.multiline : TextInputType.text)),
      inputFormatters: [
        if (number) FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
        if (phone) FilteringTextInputFormatter.allow(RegExp(r'[0-9+*#() .-]')),
      ],
      onChanged: (v) => list[i][key] = v,
      decoration: _inputDeco(label, icon),
    );
  }

  Widget _dd(List<Map<String, dynamic>> list, int i, String key, String label, List<String> options, IconData icon) =>
      _ddCb(list, i, key, label, options, icon);

  Widget _ddCb(List<Map<String, dynamic>> list, int i, String key, String label, List<String> options, IconData icon,
      {VoidCallback? onChanged}) {
    final cur = list[i][key]?.toString() ?? '';
    final value = options.contains(cur) ? cur : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDeco(label, icon),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => list[i][key] = v);
        onChanged?.call();
        _touch();
      },
    );
  }

  Widget _sw(List<Map<String, dynamic>> list, int i, String key, String label, {bool def = true}) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      value: _bool(list[i], key, def: def),
      onChanged: (v) {
        setState(() => list[i][key] = v);
        _touch();
      },
    );
  }

  Widget _dateF(List<Map<String, dynamic>> list, int i, String key, String label) {
    final cur = list[i][key]?.toString() ?? '';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final initial = DateTime.tryParse(cur) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null && mounted) {
          setState(() => list[i][key] = picked.toIso8601String().substring(0, 10));
          _touch();
        }
      },
      child: InputDecorator(
        decoration: _inputDeco(label, Icons.calendar_today_rounded),
        child: Text(cur.isEmpty ? 'Choisir une date…' : cur,
            style: TextStyle(color: cur.isEmpty ? Colors.grey.shade600 : Colors.black87)),
      ),
    );
  }

  Widget _progressF(List<Map<String, dynamic>> list, int i) {
    final v = (double.tryParse(list[i]['progress']?.toString() ?? '') ?? 0).clamp(0, 100).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Progression : ${v.round()} %', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      Slider(
        value: v,
        min: 0,
        max: 100,
        divisions: 100,
        activeColor: AppColors.primary,
        label: '${v.round()} %',
        onChanged: (x) {
          setState(() => list[i]['progress'] = x.round().toString());
          _touch();
        },
      ),
    ]);
  }

  Widget _fileF(List<Map<String, dynamic>> list, int i, String key, String label, String folder, _Kind kind) {
    return _fileRow(
      label,
      list[i][key]?.toString(),
      folder,
      kind,
      (u) {
        setState(() => list[i][key] = u);
        _touch();
      },
      onClear: () {
        setState(() => list[i][key] = '');
        _touch();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGETS RÉUTILISABLES
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionCard({required IconData icon, required String title, Widget? action, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF101840))),
          ),
          if (action != null) action,
        ]),
        const Divider(height: 24, thickness: 1),
        ...children,
      ]),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool isNumber = false, bool uppercase = false, int maxLines = 1, int? maxLength}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength ?? (maxLines > 1 ? 5000 : 300),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isNumber) FilteringTextInputFormatter.digitsOnly,
        if (uppercase)
          TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
      ],
      decoration: _inputDeco(required ? '$label *' : label, icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      counterText: '',
      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  /// Sélecteur de fichier local (photo, vidéo, audio, document).
  Widget _fileRow(String label, String? currentUrl, String folder, _Kind kind, void Function(String url) onUpdated,
      {VoidCallback? onClear}) {
    final has = currentUrl != null && currentUrl.trim().isNotEmpty;
    Widget thumb;
    if (!has) {
      thumb = Icon(kind.icon, color: Colors.grey, size: 24);
    } else if (kind == _Kind.image) {
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: currentUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
        ),
      );
    } else {
      thumb = Icon(kind.icon, color: AppColors.primary, size: 26);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(child: thumb),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              has ? 'Fichier chargé ✓' : 'Aucun fichier · max ${kind.maxBytes ~/ (1024 * 1024)} Mo',
              style: TextStyle(fontSize: 11, color: has ? AppColors.success : Colors.grey.shade600),
            ),
          ]),
        ),
        if (has && onClear != null)
          IconButton(
            tooltip: 'Retirer',
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
            onPressed: _isBusy ? null : onClear,
          ),
        ElevatedButton.icon(
          onPressed: _isBusy
              ? null
              : () async {
                  final u = await _pickSingle(kind, folder);
                  if (u != null && mounted) onUpdated(u);
                },
          icon: const Icon(Icons.upload_rounded, size: 16),
          label: Text(has ? 'Changer' : 'Choisir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ]),
    );
  }

  Widget _multiMediaGallery(String label, List<dynamic> mediaList, String folder, VoidCallback onUpdate,
      {String? deleteTable}) {
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isVideo
                    ? Container(color: AppColors.primary, child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28))
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
                      ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  final removed = mediaList.removeAt(idx);
                  if (deleteTable != null && removed is Map) {
                    final id = removed['id']?.toString().trim() ?? '';
                    if (id.isNotEmpty) (_deletedIds[deleteTable] ??= <String>{}).add(id);
                  }
                  onUpdate();
                  _touch();
                },
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ]);
        }),
        InkWell(
          onTap: _isBusy
              ? null
              : () => _pickMulti(folder, (url, type) {
                    mediaList.add({'url': url, 'type': type, '_key': _newKey()});
                    onUpdate();
                    _touch();
                  }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      Text('Photos : max ${_kMaxImageBytes ~/ (1024 * 1024)} Mo · Vidéos : max ${_kMaxVideoBytes ~/ (1024 * 1024)} Mo',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
    ]);
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDATION AVANT ENVOI
  // ═══════════════════════════════════════════════════════════════
  /// Retourne un message d'erreur (et ouvre l'onglet concerné) ou null si tout est valide.
  String? _validate() {
    String? fail(int tab, String msg) {
      _tabCtrl.animateTo(tab);
      return msg;
    }

    final site = _websiteCtrl.text.trim();
    if (site.isNotEmpty && !_isHttp(site)) return fail(0, 'Site web : l\'adresse doit commencer par http:// ou https://');

    for (var i = 0; i < _quiz.length; i++) {
      final q = _quiz[i];
      if (!_hasText(q, 'question')) continue;
      final opts = (q['opts'] as List).map((e) => e.toString().trim()).toList();
      final filled = opts.where((o) => o.isNotEmpty).length;
      final correct = (q['correct'] as int?) ?? 0;
      if (filled < 2) return fail(9, 'Quiz question ${i + 1} : au moins 2 réponses sont nécessaires.');
      if (correct >= opts.length || opts[correct].isEmpty) {
        return fail(9, 'Quiz question ${i + 1} : la bonne réponse doit être renseignée.');
      }
    }
    for (var i = 0; i < _news.length; i++) {
      final u = _news[i]['url']?.toString().trim() ?? '';
      if (u.isNotEmpty && !_isHttp(u)) return fail(8, 'Actualité ${i + 1} : le lien doit commencer par http:// ou https://');
    }
    for (var i = 0; i < _businesses.length; i++) {
      final u = _businesses[i]['website']?.toString().trim() ?? '';
      if (u.isNotEmpty && !_isHttp(u)) return fail(5, 'Entreprise ${i + 1} : le site doit commencer par http:// ou https://');
    }
    for (var i = 0; i < _budget.length; i++) {
      if (!_hasText(_budget[i], 'sector')) continue;
      final a = _toNum(_budget[i]['amount']);
      if (a == null || a < 0) return fail(5, 'Budget poste ${i + 1} : montant invalide.');
    }
    for (var i = 0; i < _demographics.length; i++) {
      final d = _demographics[i];
      if (!_hasText(d, 'year') && !_hasText(d, 'population')) continue;
      final y = _toInt(d['year']);
      final p = _toInt(d['population']);
      if (y == null || y < 1800 || y > 2100) return fail(5, 'Démographie ligne ${i + 1} : année invalide (1800-2100).');
      if (p == null || p < 0) return fail(5, 'Démographie ligne ${i + 1} : population invalide.');
    }
    for (var i = 0; i < _mediaItems.length; i++) {
      if (_hasText(_mediaItems[i], 'title') && !_hasText(_mediaItems[i], 'url')) {
        return fail(10, 'Média ${i + 1} : choisissez un fichier.');
      }
    }
    for (var i = 0; i < _documents.length; i++) {
      if (_hasText(_documents[i], 'title') && !_hasText(_documents[i], 'file_url')) {
        return fail(10, 'Document ${i + 1} : choisissez un fichier.');
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // SAUVEGARDE
  // ═══════════════════════════════════════════════════════════════
  int _skipped = 0;

  /// Synchronise une table liée à la province :
  /// suppressions → dédoublonnage → insertion (les ids retournés sont mémorisés,
  /// donc un nouvel essai après erreur ne recrée pas les lignes) → mise à jour.
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

      final deleted = _deletedIds[table];
      if (deleted != null && deleted.isNotEmpty) {
        await client.from(table).delete().eq('province_id', provinceId).inFilter('id', deleted.toList());
        _deletedIds.remove(table);
      }

      final toInsert = <Map<String, dynamic>>[];
      final insertSrc = <Map<String, dynamic>>[];
      final toUpdate = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      final seenKeys = <String>{};

      for (final item in items) {
        if (isValid != null && !isValid(item)) {
          _skipped++;
          continue;
        }
        final id = item['id']?.toString().trim() ?? '';
        final hasId = id.isNotEmpty;

        if (hasId && !seenIds.add(id)) continue;
        if (dedupeBy != null && !seenKeys.add(dedupeBy(item))) continue;

        final row = toRow(item);
        row['province_id'] = provinceId;

        if (hasId) {
          row['id'] = id;
          toUpdate.add(row);
        } else {
          row.remove('id');
          toInsert.add(row);
          insertSrc.add(item);
        }
      }

      if (toInsert.isNotEmpty) {
        final res = await client.from(table).insert(toInsert).select('id');
        final rows = res as List;
        for (var k = 0; k < rows.length && k < insertSrc.length; k++) {
          insertSrc[k]['id'] = (rows[k] as Map)['id']?.toString();
        }
      }
      if (toUpdate.isNotEmpty) await client.from(table).upsert(toUpdate);
    } catch (e) {
      throw Exception('[$table] ${_cleanErr(e)}');
    }
  }

  Future<void> _saveHymn(String provinceId) async {
    final client = SupabaseConfig.client;
    final hasHymn = _hymnTitleCtrl.text.trim().isNotEmpty ||
        _hymnLyricsCtrl.text.trim().isNotEmpty ||
        _hymnAudioUrl != null ||
        _hymnInstrumentalUrl != null;
    try {
      if (!hasHymn) {
        if (_hymnId != null) {
          await client.from('province_hymns').delete().eq('id', _hymnId!);
          _hymnId = null;
        }
        return;
      }
      final row = <String, dynamic>{
        'province_id': provinceId,
        'title': _nullIfEmpty(_hymnTitleCtrl.text),
        'lyrics': _nullIfEmpty(_hymnLyricsCtrl.text),
        'audio_url': _hymnAudioUrl,
        'instrumental_url': _hymnInstrumentalUrl,
      };
      if (_hymnId != null) {
        await client.from('province_hymns').update(row).eq('id', _hymnId!);
      } else {
        final res = await client.from('province_hymns').insert(row).select('id');
        final rows = res as List;
        if (rows.isNotEmpty) _hymnId = (rows.first as Map)['id']?.toString();
      }
    } catch (e) {
      throw Exception('[province_hymns] ${_cleanErr(e)}');
    }
  }

  Future<void> _saveRelations(String pid) async {
    _skipped = 0;

    await _syncTable(
      table: 'cities',
      provinceId: pid,
      items: _cities,
      isValid: (c) => _hasText(c, 'name'),
      toRow: (c) => <String, dynamic>{
        'name': c['name'].toString().trim(),
        'is_capital': c['is_capital'] == true,
        'population': _toInt(c['population']),
        'mayor': _nullIfEmpty(c['mayor']),
        'mayor_photo_url': _nullIfEmpty(c['mayor_photo_url']),
        'image_url': _nullIfEmpty(c['image_url']),
        'media': _cleanMedia(c['media']),
      },
    );

    await _syncTable(
      table: 'province_economic_resources',
      provinceId: pid,
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
      provinceId: pid,
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
      provinceId: pid,
      items: _emergencyContacts,
      isValid: (e) => _hasText(e, 'service'),
      toRow: (e) => <String, dynamic>{
        'service': e['service'].toString().trim(),
        'phone': _nullIfEmpty(e['phone']),
      },
    );

    await _syncTable(
      table: 'province_administrative_divisions',
      provinceId: pid,
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

    await _syncTable(
      table: 'province_achievements',
      provinceId: pid,
      items: _achievements,
      isValid: (a) => _hasText(a, 'title'),
      toRow: (a) {
        final media = _cleanMedia(a['media']);
        return <String, dynamic>{
          'title': a['title'].toString().trim(),
          'description': _nullIfEmpty(a['description']),
          'date': _toDateString(a['date']),
          'location': _nullIfEmpty(a['location']),
          'media': media,
          'cover_image_url': media.isNotEmpty ? media.first['url'] : null,
        };
      },
    );

    await _syncTable(
      table: 'province_tribes',
      provinceId: pid,
      items: _tribes,
      isValid: (t) => _hasText(t, 'name'),
      toRow: (t) => <String, dynamic>{
        'name': t['name'].toString().trim(),
        'zone': _nullIfEmpty(t['zone']),
        'history': _nullIfEmpty(t['history']),
        'media': _cleanMedia(t['media']),
      },
    );

    await _syncTable(
      table: 'province_gallery_media',
      provinceId: pid,
      items: _galleryMedia,
      isValid: (m) => _hasText(m, 'url'),
      dedupeBy: (m) => m['url'].toString().trim(),
      toRow: (m) => <String, dynamic>{
        'url': m['url'].toString().trim(),
        'type': _nullIfEmpty(m['type']) ?? 'photo',
      },
    );

    await _syncTable(
      table: 'province_ministers',
      provinceId: pid,
      items: _ministers,
      isValid: (m) => _hasText(m, 'name'),
      toRow: (m) => <String, dynamic>{
        'name': m['name'].toString().trim(),
        'role': _nullIfEmpty(m['role']),
        'photo_url': _nullIfEmpty(m['photo_url']),
      },
    );

    // ── nouvelles sections ──
    await _syncTable(
      table: 'province_news',
      provinceId: pid,
      items: _news,
      isValid: (n) => _hasText(n, 'title'),
      toRow: (n) => <String, dynamic>{
        'title': n['title'].toString().trim(),
        'summary': _nullIfEmpty(n['summary']),
        'category': _nullIfEmpty(n['category']) ?? 'INFO',
        'url': _nullIfEmpty(n['url']),
        'image_url': _nullIfEmpty(n['image_url']),
        'is_alert': _bool(n, 'is_alert', def: false),
        'is_published': _bool(n, 'is_published'),
        'published_at': _tsOrNow(n['published_at']),
      },
    );

    await _syncTable(
      table: 'province_projects',
      provinceId: pid,
      items: _projects,
      isValid: (p) => _hasText(p, 'name'),
      toRow: (p) => <String, dynamic>{
        'name': p['name'].toString().trim(),
        'description': _nullIfEmpty(p['description']),
        'category': _nullIfEmpty(p['category']),
        'image_url': _nullIfEmpty(p['image_url']),
        'progress': ((_toNum(p['progress']) ?? 0).clamp(0, 100)) / 100,
        'budget': _nullIfEmpty(p['budget']),
        'deadline': _toDateString(p['deadline']),
      },
    );

    await _syncTable(
      table: 'province_services',
      provinceId: pid,
      items: _services,
      isValid: (s) => _hasText(s, 'name'),
      toRow: (s) => <String, dynamic>{
        'name': s['name'].toString().trim(),
        'description': _nullIfEmpty(s['description']),
        'category': _nullIfEmpty(s['category']),
        'hours': _nullIfEmpty(s['hours']),
        'address': _nullIfEmpty(s['address']),
        'phone': _nullIfEmpty(s['phone']),
        'is_active': _bool(s, 'is_active'),
      },
    );

    await _syncTable(
      table: 'province_engagements',
      provinceId: pid,
      items: _engagements,
      isValid: (e) => _hasText(e, 'title'),
      toRow: (e) => <String, dynamic>{
        'type': _nullIfEmpty(e['type']) ?? 'Sondage',
        'title': e['title'].toString().trim(),
        'description': _nullIfEmpty(e['description']),
        'participants_count': _toInt(e['participants_count']) ?? 0,
        'is_active': _bool(e, 'is_active'),
      },
    );

    // Budget : pourcentages calculés automatiquement
    final totalBudget = _budget
        .where((b) => _hasText(b, 'sector'))
        .fold<num>(0, (s, b) => s + (_toNum(b['amount']) ?? 0));
    await _syncTable(
      table: 'province_budget',
      provinceId: pid,
      items: _budget,
      isValid: (b) => _hasText(b, 'sector'),
      dedupeBy: (b) => b['sector'].toString().trim().toLowerCase(),
      toRow: (b) {
        final amount = _toNum(b['amount']) ?? 0;
        final pct = totalBudget > 0 ? (amount / totalBudget * 100) : 0;
        return <String, dynamic>{
          'sector': b['sector'].toString().trim(),
          'amount': amount,
          'percentage': double.parse(pct.toStringAsFixed(2)),
        };
      },
    );

    await _syncTable(
      table: 'province_demographics',
      provinceId: pid,
      items: _demographics,
      isValid: (d) => _toInt(d['year']) != null && _toInt(d['population']) != null,
      dedupeBy: (d) => '${_toInt(d['year'])}',
      toRow: (d) => <String, dynamic>{
        'year': _toInt(d['year']),
        'population': _toInt(d['population']),
      },
    );

    await _syncTable(
      table: 'province_documents',
      provinceId: pid,
      items: _documents,
      isValid: (d) => _hasText(d, 'title') && _hasText(d, 'file_url'),
      toRow: (d) => <String, dynamic>{
        'title': d['title'].toString().trim(),
        'type': _nullIfEmpty(d['type']) ?? 'Autre',
        'file_url': d['file_url'].toString().trim(),
        'is_published': _bool(d, 'is_published'),
        'published_at': _tsOrNow(d['published_at']),
      },
    );

    await _syncTable(
      table: 'province_media',
      provinceId: pid,
      items: _mediaItems,
      isValid: (m) => _hasText(m, 'title') && _hasText(m, 'url'),
      toRow: (m) => <String, dynamic>{
        'title': m['title'].toString().trim(),
        'type': _nullIfEmpty(m['type']) ?? 'video',
        'url': m['url'].toString().trim(),
        'thumbnail_url': _nullIfEmpty(m['thumbnail_url']),
        'duration': _nullIfEmpty(m['duration']),
        'is_published': _bool(m, 'is_published'),
        'published_at': _tsOrNow(m['published_at']),
      },
    );

    await _syncTable(
      table: 'province_famous_people',
      provinceId: pid,
      items: _famous,
      isValid: (f) => _hasText(f, 'name'),
      toRow: (f) => <String, dynamic>{
        'name': f['name'].toString().trim(),
        'field': _nullIfEmpty(f['field']),
        'achievement': _nullIfEmpty(f['achievement']),
        'bio': _nullIfEmpty(f['bio']),
        'photo_url': _nullIfEmpty(f['photo_url']),
        'is_active': _bool(f, 'is_active'),
      },
    );

    await _syncTable(
      table: 'province_gastronomy',
      provinceId: pid,
      items: _gastronomy,
      isValid: (g) => _hasText(g, 'name'),
      toRow: (g) => <String, dynamic>{
        'name': g['name'].toString().trim(),
        'description': _nullIfEmpty(g['description']),
        'ingredients': (g['ingredients']?.toString() ?? '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'image_url': _nullIfEmpty(g['image_url']),
        'is_active': _bool(g, 'is_active'),
      },
    );

    await _syncTable(
      table: 'province_proverbs',
      provinceId: pid,
      items: _proverbs,
      isValid: (p) => _hasText(p, 'text'),
      toRow: (p) => <String, dynamic>{
        'text': p['text'].toString().trim(),
        'translation': _nullIfEmpty(p['translation']),
        'meaning': _nullIfEmpty(p['meaning']),
        'language': _nullIfEmpty(p['language']),
        'is_active': _bool(p, 'is_active'),
      },
    );

    await _syncTable(
      table: 'province_businesses',
      provinceId: pid,
      items: _businesses,
      isValid: (b) => _hasText(b, 'name'),
      toRow: (b) => <String, dynamic>{
        'name': b['name'].toString().trim(),
        'sector': _nullIfEmpty(b['sector']),
        'employees': _toInt(b['employees']),
        'description': _nullIfEmpty(b['description']),
        'website': _nullIfEmpty(b['website']),
        'logo_url': _nullIfEmpty(b['logo_url']),
        'is_active': _bool(b, 'is_active'),
      },
    );

    await _syncTable(
      table: 'province_products',
      provinceId: pid,
      items: _products,
      isValid: (p) => _hasText(p, 'name'),
      toRow: (p) => <String, dynamic>{
        'name': p['name'].toString().trim(),
        'description': _nullIfEmpty(p['description']),
        'image_url': _nullIfEmpty(p['image_url']),
        'is_active': _bool(p, 'is_active'),
      },
    );

    for (var i = 0; i < _quiz.length; i++) {
      _quiz[i]['_order'] = i + 1;
    }
    await _syncTable(
      table: 'province_quiz_questions',
      provinceId: pid,
      items: _quiz,
      isValid: (q) => _hasText(q, 'question'),
      toRow: (q) {
        final opts = (q['opts'] as List).map((e) => e.toString().trim()).toList();
        final correct = (q['correct'] as int?) ?? 0;
        final out = <String>[];
        var newCorrect = 0;
        for (var k = 0; k < opts.length; k++) {
          if (opts[k].isEmpty) continue;
          if (k == correct) newCorrect = out.length;
          out.add(opts[k]);
        }
        return <String, dynamic>{
          'question': q['question'].toString().trim(),
          'options': out,
          'correct_answer': newCorrect,
          'order_index': q['_order'],
          'is_active': _bool(q, 'is_active'),
        };
      },
    );

    await _saveHymn(pid);
  }

  Future<void> _save() async {
    if (_isBusy) return;
    if (!_formKey.currentState!.validate()) {
      _tabCtrl.animateTo(0);
      _snack('⚠️ Veuillez remplir les champs obligatoires (avec *)', AppColors.warning);
      return;
    }
    final err = _validate();
    if (err != null) {
      _snack('⚠️ $err', AppColors.warning);
      return;
    }

    setState(() {
      _isBusy = true;
      _busyLabel = 'Enregistrement…';
    });
    try {
      final provinceData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
        'capital': _capitalCtrl.text.trim(),
        'region': _region,
        'motto': _nullIfEmpty(_mottoCtrl.text),
        'area': int.tryParse(_areaCtrl.text.trim()),
        'population': int.tryParse(_populationCtrl.text.trim()),
        'description': _nullIfEmpty(_descriptionCtrl.text),
        'history': _nullIfEmpty(_historyCtrl.text),
        'climate': _nullIfEmpty(_climateCtrl.text),
        'infrastructure': _nullIfEmpty(_infrastructureCtrl.text),
        'education': _nullIfEmpty(_educationCtrl.text),
        'cover_image_url': _coverImageUrl,
        'coat_of_arms_url': _coatOfArmsUrl,
        'flag_url': _flagUrl,
        'map_url': _mapUrl,
        'website': _nullIfEmpty(_websiteCtrl.text),
        'governor': _nullIfEmpty(_governorCtrl.text),
        'governor_photo_url': _governorPhotoUrl,
        'vice_governor': _nullIfEmpty(_viceGovernorCtrl.text),
        'vice_governor_photo_url': _viceGovernorPhotoUrl,
        'languages': _nullIfEmpty(_languagesCtrl.text),
        'resources': _nullIfEmpty(_resourcesCtrl.text),
        'territories_count': int.tryParse(_territoriesCountCtrl.text.trim()),
      };

      String savedProvinceId;
      if (_provinceId == null) {
        final res = await SupabaseConfig.client.from('provinces').insert(provinceData).select();
        savedProvinceId = (res as List).first['id'].toString();
        // Mémorisé tout de suite : un nouvel essai mettra à jour au lieu de recréer
        _provinceId = savedProvinceId;
        _isEditing = true;
      } else {
        await SupabaseConfig.client.from('provinces').update(provinceData).eq('id', _provinceId!);
        savedProvinceId = _provinceId!;
      }

      await _saveRelations(savedProvinceId);

      ref.invalidate(provincesProvider);
      ref.invalidate(adminProvincesProvider);
      ref.invalidate(provinceWithAllRelationsProvider(savedProvinceId));

      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _busyLabel = null;
      });
      _snack(
        _skipped > 0
            ? '✅ Province enregistrée ($_skipped élément(s) vide(s) ignoré(s))'
            : '✅ Province enregistrée avec succès',
        AppColors.success,
      );
      _leave();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _busyLabel = null;
      });
      _snack('❌ Erreur : ${_cleanErr(e)}', AppColors.danger);
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
