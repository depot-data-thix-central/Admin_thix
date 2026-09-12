import 'package:flutter/foundation.dart';

/// 🛡️ Signalement normalisé (quelle que soit la table source)
@immutable
class ModerationItem {
  final String id;
  final String sourceTable;
  final String contentType; // post | comment
  final String? contentId;
  final String? reporterId;
  final String reason;
  final String details;
  final String sourceStatus;
  final String? caseAction; // décision admin (null = non traité)
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  const ModerationItem({
    required this.id,
    required this.sourceTable,
    required this.contentType,
    this.contentId,
    this.reporterId,
    required this.reason,
    required this.details,
    required this.sourceStatus,
    this.caseAction,
    required this.createdAt,
    this.raw = const {},
  });

  bool get isHandled => caseAction != null;

  String get reasonLabel {
    switch (reason.toLowerCase()) {
      case 'spam':
        return 'Spam';
      case 'harassment':
      case 'harcelement':
        return 'Harcèlement';
      case 'hate':
      case 'hate_speech':
        return 'Discours haineux';
      case 'violence':
        return 'Violence';
      case 'nudity':
      case 'sexual':
        return 'Contenu sexuel';
      case 'misinformation':
      case 'fake':
        return 'Désinformation';
      case 'scam':
      case 'fraud':
        return 'Arnaque';
      default:
        return reason.isEmpty ? 'Non précisé' : reason;
    }
  }

  String get actionLabel {
    switch (caseAction) {
      case 'dismissed':
        return 'Signalement rejeté';
      case 'content_removed':
        return 'Contenu supprimé';
      case 'author_suspended':
        return 'Auteur suspendu';
      case 'approved_content':
        return 'Contenu validé';
      default:
        return 'En attente';
    }
  }

  String get relativeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
