// lib/features/mon_pays/providers/provinces_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/supabase_config.dart';
import '../models/province.dart';

class ProvincesService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Province>> getProvinces() async {
    final response = await _client.from('provinces').select().order('name', ascending: true);
    return (response as List).map((e) => Province.fromJson(e)).toList();
  }

  Future<Province> getProvinceWithRelations(String id) async {
    // Récupère la province de base
    final res = await _client.from('provinces').select().eq('id', id).single();
    final province = Province.fromJson(res);

    // Récupère les relations (à adapter selon ta structure Supabase réelle)
    // Exemple simplifié : si les relations sont dans des tables séparées
    final citiesRes = await _client.from('cities').select().eq('province_id', id);
    province.cities.addAll(citiesRes.map((e) => City.fromJson(e)));

    // ... faire de même pour economic_resources, tourism_sites, etc. si nécessaire
    // Pour l'instant, on retourne la province avec les données de base + villes

    return province;
    // NOTE: Si ta BDD utilise des jointures Supabase (ex: select('*, cities(*)')),
    // adapte cette méthode pour utiliser une seule requête.
  }

  Future<void> saveProvinceWithRelations(Province province) async {
    final data = province.toJson();
    final provinceId = province.id.isEmpty ? null : province.id;

    if (provinceId == null) {
      // INSERT
      final res = await _client.from('provinces').insert(data).select();
      final newId = (res as List).first['id'];
      await _saveRelations(newId, province);
    } else {
      // UPDATE
      await _client.from('provinces').update(data).eq('id', provinceId);
      // Pour les relations, une stratégie simple est de supprimer et recréer,
      // ou de faire des upserts. Ici, on suppose que l'app gère les IDs.
      await _saveRelations(provinceId, province);
    }
  }

  Future<void> _saveRelations(String provinceId, Province province) async {
    // Exemple pour les villes
    if (province.cities.isNotEmpty) {
      await _client.from('cities').upsert(
        province.cities.map((c) => {...c.toJson(), 'province_id': provinceId}).toList(),
      );
    }
    // Répéter pour economic_resources, tourism_sites, emergency_contacts, administrative_divisions
  }

  Future<void> deleteProvince(String id) async {
    await _client.from('provinces').delete().eq('id', id);
  }
}

final provincesServiceProvider = Provider<ProvincesService>((ref) => ProvincesService());

final provincesProvider = FutureProvider<List<Province>>((ref) async {
  return await ref.read(provincesServiceProvider).getProvinces();
});

final provinceWithAllRelationsProvider = FutureProvider.family<Province, String>((ref, id) async {
  return await ref.read(provincesServiceProvider).getProvinceWithRelations(id);
});

final adminProvincesProvider = FutureProvider<List<Province>>((ref) async {
  return await ref.read(provincesServiceProvider).getProvinces();
});
