import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🏅 Niveaux de certification
class CertTier {
  static const String gratuit = 'gratuit';
  static const String premium = 'premium';
  static const String entreprise = 'entreprise';

  static String label(String t) {
    switch (t) {
      case premium:
        return 'Premium';
      case entreprise:
        return 'Entreprise';
      default:
        return 'Gratuit';
    }
  }

  static Color color(String t) {
    switch (t) {
      case premium:
        return const Color(0xFFF59E0B);
      case entreprise:
        return const Color(0xFF101840);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static IconData icon(String t) {
    switch (t) {
      case premium:
        return Icons.workspace_premium_rounded;
      case entreprise:
        return Icons.business_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  /// Durée par défaut à l'approbation
  static int defaultMonths(String t) => t == premium ? 1 : 12;
}

///  États possibles d'une certification
enum CertState { pending, active, expiring, suspended, expired, revoked, rejected }

/// 🏅 Certification d'un profil (vue admin)
@immutable
class AdminCertification {
  final String userId;
  final String thixId;
  final String displayName;
  final String? avatarUrl;
  final String accountType;
  final String tier;
  final String status;
  final DateTime? certifiedAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final String? notes;
  final DateTime? suspendedUntil;
  final String? suspensionReason;

  const AdminCertification({
    required this.userId,
    required this.thixId,
    required this.displayName,
    this.avatarUrl,
    required this.accountType,
    required this.tier,
    required this.status,
    this.certifiedAt,
    this.startsAt,
    this.expiresAt,
    this.autoRenew = false,
    this.notes,
    this.suspendedUntil,
    this.suspensionReason,
  });

  factory AdminCertification.fromJson(Map<String, dynamic> json) {
    return AdminCertification(
      userId: json['id']?.toString() ?? '',
      thixId: json['thix_id']?.toString() ?? '—',
      displayName: json['display_name']?.toString() ?? 'Utilisateur',
      avatarUrl: json['avatar_url']?.toString(),
      accountType: json['account_type']?.toString() ?? 'personal',
      tier: json['certification_tier']?.toString() ?? 'gratuit',
      status: json['certification_status']?.toString() ?? 'none',
      certifiedAt: _dt(json['certified_at']),
      startsAt: _dt(json['certification_starts_at']),
      expiresAt: _dt(json['certification_expires_at']),
      autoRenew: json['certification_auto_renew'] == true,
      notes: json['certification_notes']?.toString(),
      suspendedUntil: _dt(json['certification_suspended_until']),
      suspensionReason: json['certification_suspension_reason']?.toString(),
    );
  }

  static DateTime? _dt(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  // ─── ÉTAT CALCULÉ ───
  bool get isSuspended =>
      status == 'suspended' &&
      (suspendedUntil == null || suspendedUntil!.isAfter(DateTime.now()));

  bool get isPending => status == 'pending' || status == 'under_review';
  bool get isRevoked => status == 'revoked';
  bool get isRejected => status == 'rejected';

  bool get isExpired =>
      status == 'approved' &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now());

  bool get isExpiringSoon =>
      status == 'approved' &&
      !isExpired &&
      expiresAt != null &&
      expiresAt!.difference(DateTime.now()).inDays <= 30;

  bool get isActive => status == 'approved' && !isExpired && !isSuspended;

  CertState get state {
    if (isRevoked) return CertState.revoked;
    if (isRejected) return CertState.rejected;
    if (isSuspended) return CertState.suspended;
    if (isPending) return CertState.pending;
    if (isExpired) return CertState.expired;
    if (isExpiringSoon) return CertState.expiring;
    return CertState.active;
  }

  int get daysLeft => expiresAt == null
      ? 0
      : expiresAt!.difference(DateTime.now()).inDays;

  String get stateLabel {
    switch (state) {
      case CertState.pending:
        return 'En attente';
      case CertState.active:
        return 'Active';
      case CertState.expiring:
        return 'Expire bientôt';
      case CertState.suspended:
        return 'Suspendue';
      case CertState.expired:
        return 'Expirée';
      case CertState.revoked:
        return 'Révoquée';
      case CertState.rejected:
        return 'Refusée';
    }
  }

  Color get stateColor {
    switch (state) {
      case CertState.pending:
        return const Color(0xFFF59E0B);
      case CertState.active:
        return const Color(0xFF10B981);
      case CertState.expiring:
        return const Color(0xFFF97316);
      case CertState.suspended:
        return const Color(0xFFEF4444);
      case CertState.expired:
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
