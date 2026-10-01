// lib/features/mon_pays/providers/citizens_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/supabase_config.dart';

class ExemplaryCitizen {
  final String id;
  final String fullName;
  final String domain;
  final String? photoUrl;
  final String? biography;
  final bool isActive;

  ExemplaryCitizen({
    required this.id,
    required this.fullName,
    required this.domain,
    this.photoUrl,
    this.biography,
    this.isActive = true,
  });

  factory ExemplaryCitizen.fromJson(Map<String, dynamic> json) {
    return ExemplaryCitizen(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      domain: json['domain'] ?? '',
      photoUrl: json['photo_url'],
      biography: json['biography'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'domain': domain,
      'photo_url': photoUrl,
      'biography': biography,
      'is_active': isActive,
    };
  }
}

class CitizensService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<ExemplaryCitizen>> getCitizens() async {
    final response = await _client
        .from('exemplary_citizens')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((e) => ExemplaryCitizen.fromJson(e))
        .toList();
  }

  Future<void> saveCitizen(ExemplaryCitizen citizen) async {
    final data = citizen.toJson();
    if (citizen.id.isEmpty) {
      await _client.from('exemplary_citizens').insert(data);
    } else {
      await _client.from('exemplary_citizens').update(data).eq('id', citizen.id);
    }
  }

  Future<void> deleteCitizen(String id) async {
    await _client.from('exemplary_citizens').delete().eq('id', id);
  }
}

final citizensServiceProvider = Provider<CitizensService>((ref) => CitizensService());

final citizensProvider = FutureProvider<List<ExemplaryCitizen>>((ref) async {
  return await ref.read(citizensServiceProvider).getCitizens();
});
