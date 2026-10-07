// lib/features/mon_pays/providers/provinces_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/supabase_config.dart';
import '../models/province.dart';

class ProvincesService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Récupère la liste de toutes les provinces (données de base uniquement)
  Future<List<Province>> getProvinces() async {
    try {
      final response = await _client.from('provinces').select().order('name', ascending: true);
      return (response as List).map((e) => Province.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des provinces: $e');
    }
  }

  /// Récupère une province avec TOUTES ses relations (anciennes et nouvelles)
  Future<Province> getProvinceWithRelations(String id) async {
    try {
      // Récupère la province de base
      final res = await _client.from('provinces').select().eq('id', id).single();
      final provinceJson = Map<String, dynamic>.from(res);

      // Charge toutes les relations en parallèle
      final relations = await Future.wait([
        _loadMinisters(id),
        _loadCities(id),
        _loadEconomicResources(id),
        _loadTourismSites(id),
        _loadEmergencyContacts(id),
        _loadAdministrativeDivisions(id),
        _loadAchievements(id),
        _loadTribes(id),
        _loadGalleryMedia(id),
        _loadNews(id),
        _loadProjects(id),
        _loadServices(id),
        _loadEngagements(id),
        _loadBudget(id),
        _loadDemographics(id),
        _loadDocuments(id),
        _loadMedia(id),
        _loadFamousPeople(id),
        _loadGastronomy(id),
        _loadProverbs(id),
        _loadBusinesses(id),
        _loadProducts(id),
        _loadQuizQuestions(id),
        _loadHymn(id),
      ]);

      // Ajoute les relations au JSON de la province
      provinceJson['ministers'] = relations[0];
      provinceJson['cities'] = relations[1];
      provinceJson['economic_resources'] = relations[2];
      provinceJson['tourism_sites'] = relations[3];
      provinceJson['emergency_contacts'] = relations[4];
      provinceJson['administrative_divisions'] = relations[5];
      provinceJson['achievements'] = relations[6];
      provinceJson['tribes'] = relations[7];
      provinceJson['gallery_media'] = relations[8];
      provinceJson['news'] = relations[9];
      provinceJson['projects'] = relations[10];
      provinceJson['services'] = relations[11];
      provinceJson['engagements'] = relations[12];
      provinceJson['budget'] = relations[13];
      provinceJson['demographics'] = relations[14];
      provinceJson['documents'] = relations[15];
      provinceJson['media'] = relations[16];
      provinceJson['famous_people'] = relations[17];
      provinceJson['gastronomy'] = relations[18];
      provinceJson['proverbs'] = relations[19];
      provinceJson['businesses'] = relations[20];
      provinceJson['products'] = relations[21];
      provinceJson['quiz_questions'] = relations[22];
      provinceJson['hymn'] = relations[23];

      return Province.fromJson(provinceJson);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la province: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES DE CHARGEMENT DES RELATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _loadMinisters(String id) async {
    try {
      final res = await _client.from('province_ministers').select().eq('province_id', id).order('name');
      return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCities(String id) async {
    try {
      final res = await _client.from('cities').select().eq('province_id', id).order('name');
      return (res as List).map((e) => City.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadEconomicResources(String id) async {
    try {
      final res = await _client.from('province_economic_resources').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceEconomicResource.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTourismSites(String id) async {
    try {
      final res = await _client.from('province_tourism_sites').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceTourism.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadEmergencyContacts(String id) async {
    try {
      final res = await _client.from('province_emergency_contacts').select().eq('province_id', id).order('service');
      return (res as List).map((e) => ProvinceEmergencyContact.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdministrativeDivisions(String id) async {
    try {
      final res = await _client.from('province_administrative_divisions').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceAdministrativeDivision.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadAchievements(String id) async {
    try {
      final res = await _client.from('province_achievements').select().eq('province_id', id).order('date', ascending: false);
      return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTribes(String id) async {
    try {
      final res = await _client.from('province_tribes').select().eq('province_id', id).order('name');
      return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadGalleryMedia(String id) async {
    try {
      final res = await _client.from('province_gallery_media').select().eq('province_id', id).order('created_at', ascending: false);
      return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadNews(String id) async {
    try {
      final res = await _client.from('province_news').select().eq('province_id', id).order('published_at', ascending: false);
      return (res as List).map((e) => ProvinceNews.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadProjects(String id) async {
    try {
      final res = await _client.from('province_projects').select().eq('province_id', id).order('created_at');
      return (res as List).map((e) => ProvinceProject.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadServices(String id) async {
    try {
      final res = await _client.from('province_services').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceService.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadEngagements(String id) async {
    try {
      final res = await _client.from('province_engagements').select().eq('province_id', id).order('created_at', ascending: false);
      return (res as List).map((e) => ProvinceEngagement.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBudget(String id) async {
    try {
      final res = await _client.from('province_budget').select().eq('province_id', id).order('percentage', ascending: false);
      return (res as List).map((e) => ProvinceBudget.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadDemographics(String id) async {
    try {
      final res = await _client.from('province_demographics').select().eq('province_id', id).order('year');
      return (res as List).map((e) => ProvinceDemographic.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadDocuments(String id) async {
    try {
      final res = await _client.from('province_documents').select().eq('province_id', id).order('published_at', ascending: false);
      return (res as List).map((e) => ProvinceDocument.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadMedia(String id) async {
    try {
      final res = await _client.from('province_media').select().eq('province_id', id).order('published_at', ascending: false);
      return (res as List).map((e) => ProvinceMedia.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadFamousPeople(String id) async {
    try {
      final res = await _client.from('province_famous_people').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceFamousPerson.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadGastronomy(String id) async {
    try {
      final res = await _client.from('province_gastronomy').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceGastronomy.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadProverbs(String id) async {
    try {
      final res = await _client.from('province_proverbs').select().eq('province_id', id).order('created_at', ascending: false);
      return (res as List).map((e) => ProvinceProverb.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBusinesses(String id) async {
    try {
      final res = await _client.from('province_businesses').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceBusiness.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadProducts(String id) async {
    try {
      final res = await _client.from('province_products').select().eq('province_id', id).order('name');
      return (res as List).map((e) => ProvinceProduct.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuizQuestions(String id) async {
    try {
      final res = await _client.from('province_quiz_questions').select().eq('province_id', id).order('order_index');
      return (res as List).map((e) => ProvinceQuizQuestion.fromJson(e).toJson()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _loadHymn(String id) async {
    try {
      final res = await _client.from('province_hymns').select().eq('province_id', id).limit(1);
      final list = (res as List);
      if (list.isNotEmpty) {
        return ProvinceHymn.fromJson(Map<String, dynamic>.from(list.first)).toJson();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES DE SAUVEGARDE
  // ═══════════════════════════════════════════════════════════════

  /// Sauvegarde une province avec toutes ses relations
  Future<void> saveProvinceWithRelations(Province province) async {
    final data = province.toJson();
    final provinceId = province.id.isEmpty ? null : province.id;

    try {
      String savedProvinceId;
      
      if (provinceId == null) {
        // INSERT de la province
        data.remove('id');
        final res = await _client.from('provinces').insert(data).select();
        savedProvinceId = (res as List).first['id'].toString();
      } else {
        // UPDATE de la province
        await _client.from('provinces').update(data).eq('id', provinceId);
        savedProvinceId = provinceId;
      }

      // Sauvegarde toutes les relations
      await _saveRelations(savedProvinceId, province);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Sauvegarde toutes les relations d'une province
  Future<void> _saveRelations(String provinceId, Province province) async {
    // Ministres
    if (province.ministers.isNotEmpty) {
      final ministersData = province.ministers.map((m) => {...m, 'province_id': provinceId}).toList();
      await _client.from('province_ministers').upsert(ministersData);
    }

    // Villes
    if (province.cities.isNotEmpty) {
      final citiesData = province.cities.map((c) {
        final json = c.toJson();
        json['province_id'] = provinceId;
        return json;
      }).toList();
      await _client.from('cities').upsert(citiesData);
    }

    // Ressources économiques
    if (province.economicResources.isNotEmpty) {
      final data = province.economicResources.map((e) {
        final json = e.toJson();
        json['province_id'] = provinceId;
        return json;
      }).toList();
      await _client.from('province_economic_resources').upsert(data);
    }

    // Sites touristiques
    if (province.tourismSites.isNotEmpty) {
      final data = province.tourismSites.map((t) {
        final json = t.toJson();
        json['province_id'] = provinceId;
        return json;
      }).toList();
      await _client.from('province_tourism_sites').upsert(data);
    }

    // Contacts d'urgence
    if (province.emergencyContacts.isNotEmpty) {
      final data = province.emergencyContacts.map((e) {
        final json = e.toJson();
        json['province_id'] = provinceId;
        return json;
      }).toList();
      await _client.from('province_emergency_contacts').upsert(data);
    }

    // Divisions administratives
    if (province.administrativeDivisions.isNotEmpty) {
      final data = province.administrativeDivisions.map((a) {
        final json = a.toJson();
        json['province_id'] = provinceId;
        return json;
      }).toList();
      await _client.from('province_administrative_divisions').upsert(data);
    }

    // Réalisations
    if (province.achievements.isNotEmpty) {
      final data = province.achievements.map((a) => {...a, 'province_id': provinceId}).toList();
      await _client.from('province_achievements').upsert(data);
    }

    // Tribus
    if (province.tribes.isNotEmpty) {
      final data = province.tribes.map((t) => {...t, 'province_id': provinceId}).toList();
      await _client.from('province_tribes').upsert(data);
    }

    // Galerie média
    if (province.galleryMedia.isNotEmpty) {
      final data = province.galleryMedia.map((m) => {...m, 'province_id': provinceId}).toList();
      await _client.from('province_gallery_media').upsert(data);
    }
  }

  /// Supprime une province et toutes ses relations (cascade)
  Future<void> deleteProvince(String id) async {
    try {
      // Supprime d'abord les relations (si pas de cascade en BDD)
      await _deleteRelations(id);
      
      // Supprime la province
      await _client.from('provinces').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Supprime toutes les relations d'une province
  Future<void> _deleteRelations(String provinceId) async {
    final tables = [
      'province_ministers',
      'cities',
      'province_economic_resources',
      'province_tourism_sites',
      'province_emergency_contacts',
      'province_administrative_divisions',
      'province_achievements',
      'province_tribes',
      'province_gallery_media',
      'province_news',
      'province_projects',
      'province_services',
      'province_engagements',
      'province_budget',
      'province_demographics',
      'province_documents',
      'province_media',
      'province_famous_people',
      'province_gastronomy',
      'province_proverbs',
      'province_businesses',
      'province_products',
      'province_quiz_questions',
      'province_hymns',
    ];

    for (final table in tables) {
      try {
        await _client.from(table).delete().eq('province_id', provinceId);
      } catch (e) {
        // Ignore les erreurs si la table n'existe pas
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

final provincesServiceProvider = Provider<ProvincesService>((ref) => ProvincesService());

/// Provider pour la liste de toutes les provinces (données de base)
final provincesProvider = FutureProvider<List<Province>>((ref) async {
  return await ref.read(provincesServiceProvider).getProvinces();
});

/// Provider pour une province avec TOUTES ses relations
final provinceWithAllRelationsProvider = FutureProvider.family<Province, String>((ref, id) async {
  return await ref.read(provincesServiceProvider).getProvinceWithRelations(id);
});

/// Provider pour la liste des provinces en mode admin
final adminProvincesProvider = FutureProvider<List<Province>>((ref) async {
  return await ref.read(provincesServiceProvider).getProvinces();
});
