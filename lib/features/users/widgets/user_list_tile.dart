import 'package:flutter/material.dart';

import '../models/admin_user_profile.dart';
import 'user_status_badge.dart';

/// 📋 Ligne de liste utilisateur
class UserListTile extends StatelessWidget {
  final AdminUserProfile user;
  final VoidCallback onTap;

  const UserListTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // ── Avatar ──
              _avatar(),
              const SizedBox(width: 12),

              // ── Infos ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayedName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101840),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.thixId} • ${user.countryOrOrigin ?? '—'}',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    UserStatusBadge(user: user),
                  ],
                ),
              ),

              // ── Chevron ──
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: const Color(0xFFF3F4F6),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFF3F4F6),
      child: Text(
        user.displayedName.isNotEmpty
            ? user.displayedName[0].toUpperCase()
            : '?',
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: Color(0xFF101840)),
      ),
    );
  }
}
