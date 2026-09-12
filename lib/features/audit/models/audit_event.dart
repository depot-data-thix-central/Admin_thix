import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🗂️ Catégories d'audit
class AuditCategory {
  static const String auth = 'auth';
  static const String profile = 'profile';
  static const String certification = 'certification';
  static const String content = 'content';
  static const String communication = 'communication';
  static const String security = 'security';
  static const String health = 'health';
  static const String documents = 'documents';
  static const String other = 'other';

  static const List<String> all = [
    auth, profile, certification, content,
    communication, security, health, documents, other,
  ];

  static String label(String c) {
    switch (c) {
      case auth: return 'Authentification';
      case profile: return 'Profil';
      case certification: return 'Certification';
      case content: return 'Contenu';
      case communication: return 'Communication';
      case security: return 'Sécurité';
      case health: return 'Santé';
      case documents: return 'Documents';
      default: return 'Autre';
    }
  }

  static IconData icon(String c) {
    switch (c) {
      case auth: return Icons.login_rounded;
      case profile: return Icons.person_outline_rounded;
      case certification: return Icons.verified_outlined;
      case content: return Icons.edit_note_rounded;
      case communication: return Icons.chat_bubble_outline_rounded;
      case security: return Icons.shield_outlined;
      case health: return Icons.favorite_outline_rounded;
      case documents: return Icons.description_outlined;
      default: return Icons.more_horiz_rounded;
    }
  }

  static Color color(String c) {
    switch (c) {
      case auth: return const Color(0xFF3B82F6);
      case profile: return const Color(0xFF8B5CF6);
      case certification: return const Color(0xFFF59E0B);
      case content: return const Color(0xFF10B981);
      case communication: return const Color(0xFF06B6D4);
      case security: return const Color(0xFFEF4444);
      case health: return const Color(0xFFEC4899);
      case documents: return const Color(0xFF64748B);
      default: return const Color(0xFF9CA3AF);
    }
  }
}

/// 📓 Événement d'audit
@immutable
class AuditEvent {
  final String id;
  final String category;
  final String action;
  final String? userId;
  final String? thixId;
  final String? displayName;
  final String summary;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String? device;
  final String? appVersion;
  final String source;
  final DateTime createdAt;

  const AuditEvent({
    required this.id,
    required this.category,
    required this.action,
    this.userId,
    this.thixId,
    this.displayName,
    required this.summary,
    this.details = const {},
    this.ipAddress,
    this.device,
    this.appVersion,
    required this.source,
    required this.createdAt,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      action: json['action']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      thixId: json['thix_id']?.toString(),
      displayName: json['display_name']?.toString(),
      summary: json['summary']?.toString() ?? '',
      details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      ipAddress: json['ip_address']?.toString(),
      device: json['device']?.toString(),
      appVersion: json['app_version']?.toString(),
      source: json['source']?.toString() ?? 'mobile_app',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  String get userLabel =>
      (displayName?.trim().isNotEmpty ?? false) ? displayName! : 'Utilisateur';

  String get relativeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  String get dateTimeLabel {
    final d = createdAt.day.toString().padLeft(2, '0');
    final m = createdAt.month.toString().padLeft(2, '0');
    final h = createdAt.hour.toString().padLeft(2, '0');
    final min = createdAt.minute.toString().padLeft(2, '0');
    return '$d/$m/${createdAt.year} à $h:$min';
  }
}
