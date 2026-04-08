import 'dart:convert';

enum AtlasItemType { place, region, route, event }

enum AtlasMapShapeType { point, polygon, polyline }

const List<String> bibleEras = [
  'Patriarches',
  'Exode',
  'Conquête',
  'Juges',
  'Royaume uni',
  'Royaume divisé',
  'Exil',
  'Retour d’exil',
  'Temps de Jésus',
  'Église primitive',
];

AtlasItemType atlasItemTypeFromDb(String value) {
  switch (value) {
    case 'region':
      return AtlasItemType.region;
    case 'route':
      return AtlasItemType.route;
    case 'event':
      return AtlasItemType.event;
    case 'place':
    default:
      return AtlasItemType.place;
  }
}

extension AtlasItemTypeX on AtlasItemType {
  String get dbValue {
    switch (this) {
      case AtlasItemType.region:
        return 'region';
      case AtlasItemType.route:
        return 'route';
      case AtlasItemType.event:
        return 'event';
      case AtlasItemType.place:
        return 'place';
    }
  }

  String get label {
    switch (this) {
      case AtlasItemType.region:
        return 'Région';
      case AtlasItemType.route:
        return 'Trajet';
      case AtlasItemType.event:
        return 'Événement';
      case AtlasItemType.place:
        return 'Lieu';
    }
  }

  AtlasMapShapeType get defaultShapeType {
    switch (this) {
      case AtlasItemType.region:
        return AtlasMapShapeType.polygon;
      case AtlasItemType.route:
        return AtlasMapShapeType.polyline;
      case AtlasItemType.event:
      case AtlasItemType.place:
        return AtlasMapShapeType.point;
    }
  }
}

AtlasMapShapeType atlasMapShapeTypeFromDb(String value) {
  switch (value) {
    case 'polygon':
      return AtlasMapShapeType.polygon;
    case 'polyline':
      return AtlasMapShapeType.polyline;
    case 'point':
    default:
      return AtlasMapShapeType.point;
  }
}

extension AtlasMapShapeTypeX on AtlasMapShapeType {
  String get dbValue {
    switch (this) {
      case AtlasMapShapeType.polygon:
        return 'polygon';
      case AtlasMapShapeType.polyline:
        return 'polyline';
      case AtlasMapShapeType.point:
        return 'point';
    }
  }
}

class AtlasCoordinate {
  final double lat;
  final double lng;
  final String? label;

  const AtlasCoordinate({
    required this.lat,
    required this.lng,
    this.label,
  });

  factory AtlasCoordinate.fromJson(Map<String, dynamic> json) {
    return AtlasCoordinate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'label': label,
    };
  }

  AtlasCoordinate copyWith({
    double? lat,
    double? lng,
    String? label,
  }) {
    return AtlasCoordinate(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
    );
  }
}

class AtlasMapData {
  final AtlasMapShapeType type;
  final List<AtlasCoordinate> points;

  const AtlasMapData({
    required this.type,
    required this.points,
  });

  factory AtlasMapData.empty(AtlasMapShapeType type) {
    return AtlasMapData(type: type, points: const []);
  }

  factory AtlasMapData.fromEncoded(String? encoded, AtlasItemType fallbackType) {
    if (encoded == null || encoded.trim().isEmpty) {
      return AtlasMapData.empty(fallbackType.defaultShapeType);
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final shapeType = atlasMapShapeTypeFromDb(
      decoded['type'] as String? ?? fallbackType.defaultShapeType.dbValue,
    );

    if (shapeType == AtlasMapShapeType.point) {
      final lat = decoded['lat'];
      final lng = decoded['lng'];
      if (lat is num && lng is num) {
        return AtlasMapData(
          type: shapeType,
          points: [
            AtlasCoordinate(
              lat: lat.toDouble(),
              lng: lng.toDouble(),
            ),
          ],
        );
      }
    }

    final pointPayload = shapeType == AtlasMapShapeType.polygon
        ? (decoded['coordinates'] as List<dynamic>? ?? const [])
        : (decoded['points'] as List<dynamic>? ?? const []);

    final points = pointPayload.map((entry) {
      if (entry is Map<String, dynamic>) {
        return AtlasCoordinate.fromJson(entry);
      }
      if (entry is List<dynamic> && entry.length >= 2) {
        return AtlasCoordinate(
          lat: (entry[0] as num).toDouble(),
          lng: (entry[1] as num).toDouble(),
        );
      }
      throw const FormatException('Invalid map point payload');
    }).toList();

    return AtlasMapData(type: shapeType, points: points);
  }

  String encode() {
    switch (type) {
      case AtlasMapShapeType.point:
        final point = points.isEmpty ? const AtlasCoordinate(lat: 0, lng: 0) : points.first;
        return jsonEncode({
          'type': type.dbValue,
          'lat': point.lat,
          'lng': point.lng,
        });
      case AtlasMapShapeType.polygon:
        return jsonEncode({
          'type': type.dbValue,
          'coordinates': points
              .map((point) => [point.lat, point.lng])
              .toList(),
        });
      case AtlasMapShapeType.polyline:
        return jsonEncode({
          'type': type.dbValue,
          'points': points.map((point) => point.toJson()).toList(),
        });
    }
  }

  AtlasMapData copyWith({
    AtlasMapShapeType? type,
    List<AtlasCoordinate>? points,
  }) {
    return AtlasMapData(
      type: type ?? this.type,
      points: points ?? this.points,
    );
  }
}

class AtlasLinkedVerse {
  final int verseId;
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;

  const AtlasLinkedVerse({
    required this.verseId,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
  });
}

class AtlasCollection {
  final int? id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AtlasCollection({
    this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AtlasCollection.fromMap(Map<String, dynamic> map) {
    return AtlasCollection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class AtlasItem {
  final int? id;
  final AtlasItemType type;
  final String title;
  final String description;
  final String? imageUrl;
  final AtlasMapData mapData;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? era;
  final List<String> tags;
  final String? category;
  final int importance;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AtlasLinkedVerse> linkedVerses;
  final List<int> collectionIds;

  const AtlasItem({
    this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.mapData,
    this.startDate,
    this.endDate,
    this.era,
    this.tags = const [],
    this.category,
    this.importance = 3,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.linkedVerses = const [],
    this.collectionIds = const [],
  });

  factory AtlasItem.fromMap(
    Map<String, dynamic> map, {
    List<AtlasLinkedVerse> linkedVerses = const [],
    List<int> collectionIds = const [],
  }) {
    final type = atlasItemTypeFromDb(map['type'] as String);
    final tagsPayload = map['tags'] as String?;
    final tags = tagsPayload == null || tagsPayload.trim().isEmpty
        ? const <String>[]
        : (jsonDecode(tagsPayload) as List<dynamic>)
            .map((entry) => entry.toString())
            .toList();

    return AtlasItem(
      id: map['id'] as int?,
      type: type,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      mapData: AtlasMapData.fromEncoded(map['map_data'] as String?, type),
      startDate: map['start_date'] == null
          ? null
          : DateTime.tryParse(map['start_date'] as String),
      endDate: map['end_date'] == null
          ? null
          : DateTime.tryParse(map['end_date'] as String),
      era: map['era'] as String?,
      tags: tags,
      category: map['category'] as String?,
      importance: (map['importance'] as int?) ?? 3,
      colorHex: map['color_hex'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      linkedVerses: linkedVerses,
      collectionIds: collectionIds,
    );
  }

  AtlasItem copyWith({
    int? id,
    AtlasItemType? type,
    String? title,
    String? description,
    String? imageUrl,
    AtlasMapData? mapData,
    DateTime? startDate,
    DateTime? endDate,
    String? era,
    List<String>? tags,
    String? category,
    int? importance,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AtlasLinkedVerse>? linkedVerses,
    List<int>? collectionIds,
  }) {
    return AtlasItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      mapData: mapData ?? this.mapData,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      era: era ?? this.era,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedVerses: linkedVerses ?? this.linkedVerses,
      collectionIds: collectionIds ?? this.collectionIds,
    );
  }
}

class AtlasVerseLinkBadge {
  final int atlasItemId;
  final String title;
  final AtlasItemType type;
  final String? era;

  const AtlasVerseLinkBadge({
    required this.atlasItemId,
    required this.title,
    required this.type,
    this.era,
  });
}
