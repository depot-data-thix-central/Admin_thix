// lib/features/opportunities/models/admin_opportunity.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 📑 Statuts d'une opportunité
class OpportunityStatus {
  static const String published = 'published';
  static const String countdown = 'countdown';
  static const String draft = 'draft';
  static const String archived = 'archived';

  static const List<String> all = [published, countdown, draft, archived];

  static String label(String s) {
    switch (s) {
      case published:
        return 'Publiée';
      case countdown:
        return 'Urgente';
      case archived:
        return 'Archivée';
      default:
        return 'Brouillon';
    }
  }

  static bool isVisible(String s) => s == published || s == countdown;
}

/// 🎯 Opportunité (miroir de thix_opportunities)
@immutable
class AdminOpportunity {
  final String id;
  final String title;
  final String organizer;
  final String location;
  final String category;
  final String rewardLabel;
  final String deadlineLabel;
  final DateTime deadline;
  final String description;
  final List<String> eligibility;
  final String? applyUrl;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminOpportunity({
    required this.id,
    required this.title,
    required this.organizer,
    required this.location,
    required this.category,
    required this.rewardLabel,
    required this.deadlineLabel,
    required this.deadline,
    required this.description,
    required this.eligibility,
    this.applyUrl,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminOpportunity.fromJson(Map<String, dynamic> json) {
    return AdminOpportunity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sans titre',
      organizer: json['organizer']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Opportunité',
      rewardLabel: json['reward_label']?.toString() ?? '',
      deadlineLabel: json['deadline_label']?.toString() ?? '',
      deadline: _dt(json['deadline']) ?? DateTime.now(),
      description: json['description']?.toString() ?? '',
      eligibility: _parseList(json['eligibility']),
      applyUrl: json['apply_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? OpportunityStatus.draft,
      createdAt: _dt(json['created_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']) ?? DateTime.now(),
    );
  }

  /// 🔒 Parsing sécurisé de 'eligibility' (List, String JSON, ou String simple)
  static List<String> _parseList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      final str = v.trim();
      if (str.startsWith('[') && str.endsWith(']')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
      return [str];
    }
    return const [];
  }

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  // ─── GETTERS UTILITAIRES ───
  bool get isVisible => OpportunityStatus.isVisible(status);
  bool get isDraft => status == OpportunityStatus.draft;
  bool get isArchived => status == OpportunityStatus.archived;

  int get daysLeft => deadline.difference(DateTime.now()).inDays;
  bool get isClosing => daysLeft >= 0 && daysLeft <= 7 && isVisible;
  bool get isExpired => daysLeft < 0;

  String get deadlineRelative {
    if (isExpired) return 'Clôturée';
    if (daysLeft == 0) return "Aujourd'hui";
    if (daysLeft == 1) return 'Demain';
    if (daysLeft <= 7) return '$daysLeft j restants';
    if (daysLeft <= 30) return '$daysLeft j';
    return '${(daysLeft / 30).floor()} mois';
  }

  String get formattedDate {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final d = createdAt;
    return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
  }

  Map<String, dynamic> toPayload({required bool isInsert}) {
    final map = <String, dynamic>{
      'title': title,
      'organizer': organizer,
      'location': location,
      'category': category,
      'reward_label': rewardLabel,
      'deadline_label': deadlineLabel,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'eligibility': eligibility,
      'apply_url': applyUrl,
      'image_url': imageUrl,
      'status': status,
    };
    if (isInsert) {
      map['created_at'] = DateTime.now().toIso8601String();
    }
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }

  AdminOpportunity copyWith({
    String? title,
    String? organizer,
    String? location,
    String? category,
    String? rewardLabel,
    String? deadlineLabel,
    DateTime? deadline,
    String? description,
    List<String>? eligibility,
    String? applyUrl,
    String? imageUrl,
    String? status,
  }) {
    return AdminOpportunity(
      id: id,
      title: title ?? this.title,
      organizer: organizer ?? this.organizer,
      location: location ?? this.location,
      category: category ?? this.category,
      rewardLabel: rewardLabel ?? this.rewardLabel,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      eligibility: eligibility ?? this.eligibility,
      applyUrl: applyUrl ?? this.applyUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// 🎯 Résultat d'une opération
class OpportunityOpResult {
  final bool success;
  final String? id;
  final String? error;

  const OpportunityOpResult._({required this.success, this.id, this.error});

  factory OpportunityOpResult.ok([String? id]) =>
      OpportunityOpResult._(success: true, id: id);

  factory OpportunityOpResult.fail(String error) =>
      OpportunityOpResult._(success: false, error: error);
}
