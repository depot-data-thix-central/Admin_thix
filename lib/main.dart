import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:thix_admin/auth/admin_auth_gate.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/supabase/supabase_config.dart';

/// 🚀 Point d'entrée de l'application THIX Admin
/// Version Production Enterprise - Sécurisée et Robuste
Future<void> main() async {
  // ✅ Initialisation Flutter obligatoire avant tout appel async
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Verrouillage de l'orientation pour un dashboard web (paysage privilégié)
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // 🎨 Style de la barre système (couleurs sobres)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 🔒 Capture globale des erreurs synchrones Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('FlutterError', details.exception, details.stack);
  };

  // 🛡️ Zone de protection contre les erreurs asynchrones non capturées
  await runZonedGuarded<Future<void>>(
    () async {
      // 🗄️ Initialisation Supabase avec gestion d'erreur
      try {
        await SupabaseConfig.initialize();
        _logInfo('✅ Supabase initialisé avec succès');
      } catch (e, stack) {
        _logError('SupabaseConfig.initialize', e, stack);
        // On continue : l'AdminAuthGate gèrera l'erreur côté UI
      }

      // 🌐 CORRECTION : initialisation des locales intl
      // Indispensable pour DateFormat('...', 'fr_FR') sinon crash runtime
      try {
        await initializeDateFormatting('fr_FR', null);
        _logInfo('✅ Locales intl (fr_FR) initialisées');
      } catch (e, stack) {
        _logError('initializeDateFormatting', e, stack);
      }

      // 🎨 Lancement de l'application sous ProviderScope (Riverpod)
      runApp(
        const ProviderScope(
          observers: [_LoggerObserver()],
          child: ThixAdminApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      _logError('runZonedGuarded', error, stack);
    },
  );
}

// ═══════════════════════════════════════════════════════════════
// 📝 LOGGING HELPERS
// ═══════════════════════════════════════════════════════════════

/// Log une erreur avec source + stack trace
void _logError(String source, Object error, StackTrace? stack) {
  if (!kDebugMode) return;
  debugPrint('❌ [$source] $error');
  if (stack != null) {
    debugPrint(stack.toString());
  }
  // TODO: Envoyer vers Sentry en production
  // Sentry.captureException(error, stackTrace: stack);
}

/// Log une info (debug seulement)
void _logInfo(String message) {
  if (!kDebugMode) return;
  debugPrint('ℹ️ $message');
}

// ═══════════════════════════════════════════════════════════════
// 👁️ OBSERVER RIVERPOD (DEBUG)
// ═══════════════════════════════════════════════════════════════

class _LoggerObserver extends ProviderObserver {
  const _LoggerObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    // Décommenter pour debugger les providers
    // debugPrint('[Provider] ${provider.name ?? provider.runtimeType} => $newValue');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    _logError('Provider ${provider.name ?? provider.runtimeType}', error, stackTrace);
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎯 APPLICATION PRINCIPALE
// ═══════════════════════════════════════════════════════════════

class ThixAdminApp extends StatelessWidget {
  const ThixAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THIX Admin',
      debugShowCheckedModeBanner: false,

      // 🎨 Thème principal clair (dashboard professionnel)
      theme: _buildLightTheme(),

      // 🎨 Thème sombre (optionnel, pour le confort visuel)
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light, // Admin dashboard toujours en clair

      // 🌐 Localisation (pour intl, formats de date)
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],

      // 🚪 Page d'accueil : Gate d'authentification
      home: const AdminAuthGate(),

      // 🔧 Builder global pour corriger le scaling texte
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          // 🔒 On plafonne le textScaler pour éviter les textes géants
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ☀️ THÈME CLAIR (Production)
  // ═══════════════════════════════════════════════════════════════
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF101840),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF101840),
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Color(0xFF101840)),
      ),

      // ── Boutons principaux ──
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
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Boutons secondaires ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
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

      // ── Boutons textes ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Champs de saisie ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),

      // ── DataTable (listes d'utilisateurs, articles, etc.) ──
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
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

      // ── Cards (✅ sans const : BorderRadius.circular n'est pas const) ──
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),

      // ── Dialogs (✅ sans const : BorderRadius.circular n'est pas const) ──
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF101840),
        ),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ── Chip (tags, filtres) ──
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),

      // ── Progress indicators ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE5E7EB),
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.grey.shade400),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF101840),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🌙 THÈME SOMBRE (Optionnel)
  // ═══════════════════════════════════════════════════════════════
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🛡️ ERROR BOUNDARY (Widget de protection runtime)
// ═══════════════════════════════════════════════════════════════

/// Enveloppe un widget sensible et affiche un fallback en cas d'erreur.
///
/// Exemple d'utilisation :
/// ```dart
/// ErrorBoundary(
///   child: ModuleArticlesPage(),
///   fallback: Center(child: Text('Erreur de chargement')),
/// )
/// ```
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
      return widget.fallback ?? _buildErrorFallback();
    }

    return widget.child;
  }

  Widget _buildErrorFallback() {
    return Container(
      padding: const EdgeInsets.all(32),
      color: const Color(0xFFFEF2F2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              SelectableText(
                _error.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
