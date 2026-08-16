import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_admin/features/certifications/models/pending_enterprise_certification.dart';

class AdminCertificationService {
  final SupabaseClient _client;
  AdminCertificationService(this._client);

  Future<List<PendingEnterpriseCertification>> getPendingEnterprise() async {
    final rows = await _client.from('pending_enterprise_certifications').select();
    return (rows as List)
        .map((r) => PendingEnterpriseCertification.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> approve(String userId, {String? notes}) async {
    try {
      await _client.rpc('rpc_admin_approve_enterprise_certification', params: {
        'p_user_id': userId,
        'p_notes': notes,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> reject(String userId, {String? notes}) async {
    try {
      await _client.rpc('rpc_admin_reject_enterprise_certification', params: {
        'p_user_id': userId,
        'p_notes': notes,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
