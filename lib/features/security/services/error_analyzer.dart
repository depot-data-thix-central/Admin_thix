import 'package:flutter/material.dart';

/// 🧠 Catégories d'erreurs détectables automatiquement
enum ErrorCategory { image, http, typeSystem, nullSafety, database, network, unknown }

/// 🔬 Résultat d'analyse d'une erreur
class ErrorInsight {
  final ErrorCategory category;
  final String zone; // 📍 localisation probable dans l'app
  final String? failingUrl; // URL en cause si détectée
  final String explanation; // pourquoi cette classification
  final List<String> recommendations; // 🧭 actions correctives
  final double confidence; // 0..1

  const ErrorInsight({
    required this.category,
    required this.zone,
    this.failingUrl,
    required this.explanation,
    required this.recommendations,
    this.confidence = 0.9,
  });
}

/// 🔬 Analyseur statique des erreurs applicatives
class ErrorAnalyzer {
  ErrorAnalyzer._();

  static final RegExp _urlRe = RegExp(r'https?://[^\s,)"\]]+');

  static ErrorInsight analyze(String message) {
    final url = _urlRe.firstMatch(message)?.group(0);
    final m = message.toLowerCase();

    // ─── 1. IMAGES RÉSEAU ───
    if (m.contains('imagecodecexception') ||
        m.contains('failed to load network image')) {
      return ErrorInsight(
        category: ErrorCategory.image,
        zone: 'Composants Image.network (avatars, couvertures, illustrations '
            'd\'articles, cartes)',
        failingUrl: url,
        explanation: 'Flutter n\'a pas pu décoder/télécharger une image '
            'distante. L\'URL est invalide, expirée ou le format n\'est pas supporté.',
        recommendations: [
          'Ajouter errorBuilder + loadingBuilder sur tous les Image.network '
              '(fallback visuel au lieu du crash)',
          'Valider l\'URL avant affichage (https, extension connue) ou passer '
              'par cached_network_image',
          if (url != null) 'Vérifier manuellement l\'URL : $url',
          'Héberger les images critiques sur Supabase Storage (bucket public) '
              'plutôt que des CDN externes',
        ],
      );
    }

    // ─── 2. ERREUR HTTP EXTERNE ───
    if (m.contains('http request failed') ||
        m.contains('statuscode: 4') ||
        m.contains('statuscode: 5')) {
      final host = url != null ? Uri.tryParse(url)?.host ?? url : 'inconnu';
      return ErrorInsight(
        category: ErrorCategory.http,
        zone: 'Appel réseau externe vers $host (contenu embarqué : cartes, '
            'médias, SVG)',
        failingUrl: url,
        explanation: 'Un serveur externe a répondu 4xx/5xx. Souvent une URL '
            'construite dynamiquement (SVG wikimedia, miniature) qui n\'existe plus.',
        recommendations: [
          'Vérifier le statut HTTP avant d\'utiliser la réponse (if res.statusCode == 200)',
          'Ajouter retry avec backoff (1 essai → 3 s → 2e essai) puis fallback',
          if (url != null) 'Tester l\'URL directement : $url',
          'Mettre en cache les contenus externes valides pour éviter les rappels',
        ],
      );
    }

    // ─── 3. ERREUR DE TYPE (code minifié) ───
    if (m.contains('is not a subtype of') || m.contains('minified:')) {
      return ErrorInsight(
        category: ErrorCategory.typeSystem,
        zone: 'Code Dart compilé en production (build minifié) — cast ou '
            'conversion de type invalide (as, List.from, Map.cast)',
        explanation: 'Erreur de typage à l\'exécution. En build minifié les noms '
            'de classes sont illisibles : impossible de localiser sans symboles de debug.',
        recommendations: [
          'Compiler avec --split-debug-info=/debug-info --obfuscate pour pouvoir '
              're-mapper les stack traces',
          'Reproduire en mode profile (non minifié) pour obtenir la ligne exacte',
          'Auditer les casts explicites (as / List.from / .cast<>) sur les JSON '
              'Supabase : utiliser Map<String, dynamic>.from() systématiquement',
          'Ajouter des validations de schéma à la lecture des données',
        ],
        confidence: 0.85,
      );
    }

    // ─── 4. NULL SAFETY ───
    if (m.contains('null check operator') || m.contains('used on a null value')) {
      return ErrorInsight(
        category: ErrorCategory.nullSafety,
        zone: 'Opérateur `!` appliqué sur une valeur nulle (logique métier, '
            'contrôleur, réponse de requête)',
        explanation: 'Un `variable!` a été utilisé alors que la valeur était nulle '
            '(donnée manquante en base, champ optionnel non géré).',
        recommendations: [
          'Remplacer les `!` par des guards : if (x == null) return / ?? valeurParDefaut',
          'Vérifier les champs optionnels du schéma Supabase utilisés sans null-check',
          'Activer les asserts en debug pour détecter plus tôt',
          'Journaliser le contexte (table + id) avant l\'accès fautif',
        ],
      );
    }

    // ─── 5. BASE DE DONNÉES ───
    if (m.contains('postgrestexception') ||
        m.contains('relation') ||
        m.contains('column') ||
        m.contains('row level security')) {
      return ErrorInsight(
        category: ErrorCategory.database,
        zone: 'Supabase : requête SQL / politiques RLS / schéma de table',
        explanation: 'Erreur côté base de données : colonne/table inexistante ou '
            'politique RLS bloquante.',
        recommendations: [
          'Vérifier l\'orthographe des tables/colonnes dans le SQL Editor',
          'Tester la politique RLS concernée avec le rôle authenticated',
          'Contrôler les migrations récentes (colonne renommée/supprimée)',
        ],
      );
    }

    // ─── 6. RÉSEAU UTILISATEUR ───
    if (m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('timeout') ||
        m.contains('connection refused')) {
      return ErrorInsight(
        category: ErrorCategory.network,
        zone: 'Connectivité de l\'utilisateur (réseau faible, offline, DNS)',
        explanation: 'L\'appareil de l\'utilisateur n\'a pas pu joindre le serveur. '
            'Fréquent en RDC (couverture variable).',
        recommendations: [
          'Ajouter gestion offline : file d\'attente + resynchronisation',
          'Messages utilisateur clairs au lieu d\'exceptions brutes',
          'Augmenter les timeouts et ajouter retry automatique',
        ],
      );
    }

    // ─── 7. INCONNU ───
    return ErrorInsight(
      category: ErrorCategory.unknown,
      zone: 'Non déterminée — analyse manuelle requise',
      explanation: 'Signature d\'erreur non reconnue par l\'analyseur.',
      recommendations: [
        'Reproduire l\'erreur en mode debug/profile',
        'Activer --split-debug-info pour les builds production',
        'Ajouter des breadcrumbs (étapes utilisateur) au reporter',
      ],
      confidence: 0.4,
    );
  }

  // ─── LIBELLÉS & STYLE ───
  static String label(ErrorCategory c) {
    switch (c) {
      case ErrorCategory.image:
        return 'Image réseau';
      case ErrorCategory.http:
        return 'HTTP externe';
      case ErrorCategory.typeSystem:
        return 'Erreur de type';
      case ErrorCategory.nullSafety:
        return 'Null safety';
      case ErrorCategory.database:
        return 'Base de données';
      case ErrorCategory.network:
        return 'Réseau utilisateur';
      case ErrorCategory.unknown:
        return 'Inconnue';
    }
  }

  static IconData icon(ErrorCategory c) {
    switch (c) {
      case ErrorCategory.image:
        return Icons.broken_image_outlined;
      case ErrorCategory.http:
        return Icons.http_outlined;
      case ErrorCategory.typeSystem:
        return Icons.swap_horiz_rounded;
      case ErrorCategory.nullSafety:
        return Icons.dangerous_outlined;
      case ErrorCategory.database:
        return Icons.database_outlined;
      case ErrorCategory.network:
        return Icons.wifi_off_rounded;
      case ErrorCategory.unknown:
        return Icons.help_outline_rounded;
    }
  }

  static Color color(ErrorCategory c) {
    switch (c) {
      case ErrorCategory.image:
        return const Color(0xFF8B5CF6);
      case ErrorCategory.http:
        return const Color(0xFFF97316);
      case ErrorCategory.typeSystem:
        return const Color(0xFFEF4444);
      case ErrorCategory.nullSafety:
        return const Color(0xFFB91C1C);
      case ErrorCategory.database:
        return const Color(0xFF3B82F6);
      case ErrorCategory.network:
        return const Color(0xFF06B6D4);
      case ErrorCategory.unknown:
        return const Color(0xFF6B7280);
    }
  }
}
