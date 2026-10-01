import 'package:flutter/foundation.dart';

/// 🏛️ Figure historique (miroir de historical_figures)
@immutable
class HistoricalFigure {
  final String id;
  final String fullName;
  final String role;
  final String category;
  final String era;
  final String? quote;
  final String biography;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  const HistoricalFigure({
    required this.id,
    required this.fullName,
    required this.role,
    required this.category,
    required this.era,
    this.quote,
    required this.biography,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory HistoricalFigure.fromJson(Map<String, dynamic> json) {
    return HistoricalFigure(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? 'Figure historique').toString(),
      role: (json['role'] ?? '').toString(),
      category: (json['category'] ?? 'Politique').toString(),
      era: (json['era'] ?? '').toString(),
      quote: json['quote']?.toString(),
      biography: (json['biography'] ?? '').toString(),
      photoUrl: json['photo_url']?.toString(),
      isActive: json['is_active'] != false,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toPayload({required bool isInsert}) {
    final map = <String, dynamic>{
      'full_name': fullName,
      'role': role,
      'category': category,
      'era': era,
      'quote': quote,
      'biography': biography,
      'photo_url': photoUrl,
      'is_active': isActive,
    };
    if (isInsert) {
      map['created_at'] = DateTime.now().toIso8601String();
    }
    return map;
  }

  HistoricalFigure copyWith({
    String? fullName,
    String? role,
    String? category,
    String? era,
    String? quote,
    String? biography,
    String? photoUrl,
    bool? isActive,
  }) {
    return HistoricalFigure(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      category: category ?? this.category,
      era: era ?? this.era,
      quote: quote ?? this.quote,
      biography: biography ?? this.biography,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// 🎯 Résultat d'une opération
class HistoricalFigureOpResult {
  final bool success;
  final String? id;
  final String? error;

  const HistoricalFigureOpResult._({
    required this.success,
    this.id,
    this.error,
  });

  factory HistoricalFigureOpResult.ok([String? id]) =>
      HistoricalFigureOpResult._(success: true, id: id);

  factory HistoricalFigureOpResult.fail(String error) =>
      HistoricalFigureOpResult._(success: false, error: error);
}
