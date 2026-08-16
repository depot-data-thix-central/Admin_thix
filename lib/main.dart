import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/core/supabase_config.dart';
import 'package:thix_admin/auth/admin_auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: ThixAdminApp()));
}

class ThixAdminApp extends StatelessWidget {
  const ThixAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THIX Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
      ),
      home: const AdminAuthGate(),
    );
  }
}
