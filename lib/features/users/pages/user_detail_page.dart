import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import 'package:thix_admin/features/users/models/admin_user_profile.dart';
import '../providers/users_provider.dart';
import '../widgets/user_status_badge.dart';

/// 👁️ Fiche détaillée d'un utilisateur (lecture seule + actions de sécurité)
class UserDetailPage extends ConsumerStatefulWidget {
  final AdminUserProfile user;

  const UserDetailPage({super.key, required this.user});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  late AdminUserProfile _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _suspend() async {
    final ok = await _confirm(
      title: 'Suspendre ce compte ?',
      message:
          '${_user.displayedName} (${_user.thixId}) sera immédiatement désactivé. L\'utilisateur ne pourra plus se connecter.',
      confirmLabel: 'Suspendre',
      danger: true,
    );
    if (ok != true) return;

    final res = await ref.read(usersProvider.notifier).suspendUser(_user.id);
    if (!mounted) return;
    if (res.success) {
      setState(() => _user = _user.copyWith(accountStatus: 'deactivated'));
      _snack('✅ Compte suspendu', AppColors.success);
      Navigator.of(context).pop(true);
    } else {
      _snack('❌ ${res.error}', AppColors.danger);
    }
  }

  Future<void> _reactivate() async {
    final ok = await _confirm(
      title: 'Réactiver ce compte ?',
      message: '${_user.displayedName} retrouvera un accès normal à la plateforme.',
      confirmLabel: 'Réactiver',
      danger: false,
    );
    if (ok != true) return;

    final res = await ref.read(usersProvider.notifier).reactivateUser(_user.id);
    if (!mounted) return;
    if (res.success) {
      setState(() => _user = _user.copyWith(accountStatus: 'active'));
      _snack('✅ Compte réactivé', AppColors.success);
      Navigator.of(context).pop(true);
    } else {
      _snack('❌ ${res.error}', AppColors.danger);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool danger,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final operating = ref.watch(usersProvider).isOperating;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text('Fiche utilisateur'),
        actions: [
          if (_user.isPendingDeletion)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        size: 14, color: AppColors.danger),
                    SizedBox(width: 4),
                    Text('Suppression programmée',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── En-tête profil ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.displayedName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user.thixId,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      UserStatusBadge(user: _user),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Action de sécurité ──
          SizedBox(
            height: 48,
            child: _user.isSuspended
                ? ElevatedButton.icon(
                    onPressed: operating ? null : _reactivate,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Réactiver le compte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed:
                        (operating || _user.isPendingDeletion) ? null : _suspend,
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Suspendre le compte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
          if (_user.isPendingDeletion) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Compte en cours de suppression programmée (${_user.formatDate(_user.scheduledDeletionAt)}). Suspendre reste possible, réactiver est bloqué.',
              style: TextStyle(fontSize: 11.5, color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 20),

          // ── Sections ──
          _section('Identité', [
            _row('Nom complet', _user.fullName ?? '—'),
            _row('Pays / origine', _user.countryOrOrigin ?? '—'),
            _row('Profession', _user.occupationLabel),
            _row('Type de compte', _user.isEnterprise ? 'Entreprise' : 'Particulier'),
            _row('Inscription', _user.formatDate(_user.createdAt)),
          ]),
          _section('Contact (visible admin)', [
            _row('THIX Chat', _user.thixChat ?? '—'),
            _row('Téléphone', _user.phoneNumber ?? _user.contactPhone ?? '—'),
          ]),
          _section('Certification', [
            _row('Niveau', _user.certificationTier),
            _row('Statut', _user.certificationStatus),
            _row('Certifié le', _user.formatDate(_user.certifiedAt)),
            _row('Expire le', _user.formatDate(_user.certificationExpiresAt)),
          ]),
          _section('Activité', [
            _row('Abonnés', '${_user.followersCount}'),
            _row('Abonnements', '${_user.followingCount}'),
            _row('Posts', '${_user.postsCount}'),
          ]),
          _section('Sécurité', [
            _row('2FA activée', _user.twoFaEnabled ? '✅ Oui' : '❌ Non'),
            _row('Biométrie', _user.biometricsEnabled ? '✅ Oui' : '❌ Non'),
            _row('Statut compte', _user.accountStatus),
            _row('Statut cycle', _user.status),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '🔒 Monitoring uniquement — aucune donnée financière accessible',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    if (_user.avatarUrl != null && _user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(_user.avatarUrl!),
        backgroundColor: const Color(0xFFF3F4F6),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFF3F4F6),
      child: Text(
        _user.displayedName.isNotEmpty
            ? _user.displayedName[0].toUpperCase()
            : '?',
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const Divider(height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}
