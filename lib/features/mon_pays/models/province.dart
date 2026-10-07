// lib/features/mon_pays/models/province.dart

class Province {
  final String id;
  final String name;
  final String code;
  final String capital;
  final String region;
  final String? motto;
  final int? area;
  final int? population;
  final String? description;
  final String? history;
  final String? climate;
  final String? infrastructure;
  final String? education;
  final String? coverImageUrl;
  final String? coatOfArmsUrl;
  final String? flagUrl;
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
    this.motto,
    this.area,
    this.population,
    this.description,
    this.history,
    this.climate,
    this.infrastructure,
    this.education,
    this.coverImageUrl,
    this.coatOfArmsUrl,
    this.flagUrl,
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
      motto: json['motto'],
      area: json['area'],
      population: json['population'],
      description: json['description'],
      history: json['history'],
      climate: json['climate'],
      infrastructure: json['infrastructure'],
      education: json['education'],
      coverImageUrl: json['cover_image_url'],
      coatOfArmsUrl: json['coat_of_arms_url'],
      flagUrl: json['flag_url'],
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
      'motto': motto,
      'area': area,
      'population': population,
      'description': description,
      'history': history,
      'climate': climate,
      'infrastructure': infrastructure,
      'education': education,
      'cover_image_url': coverImageUrl,
      'coat_of_arms_url': coatOfArmsUrl,
      'flag_url': flagUrl,
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
  final String? imageUrl;
  final List<Map<String, dynamic>> media;

  City({
    this.id,
    this.provinceId,
    required this.name,
    this.population,
    this.isCapital = false,
    this.mayor,
    this.mayorPhotoUrl,
    this.imageUrl,
    this.media = const [],
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'],
        provinceId: json['province_id'],
        name: json['name'] ?? '',
        population: json['population']?.toString(),
        isCapital: json['is_capital'] ?? false,
        mayor: json['mayor'],
        mayorPhotoUrl: json['mayor_photo_url'],
        imageUrl: json['image_url'],
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
        'image_url': imageUrl,
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

// ═══════════════════════════════════════════════════════════════
// NOUVEAUX MODÈLES (v3 Admin_thix)
// ═══════════════════════════════════════════════════════════════

class ProvinceHymn {
  final String? id;
  final String? provinceId;
  final String? title;
  final String? lyrics;
  final String? audioUrl;
  final String? instrumentalUrl;

  ProvinceHymn({this.id, this.provinceId, this.title, this.lyrics, this.audioUrl, this.instrumentalUrl});

  factory ProvinceHymn.fromJson(Map<String, dynamic> json) => ProvinceHymn(
        id: json['id'],
        provinceId: json['province_id'],
        title: json['title'],
        lyrics: json['lyrics'],
        audioUrl: json['audio_url'],
        instrumentalUrl: json['instrumental_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'title': title, 'lyrics': lyrics,
        'audio_url': audioUrl, 'instrumental_url': instrumentalUrl,
      };
}

class ProvinceNews {
  final String? id;
  final String? provinceId;
  final String title;
  final String? summary;
  final String? category;
  final String? url;
  final String? imageUrl;
  final bool isAlert;
  final bool isPublished;
  final DateTime? publishedAt;

  ProvinceNews({this.id, this.provinceId, required this.title, this.summary, this.category, this.url, this.imageUrl, this.isAlert = false, this.isPublished = true, this.publishedAt});

  factory ProvinceNews.fromJson(Map<String, dynamic> json) => ProvinceNews(
        id: json['id'], provinceId: json['province_id'], title: json['title'] ?? '', summary: json['summary'], category: json['category'], url: json['url'], imageUrl: json['image_url'], isAlert: json['is_alert'] ?? false, isPublished: json['is_published'] ?? true, publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'title': title, 'summary': summary, 'category': category,
        'url': url, 'image_url': imageUrl, 'is_alert': isAlert, 'is_published': isPublished, 'published_at': publishedAt?.toIso8601String(),
      };
}

class ProvinceProject {
  final String? id;
  final String? provinceId;
  final String name;
  final String? description;
  final String? category;
  final String? imageUrl;
  final double progress;
  final String? budget;
  final DateTime? deadline;

  ProvinceProject({this.id, this.provinceId, required this.name, this.description, this.category, this.imageUrl, this.progress = 0.0, this.budget, this.deadline});

  factory ProvinceProject.fromJson(Map<String, dynamic> json) => ProvinceProject(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', description: json['description'], category: json['category'], imageUrl: json['image_url'], progress: (json['progress'] is num) ? (json['progress'] as num).toDouble() : 0.0, budget: json['budget'], deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'description': description, 'category': category,
        'image_url': imageUrl, 'progress': progress, 'budget': budget, 'deadline': deadline?.toIso8601String(),
      };
}

class ProvinceService {
  final String? id;
  final String? provinceId;
  final String name;
  final String? description;
  final String? category;
  final String? hours;
  final String? address;
  final String? phone;
  final bool isActive;

  ProvinceService({this.id, this.provinceId, required this.name, this.description, this.category, this.hours, this.address, this.phone, this.isActive = true});

  factory ProvinceService.fromJson(Map<String, dynamic> json) => ProvinceService(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', description: json['description'], category: json['category'], hours: json['hours'], address: json['address'], phone: json['phone'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'description': description, 'category': category,
        'hours': hours, 'address': address, 'phone': phone, 'is_active': isActive,
      };
}

class ProvinceEngagement {
  final String? id;
  final String? provinceId;
  final String? type;
  final String title;
  final String? description;
  final int participantsCount;
  final bool isActive;

  ProvinceEngagement({this.id, this.provinceId, this.type, required this.title, this.description, this.participantsCount = 0, this.isActive = true});

  factory ProvinceEngagement.fromJson(Map<String, dynamic> json) => ProvinceEngagement(
        id: json['id'], provinceId: json['province_id'], type: json['type'], title: json['title'] ?? '', description: json['description'], participantsCount: json['participants_count'] is int ? json['participants_count'] : (int.tryParse(json['participants_count']?.toString() ?? '0') ?? 0), isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'type': type, 'title': title, 'description': description,
        'participants_count': participantsCount, 'is_active': isActive,
      };
}

class ProvinceBudget {
  final String? id;
  final String? provinceId;
  final String sector;
  final num amount;
  final double percentage;

  ProvinceBudget({this.id, this.provinceId, required this.sector, this.amount = 0, this.percentage = 0.0});

  factory ProvinceBudget.fromJson(Map<String, dynamic> json) => ProvinceBudget(
        id: json['id'], provinceId: json['province_id'], sector: json['sector'] ?? '', amount: (json['amount'] is num) ? json['amount'] : (num.tryParse(json['amount']?.toString() ?? '0') ?? 0), percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : 0.0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'province_id': provinceId, 'sector': sector, 'amount': amount, 'percentage': percentage};
}

class ProvinceDemographic {
  final String? id;
  final String? provinceId;
  final int year;
  final int population;

  ProvinceDemographic({this.id, this.provinceId, required this.year, required this.population});

  factory ProvinceDemographic.fromJson(Map<String, dynamic> json) => ProvinceDemographic(
        id: json['id'], provinceId: json['province_id'], year: json['year'] is int ? json['year'] : (int.tryParse(json['year']?.toString() ?? '0') ?? 0), population: json['population'] is int ? json['population'] : (int.tryParse(json['population']?.toString() ?? '0') ?? 0),
      );

  Map<String, dynamic> toJson() => {'id': id, 'province_id': provinceId, 'year': year, 'population': population};
}

class ProvinceDocument {
  final String? id;
  final String? provinceId;
  final String title;
  final String? type;
  final String fileUrl;
  final bool isPublished;
  final DateTime? publishedAt;

  ProvinceDocument({this.id, this.provinceId, required this.title, this.type, required this.fileUrl, this.isPublished = true, this.publishedAt});

  factory ProvinceDocument.fromJson(Map<String, dynamic> json) => ProvinceDocument(
        id: json['id'], provinceId: json['province_id'], title: json['title'] ?? '', type: json['type'], fileUrl: json['file_url'] ?? '', isPublished: json['is_published'] ?? true, publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'title': title, 'type': type, 'file_url': fileUrl,
        'is_published': isPublished, 'published_at': publishedAt?.toIso8601String(),
      };
}

class ProvinceMedia {
  final String? id;
  final String? provinceId;
  final String title;
  final String? type;
  final String url;
  final String? thumbnailUrl;
  final String? duration;
  final bool isPublished;
  final DateTime? publishedAt;

  ProvinceMedia({this.id, this.provinceId, required this.title, this.type, required this.url, this.thumbnailUrl, this.duration, this.isPublished = true, this.publishedAt});

  factory ProvinceMedia.fromJson(Map<String, dynamic> json) => ProvinceMedia(
        id: json['id'], provinceId: json['province_id'], title: json['title'] ?? '', type: json['type'], url: json['url'] ?? '', thumbnailUrl: json['thumbnail_url'], duration: json['duration'], isPublished: json['is_published'] ?? true, publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'title': title, 'type': type, 'url': url, 'thumbnail_url': thumbnailUrl,
        'duration': duration, 'is_published': isPublished, 'published_at': publishedAt?.toIso8601String(),
      };
}

class ProvinceFamousPerson {
  final String? id;
  final String? provinceId;
  final String name;
  final String? field;
  final String? achievement;
  final String? bio;
  final String? photoUrl;
  final bool isActive;

  ProvinceFamousPerson({this.id, this.provinceId, required this.name, this.field, this.achievement, this.bio, this.photoUrl, this.isActive = true});

  factory ProvinceFamousPerson.fromJson(Map<String, dynamic> json) => ProvinceFamousPerson(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', field: json['field'], achievement: json['achievement'], bio: json['bio'], photoUrl: json['photo_url'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'field': field, 'achievement': achievement,
        'bio': bio, 'photo_url': photoUrl, 'is_active': isActive,
      };
}

class ProvinceGastronomy {
  final String? id;
  final String? provinceId;
  final String name;
  final String? description;
  final List<String> ingredients;
  final String? imageUrl;
  final bool isActive;

  ProvinceGastronomy({this.id, this.provinceId, required this.name, this.description, this.ingredients = const [], this.imageUrl, this.isActive = true});

  factory ProvinceGastronomy.fromJson(Map<String, dynamic> json) => ProvinceGastronomy(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', description: json['description'], ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [], imageUrl: json['image_url'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'description': description, 'ingredients': ingredients,
        'image_url': imageUrl, 'is_active': isActive,
      };
}

class ProvinceProverb {
  final String? id;
  final String? provinceId;
  final String text;
  final String? translation;
  final String? meaning;
  final String? language;
  final bool isActive;

  ProvinceProverb({this.id, this.provinceId, required this.text, this.translation, this.meaning, this.language, this.isActive = true});

  factory ProvinceProverb.fromJson(Map<String, dynamic> json) => ProvinceProverb(
        id: json['id'], provinceId: json['province_id'], text: json['text'] ?? '', translation: json['translation'], meaning: json['meaning'], language: json['language'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'text': text, 'translation': translation, 'meaning': meaning,
        'language': language, 'is_active': isActive,
      };
}

class ProvinceBusiness {
  final String? id;
  final String? provinceId;
  final String name;
  final String? sector;
  final int? employees;
  final String? description;
  final String? website;
  final String? logoUrl;
  final bool isActive;

  ProvinceBusiness({this.id, this.provinceId, required this.name, this.sector, this.employees, this.description, this.website, this.logoUrl, this.isActive = true});

  factory ProvinceBusiness.fromJson(Map<String, dynamic> json) => ProvinceBusiness(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', sector: json['sector'], employees: json['employees'] is int ? json['employees'] : (int.tryParse(json['employees']?.toString() ?? '') ?? null), description: json['description'], website: json['website'], logoUrl: json['logo_url'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'sector': sector, 'employees': employees,
        'description': description, 'website': website, 'logo_url': logoUrl, 'is_active': isActive,
      };
}

class ProvinceProduct {
  final String? id;
  final String? provinceId;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  ProvinceProduct({this.id, this.provinceId, required this.name, this.description, this.imageUrl, this.isActive = true});

  factory ProvinceProduct.fromJson(Map<String, dynamic> json) => ProvinceProduct(
        id: json['id'], provinceId: json['province_id'], name: json['name'] ?? '', description: json['description'], imageUrl: json['image_url'], isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'name': name, 'description': description, 'image_url': imageUrl, 'is_active': isActive,
      };
}

class ProvinceQuizQuestion {
  final String? id;
  final String? provinceId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int orderIndex;
  final bool isActive;

  ProvinceQuizQuestion({this.id, this.provinceId, required this.question, this.options = const [], this.correctAnswer = 0, this.orderIndex = 0, this.isActive = true});

  factory ProvinceQuizQuestion.fromJson(Map<String, dynamic> json) => ProvinceQuizQuestion(
        id: json['id'], provinceId: json['province_id'], question: json['question'] ?? '', options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [], correctAnswer: json['correct_answer'] is int ? json['correct_answer'] : (int.tryParse(json['correct_answer']?.toString() ?? '0') ?? 0), orderIndex: json['order_index'] is int ? json['order_index'] : (int.tryParse(json['order_index']?.toString() ?? '0') ?? 0), isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'province_id': provinceId, 'question': question, 'options': options,
        'correct_answer': correctAnswer, 'order_index': orderIndex, 'is_active': isActive,
      };
}
