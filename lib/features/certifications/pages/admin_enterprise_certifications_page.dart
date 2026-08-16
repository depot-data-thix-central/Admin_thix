import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_admin/core/app_colors.dart';
import 'package:thix_admin/features/certifications/models/pending_enterprise_certification.dart';
import 'package:thix_admin/features/certifications/services/admin_certification_service.dart';

class AdminEnterpriseCertificationsPage extends StatefulWidget {
  const AdminEnterpriseCertificationsPage({super.key});

  @override
  State<AdminEnterpriseCertificationsPage> createState() => _AdminEnterpriseCertificationsPageState();
}

class _AdminEnterpriseCertificationsPageState extends State<AdminEnterpriseCertificationsPage> {
  late final AdminCertificationService _service;
  List<PendingEnterpriseCertification>? _items;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _service = AdminCertificationService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() { _error = null; });
    try {
      final items = await _service.getPendingEnterprise();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _approve(PendingEnterpriseCertification item) async {
    final notes = await _promptNotes(title: 'Approuver ${item.displayName ?? item.thixId ?? item.userId}');
    if (notes == null) return;
    setState(() => _busy.add(item.userId));
    try {
      await _service.approve(item.userId, notes: notes);
      await _load();
      _toast('Compte Entreprise activé');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(item.userId));
    }
  }

  Future<void> _reject(PendingEnterpriseCertification item) async {
    final notes = await _promptNotes(title: 'Rejeter ${item.displayName ?? item.thixId ?? item.userId}', required: true);
    if (notes == null) return;
    setState(() => _busy.add(item.userId));
    try {
      await _service.reject(item.userId, notes: notes);
      await _load();
      _toast('Demande rejetée');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(item.userId));
    }
  }

  Future<String?> _promptNotes({required String title, bool required = false}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Note (optionnel)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (required && text.isEmpty) return;
              Navigator.pop(ctx, text.isEmpty ? null : text);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.danger : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Certifications Entreprise — à valider'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Erreur: $_error'))
          : _items == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _items!.isEmpty
                  ? const Center(child: Text('Aucune demande en attente.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _items!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = _items![i];
                        final busy = _busy.contains(item.userId);
                        final paidStr = item.paidAt != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(item.paidAt!.toLocal())
                            : '—';
                        return Container(
                          constraints: const BoxConstraints(maxWidth: 640),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.displayName ?? item.thixId ?? item.userId,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('${item.amountUsd.toStringAsFixed(0)} USD · Payé le $paidStr',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    if (item.reason != null && item.reason!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Motif : ${item.reason}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: busy ? null : () => _reject(item),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                child: const Text('Rejeter'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: busy ? null : () => _approve(item),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.enterprise, foregroundColor: Colors.white),
                                child: busy
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Approuver'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
