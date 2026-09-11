import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 👤 Profil utilisateur (mirroir de la table public.profiles)
@immutable
class AdminUserProfile {
  final String id;
  final String thixId;
  final String? thixChat;
  final String displayName;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String accountType;
  final String accountStatus;
  final String status;
  final String certificationTier;
  final String certificationStatus;
  final DateTime? certifiedAt;
  final DateTime? certificationExpiresAt;
  final String? countryOrOrigin;
  final String? phoneNumber;
  final String? contactPhone;
  final String? occupation;
  final String? profession;
  final String? registrationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool twoFaEnabled;
  final bool biometricsEnabled;
  final DateTime? scheduledDeletionAt;
  final String? bio;

  const AdminUserProfile({
    required this.id,
    required this.thixId,
    this.thixChat,
    required this.displayName,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.accountType,
    required this.accountStatus,
    required this.status,
    required this.certificationTier,
    required this.certificationStatus,
    this.certifiedAt,
    this.certificationExpiresAt,
    this.countryOrOrigin,
    this.phoneNumber,
    this.contactPhone,
    this.occupation,
    this.profession,
    this.registrationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.twoFaEnabled = false,
    this.biometricsEnabled = false,
    this.scheduledDeletionAt,
    this.bio,
  });

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id']?.toString() ?? '',
      thixId: json['thix_id']?.toString() ?? 'THIX-PENDING',
      thixChat: json['thix_chat']?.toString(),
      displayName: json['display_name']?.toString() ?? 'Utilisateur THIX',
      fullName: json['full_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString() ?? 'user',
      accountType: json['account_type']?.toString() ?? 'personal',
      accountStatus: json['account_status']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'active',
      certificationTier: json['certification_tier']?.toString() ?? 'gratuit',
      certificationStatus: json['certification_status']?.toString() ?? 'none',
      certifiedAt: _parseDate(json['certified_at']),
      certificationExpiresAt: _parseDate(json['certification_expires_at']),
      countryOrOrigin: json['country_or_origin']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      occupation: json['occupation']?.toString(),
      profession: json['profession']?.toString(),
      registrationStatus: json['registration_status']?.toString(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] == true,
      twoFaEnabled: json['two_fa_enabled'] == true,
      biometricsEnabled: json['biometrics_enabled'] == true,
      scheduledDeletionAt: _parseDate(json['scheduled_deletion_at']),
      bio: json['bio']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  bool get isAdmin => role == 'admin';
  bool get isSuspended => accountStatus == 'deactivated';
  bool get isPendingDeletion => status == 'pending_deletion';
  bool get isActive => !isSuspended && !isPendingDeletion;
  bool get isEnterprise => accountType == 'enterprise';
  bool get isCertified => certificationStatus == 'approved';

  String get displayedName =>
      displayName.trim().isNotEmpty ? displayName : (fullName ?? 'Utilisateur');

  String get contactLabel => thixChat ?? phoneNumber ?? contactPhone ?? '—';

  String get occupationLabel =>
      (occupation?.trim().isNotEmpty ?? false)
          ? occupation!
          : (profession?.trim().isNotEmpty ?? false)
              ? profession!
              : '—';

  String formatDate(DateTime? dt) {
    if (dt == null) return '—';
    try {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }

  AdminUserProfile copyWith({String? accountStatus, String? status}) {
    return AdminUserProfile(
      id: id,
      thixId: thixId,
      thixChat: thixChat,
      displayName: displayName,
      fullName: fullName,
      avatarUrl: avatarUrl,
      role: role,
      accountType: accountType,
      accountStatus: accountStatus ?? this.accountStatus,
      status: status ?? this.status,
      certificationTier: certificationTier,
      certificationStatus: certificationStatus,
      certifiedAt: certifiedAt,
      certificationExpiresAt: certificationExpiresAt,
      countryOrOrigin: countryOrOrigin,
      phoneNumber: phoneNumber,
      contactPhone: contactPhone,
      occupation: occupation,
      profession: profession,
      registrationStatus: registrationStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      isVerified: isVerified,
      twoFaEnabled: twoFaEnabled,
      biometricsEnabled: biometricsEnabled,
      scheduledDeletionAt: scheduledDeletionAt,
      bio: bio,
    );
  }
}

/// 📊 Compteurs du module
@immutable
class UsersStats {
  final int total;
  final int admins;
  final int suspended;
  final int pendingDeletion;

  const UsersStats({
    this.total = 0,
    this.admins = 0,
    this.suspended = 0,
    this.pendingDeletion = 0,
  });
}

/// 🔍 Filtres de liste
@immutable
class UsersFilters {
  final String search;
  final String? role;
  final String? accountType;
  final String? statusGroup;

  const UsersFilters({
    this.search = '',
    this.role,
    this.accountType,
    this.statusGroup,
  });

  bool get isEmpty =>
      search.isEmpty && role == null && accountType == null && statusGroup == null;

  UsersFilters copyWith({
    String? search,
    String? role,
    String? accountType,
    String? statusGroup,
    bool clearRole = false,
    bool clearAccountType = false,
    bool clearStatusGroup = false,
  }) {
    return UsersFilters(
      search: search ?? this.search,
      role: clearRole ? null : (role ?? this.role),
      accountType: clearAccountType ? null : (accountType ?? this.accountType),
      statusGroup: clearStatusGroup ? null : (statusGroup ?? this.statusGroup),
    );
  }
}

/// 🎯 Résultat d'opération
class UserOpResult {
  final bool success;
  final String? error;
  const UserOpResult({required this.success, this.error});
  factory UserOpResult.ok() => const UserOpResult(success: true);
  factory UserOpResult.fail(String e) => UserOpResult(success: false, error: e);
}
