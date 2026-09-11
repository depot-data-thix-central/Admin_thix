import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 🛡️ Types d'événements
class SecurityEventType {
  static const String loginFailed = 'login_failed';
  static const String loginBlocked = 'login_blocked';
  static const String clientError = 'client_error';
  static const String adminAction = 'admin_action';
  static const String rateLimit = 'rate_limit';
  static const String permissionDenied = 'permission_denied';
  static const String suspicious = 'suspicious';

  static const List<String> all = [
    loginFailed,
    loginBlocked,
    clientError,
    adminAction,
    rateLimit,
    permissionDenied,
    suspicious,
  ];

  static String label(String t) {
    switch (t) {
      case loginFailed:
        return 'Échec de connexion';
      case loginBlocked:
        return 'Connexion bloquée';
      case clientError:
        return 'Erreur applicative';
      case adminAction:
        return 'Action admin';
      case rateLimit:
        return 'Limite de débit';
      case permissionDenied:
        return 'Permission refusée';
      default:
        return 'Activité suspecte';
    }
  }

  static IconData icon(String t) {
    switch (t) {
      case loginFailed:
        return Icons.lock_outline_rounded;
      case loginBlocked:
        return Icons.block_rounded;
      case clientError:
        return Icons.bug_report_outlined;
      case adminAction:
        return Icons.admin_panel_settings_rounded;
      case rateLimit:
        return Icons.speed_rounded;
      case permissionDenied:
        return Icons.remove_moderator_rounded;
      default:
        return Icons.gpp_maybe_outlined;
    }
  }
}

/// 🚨 Niveaux de sévérité
class SecuritySeverity {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> all = [low, medium, high, critical];

  static String label(String s) {
    switch (s) {
      case critical:
        return 'CRITIQUE';
      case high:
        return 'Élevé';
      case medium:
        return 'Moyen';
      default:
        return 'Faible';
    }
  }

  static Color color(String s) {
    switch (s) {
      case critical:
        return const Color(0xFFB91C1C);
      case high:
        return const Color(0xFFF97316);
      case medium:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

/// 🛡️ Événement de sécurité
@immutable
class SecurityEvent {
  final String id;
  final String eventType;
  final String severity;
  final String source;
  final String? userId;
  final String? identifier;
  final String? ipAddress;
  final String? userAgent;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String status; // new | acknowledged | resolved
  final String? handledBy;
  final DateTime? handledAt;

  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.source,
    this.userId,
    this.identifier,
    this.ipAddress,
    this.userAgent,
    required this.message,
    this.metadata = const {},
    required this.createdAt,
    this.status = 'new',
    this.handledBy,
    this.handledAt,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'suspicious',
      severity: json['severity']?.toString() ?? 'low',
      source: json['source']?.toString() ?? 'unknown',
      userId: json['user_id']?.toString(),
      identifier: json['identifier']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      message: json['message']?.toString() ?? '',
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'new',
      handledBy: json['handled_by']?.toString(),
      handledAt: _parseDate(json['handled_at']),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  bool get isHandled => status != 'new';
  bool get isCritical =>
      severity == SecuritySeverity.critical || severity == SecuritySeverity.high;

  String get relativeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}

/// 🔑 Menace brute force
@immutable
class BruteForceThreat {
  final String identifier;
  final int attempts;
  final DateTime lastAttempt;
  final Set<String> ipAddresses;
  final String? userId; // ⬅️ AJOUT : compte lié si connu

  const BruteForceThreat({
    required this.identifier,
    required this.attempts,
    required this.lastAttempt,
    required this.ipAddresses,
    this.userId,
  });

  String get severity => attempts >= 10
      ? SecuritySeverity.critical
      : (attempts >= 7 ? SecuritySeverity.high : SecuritySeverity.medium);

  String get description =>
      '$attempts tentatives échouées en 24 h depuis ${ipAddresses.length} IP différente(s)';
}

/// 🐛 Erreur agrégée
@immutable
class AggregatedError {
  final String message;
  final int count;
  final DateTime lastOccurrence;

  const AggregatedError({
    required this.message,
    required this.count,
    required this.lastOccurrence,
  });
}

/// ⛔ Entrée de liste noire
@immutable
class SecurityBlock {
  final String id;
  final String type; // identifier | ip
  final String value;
  final String reason;
  final String severity;
  final DateTime? expiresAt;
  final bool active;
  final DateTime createdAt;

  const SecurityBlock({
    required this.id,
    required this.type,
    required this.value,
    required this.reason,
    required this.severity,
    this.expiresAt,
    required this.active,
    required this.createdAt,
  });

  factory SecurityBlock.fromJson(Map<String, dynamic> json) {
    return SecurityBlock(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'identifier',
      value: json['value']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'high',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal()
          : null,
      active: json['active'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPermanent => expiresAt == null;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get expiryLabel {
    if (isPermanent) return 'Définitif';
    if (isExpired) return 'Expiré';
    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.inHours < 1) return 'Expire dans ${remaining.inMinutes} min';
    if (remaining.inDays < 1) return 'Expire dans ${remaining.inHours} h';
    return 'Expire dans ${remaining.inDays} j';
  }
}
