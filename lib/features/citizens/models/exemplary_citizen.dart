import 'package:flutter/foundation.dart';

/// 👤 Citoyen exemplaire (miroir de exemplary_citizens)
@immutable
class ExemplaryCitizen {
  final String id;
  final String fullName;
  final String domain;
  final String? shortDescription;
  final String biography;
  final String? photoUrl;
  final DateTime? recognitionDate;
  final List<Map<String, dynamic>> media;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExemplaryCitizen({
    required this.id,
    required this.fullName,
    required this.domain,
    this.shortDescription,
    required this.biography,
    this.photoUrl,
    this.recognitionDate,
    this.media = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ExemplaryCitizen.fromJson(Map<String, dynamic> json) {
    return ExemplaryCitizen(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Citoyen',
      domain: json['domain']?.toString() ?? 'Général',
      shortDescription: json['short_description']?.toString(),
      biography: json['biography']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      recognitionDate: _dt(json['recognition_date']),
      media: (json['media'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      isActive: json['is_active'] == true,
      createdAt: _dt(json['created_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']),
    );
  }

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  String get formattedDate {
    if (recognitionDate == null) return 'Date inconnue';
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final d = recognitionDate!;
    return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
  }

  Map<String, dynamic> toPayload({required bool isInsert}) {
    final map = <String, dynamic>{
      'full_name': fullName,
      'domain': domain,
      'short_description': shortDescription,
      'biography': biography,
      'photo_url': photoUrl,
      'recognition_date': recognitionDate?.toIso8601String().split('T').first,
      'media': media.isEmpty ? [] : media,  // ✅ CORRIGÉ : [] au lieu de '[]'::jsonb
      'is_active': isActive,
    };
    if (isInsert) {
      map['created_at'] = DateTime.now().toIso8601String();
    }
    return map;
  }

  ExemplaryCitizen copyWith({
    String? fullName,
    String? domain,
    String? shortDescription,
    String? biography,
    String? photoUrl,
    DateTime? recognitionDate,
    List<Map<String, dynamic>>? media,
    bool? isActive,
  }) {
    return ExemplaryCitizen(
      id: id,
      fullName: fullName ?? this.fullName,
      domain: domain ?? this.domain,
      shortDescription: shortDescription ?? this.shortDescription,
      biography: biography ?? this.biography,
      photoUrl: photoUrl ?? this.photoUrl,
      recognitionDate: recognitionDate ?? this.recognitionDate,
      media: media ?? this.media,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 🎯 Résultat d'une opération
class CitizenOpResult {
  final bool success;
  final String? id;
  final String? error;

  const CitizenOpResult._({required this.success, this.id, this.error});

  factory CitizenOpResult.ok([String? id]) =>
      CitizenOpResult._(success: true, id: id);

  factory CitizenOpResult.fail(String error) =>
      CitizenOpResult._(success: false, error: error);
}
