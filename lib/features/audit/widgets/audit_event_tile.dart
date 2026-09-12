import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../models/audit_event.dart';

/// 📋 Tuile d'événement d'audit (tap = détails)
class AuditEventTile extends StatelessWidget {
  final AuditEvent event;
  final VoidCallback onTap;

  const AuditEventTile({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AuditCategory.color(event.category);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AuditCategory.icon(event.category),
                    size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${event.userLabel} • ${event.action}',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          event.relativeLabel,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.summary,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (event.thixId != null) event.thixId!,
                        AuditCategory.label(event.category),
                        if (event.device != null) event.device!,
                        if (event.ipAddress != null) 'IP ${event.ipAddress}',
                      ].join(' • '),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔍 Dialogue des détails techniques
void showAuditDetails(BuildContext context, AuditEvent e) {
  final color = AuditCategory.color(e.category);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(AuditCategory.icon(e.category), size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(e.action, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _kv('Utilisateur', e.userLabel),
            _kv('THIX ID', e.thixId ?? '—'),
            _kv('Catégorie', AuditCategory.label(e.category)),
            _kv('Résumé', e.summary),
            _kv('Date', e.dateTimeLabel),
            _kv('IP', e.ipAddress ?? '—'),
            _kv('Appareil', e.device ?? '—'),
            _kv('Version app', e.appVersion ?? '—'),
            _kv('Source', e.source),
            if (e.details.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Détails techniques',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 6),
              for (final entry in e.details.entries)
                _kv(entry.key, '${entry.value}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: SelectableText(
            v,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );
}
