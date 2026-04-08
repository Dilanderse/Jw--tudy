
class Talk {
  final int id;
  final String theme;
  final DateTime createdAt;
  final int numberOfParts;
  final int totalDurationMinutes;
  final List<TalkPart> parts;

  Talk({
    required this.id,
    required this.theme,
    required this.createdAt,
    required this.numberOfParts,
    required this.totalDurationMinutes,
    this.parts = const [],
  });

  factory Talk.fromMap(Map<String, dynamic> map, [List<TalkPart> parts = const []]) {
    return Talk(
      id: map['id'] as int,
      theme: map['theme'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      numberOfParts: map['number_of_parts'] as int,
      totalDurationMinutes: map['total_duration_minutes'] as int? ?? 30, // Default to 30 if null
      parts: parts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'theme': theme,
      'created_at': createdAt.toIso8601String(),
      'number_of_parts': numberOfParts,
      'total_duration_minutes': totalDurationMinutes,
    };
  }
}

class TalkPart {
  final int id;
  final int talkId;
  final int partOrder;
  final String content;
  final int durationMinutes;

  TalkPart({
    required this.id,
    required this.talkId,
    required this.partOrder,
    required this.content,
    required this.durationMinutes,
  });

  factory TalkPart.fromMap(Map<String, dynamic> map) {
    return TalkPart(
      id: map['id'] as int,
      talkId: map['talk_id'] as int,
      partOrder: map['part_order'] as int,
      content: map['content'] as String,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talk_id': talkId,
      'part_order': partOrder,
      'content': content,
      'duration_minutes': durationMinutes,
    };
  }
}
