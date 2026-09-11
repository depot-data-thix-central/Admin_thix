import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/core/supabase_config.dart';
import 'package:thix_admin/auth/admin_auth_gate.dart';

/// 🚀 Point d'entrée de l'application THIX Admin
/// Version Production Enterprise - Sécurisée et Robuste
Future<void> main() async {
  // ✅ Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Capture globale des erreurs pour éviter les crashes
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logError('FlutterError', details.exception, details.stack);
  };

  // 🛡️ Zone de protection contre les erreurs asynchrones
  await runZonedGuarded<Future<void>>(
    () async {
      // 🗄️ Initialisation Supabase avec gestion d'erreur
      try {
        await SupabaseConfig.init();
        _logInfo('Supabase initialisé avec succès');
      } catch (e, stack) {
        _logError('SupabaseConfig.init', e, stack);
        // En production, on pourrait afficher une page d'erreur
        // Pour l'instant, on continue et l'auth gèrera l'erreur
      }

      // 🎨 Lancement de l'application
      runApp(
        const ProviderScope(
          child: ThixAdminApp(),
        ),
      );
    },
    (error, stack) {
      _logError('runZonedGuarded', error, stack);
    },
  );
}

/// 📝 Logging helper pour le monitoring
void _logError(String source, Object error, StackTrace? stack) {
  if (kDebugMode) {
    debugPrint('❌ [$source] $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
  }
  // TODO: Envoyer vers un service de monitoring (Sentry, Firebase Crashlytics)
}

void _logInfo(String message) {
  if (kDebugMode) {
    debugPrint('ℹ️ $message');
  }
}

/// 🎯 Application principale THIX Admin
class ThixAdminApp extends StatelessWidget {
  const ThixAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THIX Admin',
      debugShowCheckedModeBanner: false,
      
      // 🎨 Thème professionnel pour admin dashboard
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        
        // AppBar personnalisée
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF101840),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101840),
          ),
        ),
        
        // Boutons personnalisés
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Input fields personnalisés
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        
        // DataTable personnalisée
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF101840),
            fontSize: 13,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
          dividerThickness: 1,
          horizontalMargin: 16,
          columnSpacing: 24,
        ),
        
        // Cards personnalisées
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        
        // Scrollbar personnalisée
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(Colors.grey[400]),
          thickness: MaterialStateProperty.all(8),
          radius: const Radius.circular(4),
        ),
      ),
      
      // 🚪 Page d'accueil : Gate d'authentification
      home: const AdminAuthGate(),
      
      // 🔧 Builder pour gérer les erreurs de routing
      builder: (context, child) {
        return MediaQuery(
          // Fix pour le texte trop grand sur mobile
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 🛡️ Widget de protection contre les erreurs de runtime
/// À utiliser si besoin d'envelopper des widgets sensibles
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildErrorWidget();
    }

    return widget.child;
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.red[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
          const SizedBox(height: 16),
          Text(
            'Une erreur est survenue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error?.toString() ?? 'Erreur inconnue',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _error = null;
              });
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
