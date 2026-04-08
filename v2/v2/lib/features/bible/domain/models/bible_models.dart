import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';

enum Testament { old, newTestament }

enum UserNoteType { text, image, video }

UserNoteType userNoteTypeFromDbValue(String? value) {
  switch (value) {
    case 'image':
      return UserNoteType.image;
    case 'video':
      return UserNoteType.video;
    case 'text':
    default:
      return UserNoteType.text;
  }
}

extension UserNoteTypeX on UserNoteType {
  String get dbValue {
    switch (this) {
      case UserNoteType.image:
        return 'image';
      case UserNoteType.video:
        return 'video';
      case UserNoteType.text:
        return 'text';
    }
  }

  bool get isMedia => this != UserNoteType.text;
}

class BibleBook {
  final String id;
  final String name;
  final String abbreviation;
  final Testament testament;
  final int chaptersCount;
  final int sortOrder;

  BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testament,
    required this.chaptersCount,
    required this.sortOrder,
  });

  factory BibleBook.fromMap(Map<String, dynamic> map) {
    return BibleBook(
      id: map['id'] as String,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      testament: map['testament'] == 'old' ? Testament.old : Testament.newTestament,
      chaptersCount: map['chapters_count'] as int,
      sortOrder: map['sort_order'] as int,
    );
  }
}

class BibleVerse {
  final int id;
  final int number;
  final String text;
  final List<BibleVerseNote> notes;
  final List<BibleVerseMedia> media;
  final List<StrongTag> strongTags;
  final List<UserHighlight> highlights; // Changed to List
  final List<UserNote> userNotes; // Changed to List
  final List<AtlasVerseLinkBadge> atlasLinks;

  BibleVerse({
    required this.id,
    required this.number,
    required this.text,
    required this.notes,
    this.media = const [],
    this.strongTags = const [],
    this.highlights = const [],
    this.userNotes = const [],
    this.atlasLinks = const [],
  });
}

class UserHighlight {
  final int? id; // Added for deletion
  final int startOffset;
  final int endOffset;
  final String colorHex;
  final DateTime createdAt;

  UserHighlight({
    this.id,
    required this.startOffset,
    required this.endOffset,
    required this.colorHex,
    required this.createdAt,
  });
}

class UserNote {
  final int? id; // Added for deletion
  final int startOffset;
  final int endOffset;
  final String? title;
  final String content;
  final UserNoteType noteType;
  final String? mediaSource;
  final DateTime updatedAt;

  UserNote({
    this.id,
    required this.startOffset,
    required this.endOffset,
    this.title,
    required this.content,
    this.noteType = UserNoteType.text,
    this.mediaSource,
    required this.updatedAt,
  });

  bool get hasTitle => title != null && title!.trim().isNotEmpty;
  bool get hasMediaSource => mediaSource != null && mediaSource!.trim().isNotEmpty;
}

class BibleVerseNote {
  final String id;
  final String text;

  BibleVerseNote({required this.id, required this.text});
}

class BibleVerseMedia {
  final int id;
  final String mediaType;
  final String? provider;
  final String sourceUrl;
  final String? title;

  BibleVerseMedia({
    required this.id,
    required this.mediaType,
    this.provider,
    required this.sourceUrl,
    this.title,
  });
}

class StrongTag {
  final int id;
  final String tokenText;
  final String strongNumber;
  final String? lemma;

  StrongTag({
    required this.id,
    required this.tokenText,
    required this.strongNumber,
    this.lemma,
  });
}

class BookIntroVideo {
  final String bookId;
  final String title;
  final String streamUrl;
  final String? thumbnailUrl;
  final String? localPath;

  BookIntroVideo({
    required this.bookId,
    required this.title,
    required this.streamUrl,
    this.thumbnailUrl,
    this.localPath,
  });

  factory BookIntroVideo.fromMap(Map<String, dynamic> map) {
    return BookIntroVideo(
      bookId: map['book_id'] as String,
      title: map['title'] as String,
      streamUrl: map['stream_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      localPath: map['local_path'] as String?,
    );
  }

  BookIntroVideo copyWith({String? localPath}) {
    return BookIntroVideo(
      bookId: bookId,
      title: title,
      streamUrl: streamUrl,
      thumbnailUrl: thumbnailUrl,
      localPath: localPath ?? this.localPath,
    );
  }
}
