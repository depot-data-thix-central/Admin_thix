import 'package:flutter/foundation.dart';

/// 📑 Statuts d'un article
class ArticleStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String archived = 'archived';

  static const List<String> all = [draft, published, archived];

  static String label(String s) {
    switch (s) {
      case published:
        return 'Publié';
      case archived:
        return 'Archivé';
      default:
        return 'Brouillon';
    }
  }
}

/// 📰 Article (mirroir de news_articles)
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
  final Map<String, dynamic> magazineExtras; // ⬅️ NOUVEAU

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
    required this.status,
    required this.publishedAt,
    required this.createdAt,
    this.createdBy,
    this.magazineExtras = const {},
  });

  factory AdminArticle.fromJson(Map<String, dynamic> json) {
    return AdminArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sans titre',
      summary: json['summary']?.toString(),
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Actualités',
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] == true,
      isBreaking: json['is_breaking'] == true,
      status: json['status']?.toString() ?? ArticleStatus.draft,
      publishedAt: _dt(json['published_at']) ?? DateTime.now(),
      createdAt: _dt(json['created_at']) ?? DateTime.now(),
      createdBy: json['created_by']?.toString(),
      magazineExtras:
          (json['magazine_extras'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  Map<String, dynamic> toPayload({required bool isInsert, String? authorId}) {
    final map = <String, dynamic>{
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'is_featured': isFeatured,
      'is_breaking': isBreaking,
      'status': status,
      'published_at': publishedAt.toIso8601String(),
      'magazine_extras': magazineExtras.isEmpty ? null : magazineExtras,
    };
    if (isInsert) {
      map['views_count'] = 0;
      map['created_at'] = DateTime.now().toIso8601String();
      map['created_by'] = authorId;
    }
    return map;
  }

  AdminArticle copyWith({
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
    Map<String, dynamic>? magazineExtras,
  }) {
    return AdminArticle(
      id: id,
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
      createdAt: createdAt,
      createdBy: createdBy,
      magazineExtras: magazineExtras ?? this.magazineExtras,
    );
  }
}

/// 🎯 Résultat d'une opération
class ArticleOpResult {
  final bool success;
  final String? id;
  final String? error;

  const ArticleOpResult._({required this.success, this.id, this.error});

  factory ArticleOpResult.ok([String? id]) =>
      ArticleOpResult._(success: true, id: id);

  factory ArticleOpResult.fail(String error) =>
      ArticleOpResult._(success: false, error: error);
}
