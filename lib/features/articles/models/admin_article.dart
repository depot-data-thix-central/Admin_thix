import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 📰 Statuts d'un article
class ArticleStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String archived = 'archived';

  static const List<String> all = [draft, published, archived];

  static String label(String status) {
    switch (status) {
      case published:
        return 'Publié';
      case archived:
        return 'Archivé';
      default:
        return 'Brouillon';
    }
  }
}

/// 📰 Modèle Article (mirroir exact de la table news_articles / modèle PROD)
@immutable
class AdminArticle {
  final String id;
  final String title;
  final String? summary;
  final String content;
  final String category;
  final String? imageUrl;
  final String? videoUrl;
  final int viewsCount;
  final bool isFeatured;
  final bool isBreaking;
  final String status;
  final DateTime publishedAt;
  final DateTime createdAt;
  final String? createdBy;

  const AdminArticle({
    required this.id,
    required this.title,
    this.summary,
    required this.content,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    this.viewsCount = 0,
    this.isFeatured = false,
    this.isBreaking = false,
    this.status = ArticleStatus.draft,
    required this.publishedAt,
    required this.createdAt,
    this.createdBy,
  });

  /// 🆓 Brouillon vide pour le formulaire de création
  factory AdminArticle.draft() => AdminArticle(
        id: '',
        title: '',
        content: '',
        category: 'Annonces officielles',
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

  bool get isPublished => status == ArticleStatus.published;
  bool get isNew => id.isEmpty;

  // ─── FROM SUPABASE ───
  factory AdminArticle.fromJson(Map<String, dynamic> json) {
    return AdminArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sans titre',
      summary: json['summary']?.toString(),
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Général',
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] == true,
      isBreaking: json['is_breaking'] == true,
      status: json['status']?.toString() ?? ArticleStatus.draft,
      publishedAt: _parseDate(json['published_at']) ?? DateTime.now(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      createdBy: json['created_by']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  // ─── PAYLOAD SUPABASE ───
  Map<String, dynamic> toPayload({required bool isInsert, String? authorId}) {
    final map = <String, dynamic>{
      'title': sanitize(title),
      'summary': summary == null ? null : sanitize(summary!),
      'content': sanitize(content),
      'category': category,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'is_featured': isFeatured,
      'is_breaking': isBreaking,
      'status': status,
      'published_at': publishedAt.toIso8601String(),
    };
    if (isInsert) {
      map['views_count'] = 0;
      map['created_at'] = DateTime.now().toIso8601String();
      map['created_by'] = authorId;
    }
    return map;
  }

  AdminArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? category,
    String? imageUrl,
    String? videoUrl,
    int? viewsCount,
    bool? isFeatured,
    bool? isBreaking,
    String? status,
    DateTime? publishedAt,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AdminArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      viewsCount: viewsCount ?? this.viewsCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isBreaking: isBreaking ?? this.isBreaking,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ─── SÉCURITÉ : sanitization anti-XSS ───
  static String sanitize(String input) {
    var s = input;
    s = s.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
        '');
    s = s.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    return s.trim();
  }

  // ─── FORMATAGE DATE SÉCURISÉ ───
  String get formattedDate {
    try {
      return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(publishedAt);
    } catch (_) {
      final d = publishedAt.day.toString().padLeft(2, '0');
      final m = publishedAt.month.toString().padLeft(2, '0');
      return '$d/$m/${publishedAt.year}';
    }
  }
}

/// 🎯 Résultat d'une opération (save / delete / toggle)
class ArticleOpResult {
  final bool success;
  final String? error;
  final String? id;

  const ArticleOpResult({required this.success, this.error, this.id});

  factory ArticleOpResult.ok([String? id]) =>
      ArticleOpResult(success: true, id: id);
  factory ArticleOpResult.fail(String error) =>
      ArticleOpResult(success: false, error: error);
}
