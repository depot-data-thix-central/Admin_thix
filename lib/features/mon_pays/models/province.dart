// lib/features/mon_pays/models/province.dart

class Province {
  final String id;
  final String name;
  final String code;
  final String capital;
  final String region;
  final int? area;
  final int? population;
  final String? description;
  final String? history;
  final String? climate;
  final String? infrastructure;
  final String? education;
  final String? coverImageUrl;
  final String? coatOfArmsUrl;
  final String? mapUrl;
  final String? website;
  final String? governor;
  final String? governorPhotoUrl;
  final String? viceGovernor;
  final String? viceGovernorPhotoUrl;
  final List<Map<String, dynamic>> ministers;
  final List<City> cities;
  final List<ProvinceEconomicResource> economicResources;
  final List<ProvinceTourism> tourismSites;
  final List<ProvinceEmergencyContact> emergencyContacts;
  final List<ProvinceAdministrativeDivision> administrativeDivisions;
  final List<Map<String, dynamic>> achievements;
  final List<Map<String, dynamic>> tribes;
  final List<Map<String, dynamic>> galleryMedia;
  final String? languages;
  final String? resources;
  final int? territoriesCount;

  Province({
    required this.id,
    required this.name,
    required this.code,
    required this.capital,
    required this.region,
    this.area,
    this.population,
    this.description,
    this.history,
    this.climate,
    this.infrastructure,
    this.education,
    this.coverImageUrl,
    this.coatOfArmsUrl,
    this.mapUrl,
    this.website,
    this.governor,
    this.governorPhotoUrl,
    this.viceGovernor,
    this.viceGovernorPhotoUrl,
    this.ministers = const [],
    this.cities = const [],
    this.economicResources = const [],
    this.tourismSites = const [],
    this.emergencyContacts = const [],
    this.administrativeDivisions = const [],
    this.achievements = const [],
    this.tribes = const [],
    this.galleryMedia = const [],
    this.languages,
    this.resources,
    this.territoriesCount,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      capital: json['capital'] ?? '',
      region: json['region'] ?? '',
      area: json['area'],
      population: json['population'],
      description: json['description'],
      history: json['history'],
      climate: json['climate'],
      infrastructure: json['infrastructure'],
      education: json['education'],
      coverImageUrl: json['cover_image_url'],
      coatOfArmsUrl: json['coat_of_arms_url'],
      mapUrl: json['map_url'],
      website: json['website'],
      governor: json['governor'],
      governorPhotoUrl: json['governor_photo_url'],
      viceGovernor: json['vice_governor'],
      viceGovernorPhotoUrl: json['vice_governor_photo_url'],
      ministers: (json['ministers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      cities: (json['cities'] as List?)?.map((e) => City.fromJson(e)).toList() ?? [],
      economicResources: (json['economic_resources'] as List?)?.map((e) => ProvinceEconomicResource.fromJson(e)).toList() ?? [],
      tourismSites: (json['tourism_sites'] as List?)?.map((e) => ProvinceTourism.fromJson(e)).toList() ?? [],
      emergencyContacts: (json['emergency_contacts'] as List?)?.map((e) => ProvinceEmergencyContact.fromJson(e)).toList() ?? [],
      administrativeDivisions: (json['administrative_divisions'] as List?)?.map((e) => ProvinceAdministrativeDivision.fromJson(e)).toList() ?? [],
      achievements: (json['achievements'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      tribes: (json['tribes'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      galleryMedia: (json['gallery_media'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      languages: json['languages'],
      resources: json['resources'],
      territoriesCount: json['territories_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'capital': capital,
      'region': region,
      'area': area,
      'population': population,
      'description': description,
      'history': history,
      'climate': climate,
      'infrastructure': infrastructure,
      'education': education,
      'cover_image_url': coverImageUrl,
      'coat_of_arms_url': coatOfArmsUrl,
      'map_url': mapUrl,
      'website': website,
      'governor': governor,
      'governor_photo_url': governorPhotoUrl,
      'vice_governor': viceGovernor,
      'vice_governor_photo_url': viceGovernorPhotoUrl,
      'ministers': ministers,
      'cities': cities.map((e) => e.toJson()).toList(),
      'economic_resources': economicResources.map((e) => e.toJson()).toList(),
      'tourism_sites': tourismSites.map((e) => e.toJson()).toList(),
      'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'administrative_divisions': administrativeDivisions.map((e) => e.toJson()).toList(),
      'achievements': achievements,
      'tribes': tribes,
      'gallery_media': galleryMedia,
      'languages': languages,
      'resources': resources,
      'territories_count': territoriesCount,
    };
  }
}

class City {
  final String? id;
  final String? provinceId;
  final String name;
  final String? population;
  final bool isCapital;
  final String? mayor;
  final String? mayorPhotoUrl;
  final List<Map<String, dynamic>> media;

  City({this.id, this.provinceId, required this.name, this.population, this.isCapital = false, this.mayor, this.mayorPhotoUrl, this.media = const []});

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'],
        provinceId: json['province_id'],
        name: json['name'] ?? '',
        population: json['population']?.toString(),
        isCapital: json['is_capital'] ?? false,
        mayor: json['mayor'],
        mayorPhotoUrl: json['mayor_photo_url'],
        media: (json['media'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'name': name,
        'population': population,
        'is_capital': isCapital,
        'mayor': mayor,
        'mayor_photo_url': mayorPhotoUrl,
        'media': media,
      };
}

class ProvinceEconomicResource {
  final String? id;
  final String? provinceId;
  final String name;
  final String? description;
  final List<Map<String, dynamic>> media;

  ProvinceEconomicResource({this.id, this.provinceId, required this.name, this.description, this.media = const []});

  factory ProvinceEconomicResource.fromJson(Map<String, dynamic> json) => ProvinceEconomicResource(
        id: json['id'],
        provinceId: json['province_id'],
        name: json['name'] ?? '',
        description: json['description'],
        media: (json['media'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {'id': id, 'province_id': provinceId, 'name': name, 'description': description, 'media': media};
}

class ProvinceTourism {
  final String? id;
  final String? provinceId;
  final String name;
  final String type;
  final String? description;
  final List<Map<String, dynamic>> media;

  ProvinceTourism({this.id, this.provinceId, required this.name, required this.type, this.description, this.media = const []});

  factory ProvinceTourism.fromJson(Map<String, dynamic> json) => ProvinceTourism(
        id: json['id'],
        provinceId: json['province_id'],
        name: json['name'] ?? '',
        type: json['type'] ?? '',
        description: json['description'],
        media: (json['media'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {'id': id, 'province_id': provinceId, 'name': name, 'type': type, 'description': description, 'media': media};
}

class ProvinceEmergencyContact {
  final String? id;
  final String? provinceId;
  final String service;
  final String phone;

  ProvinceEmergencyContact({this.id, this.provinceId, required this.service, required this.phone});

  factory ProvinceEmergencyContact.fromJson(Map<String, dynamic> json) => ProvinceEmergencyContact(
        id: json['id'],
        provinceId: json['province_id'],
        service: json['service'] ?? '',
        phone: json['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'province_id': provinceId, 'service': service, 'phone': phone};
}

class ProvinceAdministrativeDivision {
  final String? id;
  final String? provinceId;
  final String type;
  final String name;
  final String? capital;
  final String? population;
  final String? area;
  final String? administrator;
  final List<Map<String, dynamic>> media;

  ProvinceAdministrativeDivision({this.id, this.provinceId, required this.type, required this.name, this.capital, this.population, this.area, this.administrator, this.media = const []});

  factory ProvinceAdministrativeDivision.fromJson(Map<String, dynamic> json) => ProvinceAdministrativeDivision(
        id: json['id'],
        provinceId: json['province_id'],
        type: json['type'] ?? '',
        name: json['name'] ?? '',
        capital: json['capital'],
        population: json['population']?.toString(),
        area: json['area']?.toString(),
        administrator: json['administrator'],
        media: (json['media'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'province_id': provinceId,
        'type': type,
        'name': name,
        'capital': capital,
        'population': population,
        'area': area,
        'administrator': administrator,
        'media': media,
      };
}
