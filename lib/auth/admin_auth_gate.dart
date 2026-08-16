import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_admin/auth/admin_login_page.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/shell/admin_shell_page.dart';

/// Point d'entrée unique de vérification du rôle admin.
/// Aucune autre page de ce dépôt ne doit refaire ce check —
/// tout passe par ce widget avant d'atteindre AdminShellPage.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

enum _GateStatus { checking, notLoggedIn, notAdmin, ok }

class _AdminAuthGateState extends State<AdminAuthGate> {
  _GateStatus _status = _GateStatus.checking;

  @override
  void initState() {
    super.initState();
    _check();
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => _check());
  }

  Future<void> _check() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _status = _GateStatus.notLoggedIn);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final isAdmin = row?['role']?.toString() == 'admin';
      if (mounted) {
        setState(() => _status = isAdmin ? _GateStatus.ok : _GateStatus.notAdmin);
      }
    } catch (_) {
      if (mounted) setState(() => _status = _GateStatus.notAdmin);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _GateStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      case _GateStatus.notLoggedIn:
        return AdminLoginPage(onLoggedIn: _check);
      case _GateStatus.notAdmin:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block_rounded, size: 56, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text(
                  'Accès réservé aux administrateurs THIX.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) setState(() => _status = _GateStatus.notLoggedIn);
                  },
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        );
      case _GateStatus.ok:
        return const AdminShellPage();
    }
  }
}
