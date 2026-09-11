import 'package:flutter/material.dart';

/// 🎨 Design system THIX Admin - Palette de couleurs
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════
  // 🎯 COULEURS PRINCIPALES
  // ═══════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF101840);      // Bleu nuit
  static const Color secondary = Color(0xFFFFB800);    // Doré
  static const Color accent = Color(0xFF2E7DFF);       // Bleu vif

  // ═══════════════════════════════════════════════════════════
  // 🎨 BASE (BLANC / NOIR)
  // ═══════════════════════════════════════════════════════════
  static const Color white = Colors.white;             // ⬅️ AJOUTÉ
  static const Color black = Colors.black;             // ⬅️ AJOUTÉ

  // ═══════════════════════════════════════════════════════════
  // 🖼️ FOND & SURFACES
  // ═══════════════════════════════════════════════════════════
  static const Color bg = Color(0xFFF7F8FB);
  static const Color surface = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════
  // 🏢 ENTERPRISE (SIDEBAR)
  // ═══════════════════════════════════════════════════════════
  static const Color enterprise = Color(0xFF101840);

  // ═══════════════════════════════════════════════════════════
  // 📣 FEEDBACK (SUCCESS / DANGER / WARNING / INFO)
  // ═══════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════
  // 📝 TEXTE
  // ═══════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMain = Color(0xFF111827);     // ⬅️ AJOUTÉ (alias)
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFFFFFFFF);    // ⬅️ AJOUTÉ

  // ═══════════════════════════════════════════════════════════
  // 🔲 BORDURES & DIVIDERS
  // ═══════════════════════════════════════════════════════════
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════════════════════
  // 🏅 CERTIFICATIONS
  // ═══════════════════════════════════════════════════════════
  static const Color certGold = Color(0xFFFFD700);
  static const Color certSilver = Color(0xFFC0C0C0);
  static const Color certBronze = Color(0xFFCD7F32);
  static const Color certPending = Color(0xFF9CA3AF);

  // ═══════════════════════════════════════════════════════════
  // 🎨 UTILES (alias pour compatibilité)
  // ═══════════════════════════════════════════════════════════
  static const Color gold = secondary;
  static const Color dark = primary;
}
