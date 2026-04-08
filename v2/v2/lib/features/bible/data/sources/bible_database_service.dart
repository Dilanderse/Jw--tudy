import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';
import '../../domain/models/bible_models.dart';
import '../../../talks/domain/models/talk_models.dart';

class BibleDatabaseService {
  Database? _db;

  Future<void> initDatabase() async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, 'bible.sqlite');
    final exists = await File(dbPath).exists();

    if (!exists) {
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'data', 'bible.sqlite'));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception("Impossible de charger la base de données: $e");
      }
    }

    _db = await openDatabase(
      dbPath,
      version: 11, // v11 adds atlas studio persistence
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS book_intro_videos');
          await db.execute('''
            CREATE TABLE book_intro_videos (
              book_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              stream_url TEXT NOT NULL,
              thumbnail_url TEXT,
              local_path TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          // Simplistic v5 schema (verse-level)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_highlights (
              verse_id INTEGER PRIMARY KEY,
              color_hex TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_notes (
              verse_id INTEGER PRIMARY KEY,
              content TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          // Recreate for v6 (offset-level)
          await db.execute('DROP TABLE IF EXISTS user_highlights');
          await db.execute('DROP TABLE IF EXISTS user_notes');
          await db.execute('''
            CREATE TABLE user_highlights (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              verse_id INTEGER NOT NULL,
              start_offset INTEGER NOT NULL,
              end_offset INTEGER NOT NULL,
              color_hex TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE user_notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              verse_id INTEGER NOT NULL,
              start_offset INTEGER NOT NULL,
              end_offset INTEGER NOT NULL,
              content TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE talks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              theme TEXT NOT NULL,
              number_of_parts INTEGER NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE talk_parts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              talk_id INTEGER NOT NULL,
              part_order INTEGER NOT NULL,
              content TEXT NOT NULL,
              FOREIGN KEY (talk_id) REFERENCES talks (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE talks ADD COLUMN total_duration_minutes INTEGER DEFAULT 30');
          await db.execute('ALTER TABLE talk_parts ADD COLUMN duration_minutes INTEGER DEFAULT 0');
        }
        if (oldVersion < 9) {
          await db.execute(
            "ALTER TABLE user_notes ADD COLUMN note_type TEXT NOT NULL DEFAULT 'text'",
          );
          await db.execute(
            'ALTER TABLE user_notes ADD COLUMN media_source TEXT',
          );
        }
        if (oldVersion < 10) {
          await db.execute(
            'ALTER TABLE user_notes ADD COLUMN note_title TEXT',
          );
        }
        if (oldVersion < 11) {
          await _createAtlasTables(db);
        }
      },
    );
  }

  Future<void> _createAtlasTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS atlas_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        image_url TEXT,
        map_data TEXT,
        start_date TEXT,
        end_date TEXT,
        era TEXT,
        tags TEXT,
        category TEXT,
        importance INTEGER NOT NULL DEFAULT 3,
        color_hex TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS atlas_item_verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        atlas_item_id INTEGER NOT NULL,
        verse_id INTEGER NOT NULL,
        UNIQUE(atlas_item_id, verse_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS atlas_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS atlas_collection_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        atlas_item_id INTEGER NOT NULL,
        UNIQUE(collection_id, atlas_item_id)
      )
    ''');
  }

  Future<List<BibleBook>> getBooks() async {
    if (_db == null) await initDatabase();
    final List<Map<String, dynamic>> maps = await _db!.query('books', orderBy: 'sort_order ASC');
    return List.generate(maps.length, (i) => BibleBook.fromMap(maps[i]));
  }

  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber) async {
    if (_db == null) await initDatabase();
    
    final List<Map<String, dynamic>> verseRows = await _db!.rawQuery('''
      SELECT 
        v.id as verse_id,
        v.verse_number,
        v.text,
        vn.note_id,
        vn.note_text
      FROM verses v
      JOIN chapters c ON c.id = v.chapter_id
      LEFT JOIN verse_notes vn ON vn.verse_id = v.id
      WHERE c.book_id = ? AND c.chapter_number = ?
      ORDER BY v.verse_number ASC, vn.note_order ASC
    ''', [bookId, chapterNumber]);

    final Map<int, BibleVerse> groupedVerses = {};

    for (final row in verseRows) {
      final verseId = row['verse_id'] as int;
      final verseNumber = row['verse_number'] as int;
      
      if (!groupedVerses.containsKey(verseNumber)) {
        // Fetch media for this verse
        final mediaRows = await _db!.query('verse_media', where: 'verse_id = ?', whereArgs: [verseId]);
        final media = mediaRows.map((m) => BibleVerseMedia(
          id: m['id'] as int,
          mediaType: m['media_type'] as String,
          provider: m['provider'] as String?,
          sourceUrl: m['source_url'] as String,
          title: m['title'] as String?,
        )).toList();

        // Fetch strong tags for this verse
        final strongRows = await _db!.query('verse_strong_tags', where: 'verse_id = ?', whereArgs: [verseId]);
        final strongTags = strongRows.map((s) => StrongTag(
          id: s['id'] as int,
          tokenText: s['token_text'] as String,
          strongNumber: s['strong_number'] as String,
          lemma: s['lemma'] as String?,
        )).toList();

        // Fetch user highlights
        final highlightRows = await _db!.query('user_highlights', where: 'verse_id = ?', whereArgs: [verseId]);
        final highlights = highlightRows.map((h) => UserHighlight(
          id: h['id'] as int,
          startOffset: h['start_offset'] as int,
          endOffset: h['end_offset'] as int,
          colorHex: h['color_hex'] as String,
          createdAt: DateTime.parse(h['created_at'] as String),
        )).toList();

        // Fetch user notes
        final userNoteRows = await _db!.query(
          'user_notes',
          where: 'verse_id = ?',
          whereArgs: [verseId],
          orderBy: 'updated_at DESC, id DESC',
        );
        final userNotes = userNoteRows.map((n) => UserNote(
          id: n['id'] as int,
          startOffset: n['start_offset'] as int,
          endOffset: n['end_offset'] as int,
          title: n['note_title'] as String?,
          content: n['content'] as String,
          noteType: userNoteTypeFromDbValue(n['note_type'] as String?),
          mediaSource: n['media_source'] as String?,
          updatedAt: DateTime.parse(n['updated_at'] as String),
        )).toList();
        final atlasLinks = await _getAtlasLinksForVerse(verseId);

        groupedVerses[verseNumber] = BibleVerse(
          id: verseId,
          number: verseNumber,
          text: row['text'] as String,
          notes: [],
          media: media,
          strongTags: strongTags,
          highlights: highlights,
          userNotes: userNotes,
          atlasLinks: atlasLinks,
        );
      }

      if (row['note_id'] != null) {
        groupedVerses[verseNumber]!.notes.add(
          BibleVerseNote(
            id: row['note_id'] as String,
            text: row['note_text'] as String,
          ),
        );
      }
    }

    return groupedVerses.values.toList()..sort((a, b) => a.number.compareTo(b.number));
  }

  Future<List<AtlasVerseLinkBadge>> _getAtlasLinksForVerse(int verseId) async {
    if (_db == null) await initDatabase();
    final rows = await _db!.rawQuery(
      '''
      SELECT ai.id, ai.title, ai.type, ai.era
      FROM atlas_item_verses aiv
      JOIN atlas_items ai ON ai.id = aiv.atlas_item_id
      WHERE aiv.verse_id = ?
      ORDER BY ai.updated_at DESC, ai.title COLLATE NOCASE ASC
      ''',
      [verseId],
    );

    return rows.map((row) {
      return AtlasVerseLinkBadge(
        atlasItemId: row['id'] as int,
        title: row['title'] as String,
        type: atlasItemTypeFromDb(row['type'] as String),
        era: row['era'] as String?,
      );
    }).toList();
  }

  Future<List<AtlasLinkedVerse>> _getLinkedVersesForAtlasItem(int atlasItemId) async {
    if (_db == null) await initDatabase();
    final rows = await _db!.rawQuery(
      '''
      SELECT
        v.id AS verse_id,
        b.id AS book_id,
        b.name AS book_name,
        c.chapter_number,
        v.verse_number,
        v.text
      FROM atlas_item_verses aiv
      JOIN verses v ON v.id = aiv.verse_id
      JOIN chapters c ON c.id = v.chapter_id
      JOIN books b ON b.id = c.book_id
      WHERE aiv.atlas_item_id = ?
      ORDER BY b.sort_order ASC, c.chapter_number ASC, v.verse_number ASC
      ''',
      [atlasItemId],
    );

    return rows.map((row) {
      return AtlasLinkedVerse(
        verseId: row['verse_id'] as int,
        bookId: row['book_id'] as String,
        bookName: row['book_name'] as String,
        chapterNumber: row['chapter_number'] as int,
        verseNumber: row['verse_number'] as int,
        verseText: row['text'] as String,
      );
    }).toList();
  }

  Future<List<int>> _getCollectionIdsForAtlasItem(int atlasItemId) async {
    if (_db == null) await initDatabase();
    final rows = await _db!.query(
      'atlas_collection_items',
      columns: ['collection_id'],
      where: 'atlas_item_id = ?',
      whereArgs: [atlasItemId],
      orderBy: 'collection_id ASC',
    );

    return rows.map((row) => row['collection_id'] as int).toList();
  }

  Future<List<AtlasCollection>> getAtlasCollections() async {
    if (_db == null) await initDatabase();
    final rows = await _db!.query(
      'atlas_collections',
      orderBy: 'updated_at DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(AtlasCollection.fromMap).toList();
  }

  Future<int> saveAtlasCollection({
    int? id,
    required String name,
    String description = '',
  }) async {
    if (_db == null) await initDatabase();
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      return _db!.insert(
        'atlas_collections',
        {
          'name': name,
          'description': description,
          'created_at': now,
          'updated_at': now,
        },
      );
    }

    await _db!.update(
      'atlas_collections',
      {
        'name': name,
        'description': description,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> deleteAtlasCollection(int collectionId) async {
    if (_db == null) await initDatabase();
    await _db!.transaction((txn) async {
      await txn.delete(
        'atlas_collection_items',
        where: 'collection_id = ?',
        whereArgs: [collectionId],
      );
      await txn.delete(
        'atlas_collections',
        where: 'id = ?',
        whereArgs: [collectionId],
      );
    });
  }

  Future<List<AtlasItem>> getAtlasItems({
    String search = '',
    Set<AtlasItemType>? types,
    String? era,
    int? collectionId,
  }) async {
    if (_db == null) await initDatabase();

    final where = <String>[];
    final whereArgs = <Object?>[];
    final trimmedSearch = search.trim();

    if (trimmedSearch.isNotEmpty) {
      where.add(
        '(title LIKE ? OR description LIKE ? OR tags LIKE ? OR category LIKE ?)',
      );
      for (int i = 0; i < 4; i++) {
        whereArgs.add('%$trimmedSearch%');
      }
    }

    if (types != null && types.isNotEmpty) {
      final placeholders = List.filled(types.length, '?').join(', ');
      where.add('type IN ($placeholders)');
      whereArgs.addAll(types.map((type) => type.dbValue));
    }

    if (era != null && era.trim().isNotEmpty) {
      where.add('era = ?');
      whereArgs.add(era);
    }

    if (collectionId != null) {
      where.add(
        'id IN (SELECT atlas_item_id FROM atlas_collection_items WHERE collection_id = ?)',
      );
      whereArgs.add(collectionId);
    }

    final rows = await _db!.query(
      'atlas_items',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC, title COLLATE NOCASE ASC',
    );

    final items = <AtlasItem>[];
    for (final row in rows) {
      final itemId = row['id'] as int;
      final linkedVerses = await _getLinkedVersesForAtlasItem(itemId);
      final collectionIds = await _getCollectionIdsForAtlasItem(itemId);
      items.add(
        AtlasItem.fromMap(
          row,
          linkedVerses: linkedVerses,
          collectionIds: collectionIds,
        ),
      );
    }
    return items;
  }

  Future<AtlasItem?> getAtlasItemById(int itemId) async {
    if (_db == null) await initDatabase();
    final rows = await _db!.query(
      'atlas_items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return AtlasItem.fromMap(
      rows.first,
      linkedVerses: await _getLinkedVersesForAtlasItem(itemId),
      collectionIds: await _getCollectionIdsForAtlasItem(itemId),
    );
  }

  Future<int> saveAtlasItem({
    int? id,
    required AtlasItemType type,
    required String title,
    String description = '',
    String? imageUrl,
    required AtlasMapData mapData,
    DateTime? startDate,
    DateTime? endDate,
    String? era,
    List<String> tags = const [],
    String? category,
    int importance = 3,
    String? colorHex,
    List<int> verseIds = const [],
    List<int> collectionIds = const [],
  }) async {
    if (_db == null) await initDatabase();
    final now = DateTime.now().toIso8601String();

    return _db!.transaction((txn) async {
      final atlasItemId = id ??
          await txn.insert(
            'atlas_items',
            {
              'type': type.dbValue,
              'title': title,
              'description': description,
              'image_url': imageUrl,
              'map_data': mapData.encode(),
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
              'era': era,
              'tags': jsonEncode(tags),
              'category': category,
              'importance': importance,
              'color_hex': colorHex,
              'created_at': now,
              'updated_at': now,
            },
          );

      if (id != null) {
        await txn.update(
          'atlas_items',
          {
            'type': type.dbValue,
            'title': title,
            'description': description,
            'image_url': imageUrl,
            'map_data': mapData.encode(),
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'era': era,
            'tags': jsonEncode(tags),
            'category': category,
            'importance': importance,
            'color_hex': colorHex,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await txn.delete(
        'atlas_item_verses',
        where: 'atlas_item_id = ?',
        whereArgs: [atlasItemId],
      );
      await txn.delete(
        'atlas_collection_items',
        where: 'atlas_item_id = ?',
        whereArgs: [atlasItemId],
      );

      for (final verseId in verseIds.toSet()) {
        await txn.insert(
          'atlas_item_verses',
          {
            'atlas_item_id': atlasItemId,
            'verse_id': verseId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      for (final collectionId in collectionIds.toSet()) {
        await txn.insert(
          'atlas_collection_items',
          {
            'collection_id': collectionId,
            'atlas_item_id': atlasItemId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return atlasItemId;
    });
  }

  Future<void> deleteAtlasItem(int atlasItemId) async {
    if (_db == null) await initDatabase();
    await _db!.transaction((txn) async {
      await txn.delete(
        'atlas_item_verses',
        where: 'atlas_item_id = ?',
        whereArgs: [atlasItemId],
      );
      await txn.delete(
        'atlas_collection_items',
        where: 'atlas_item_id = ?',
        whereArgs: [atlasItemId],
      );
      await txn.delete(
        'atlas_items',
        where: 'id = ?',
        whereArgs: [atlasItemId],
      );
    });
  }

  Future<BookIntroVideo?> getBookIntroVideo(String bookId) async {
    if (_db == null) await initDatabase();
    final List<Map<String, dynamic>> maps = await _db!.query(
      'book_intro_videos',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );

    if (maps.isEmpty) return null;
    return BookIntroVideo.fromMap(maps[0]);
  }

  Future<void> updateBookIntroLocalPath(String bookId, String? localPath) async {
    if (_db == null) await initDatabase();
    await _db!.update(
      'book_intro_videos',
      {'local_path': localPath},
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }
  
  Future<void> setBookIntroVideo(BookIntroVideo video) async {
    if (_db == null) await initDatabase();
    await _db!.insert(
      'book_intro_videos',
      {
        'book_id': video.bookId,
        'title': video.title,
        'stream_url': video.streamUrl,
        'thumbnail_url': video.thumbnailUrl,
        'local_path': video.localPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveHighlight(int verseId, int start, int end, String colorHex) async {
    if (_db == null) await initDatabase();
    await _db!.insert(
      'user_highlights',
      {
        'verse_id': verseId,
        'start_offset': start,
        'end_offset': end,
        'color_hex': colorHex,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> removeHighlight(int highlightId) async {
    if (_db == null) await initDatabase();
    await _db!.delete('user_highlights', where: 'id = ?', whereArgs: [highlightId]);
  }

  Future<void> saveNote({
    required int verseId,
    required int start,
    required int end,
    String? title,
    required String content,
    UserNoteType noteType = UserNoteType.text,
    String? mediaSource,
  }) async {
    if (_db == null) await initDatabase();
    await _db!.insert(
      'user_notes',
      {
        'verse_id': verseId,
        'start_offset': start,
        'end_offset': end,
        'note_title': title,
        'content': content,
        'note_type': noteType.dbValue,
        'media_source': mediaSource,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> removeNote(int noteId) async {
    if (_db == null) await initDatabase();
    await _db!.delete('user_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  // --- Talks (Discours) Methods ---

  Future<List<Talk>> getTalks() async {
    if (_db == null) await initDatabase();
    final List<Map<String, dynamic>> maps = await _db!.query('talks', orderBy: 'created_at DESC');
    
    final talks = <Talk>[];
    for (final map in maps) {
      final talkId = map['id'] as int;
      final partMaps = await _db!.query('talk_parts', where: 'talk_id = ?', whereArgs: [talkId], orderBy: 'part_order ASC');
      final parts = partMaps.map((p) => TalkPart.fromMap(p)).toList();
      talks.add(Talk.fromMap(map, parts));
    }
    return talks;
  }

  Future<int> createTalk(String theme, int numberOfParts, int totalDurationMinutes) async {
    if (_db == null) await initDatabase();
    return await _db!.transaction((txn) async {
      final talkId = await txn.insert('talks', {
        'theme': theme,
        'number_of_parts': numberOfParts,
        'total_duration_minutes': totalDurationMinutes,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (int i = 0; i < numberOfParts; i++) {
        await txn.insert('talk_parts', {
          'talk_id': talkId,
          'part_order': i,
          'content': '',
        });
      }
      return talkId;
    });
  }

  Future<void> updateTalkPart(int partId, String content) async {
    if (_db == null) await initDatabase();
    await _db!.update(
      'talk_parts',
      {'content': content},
      where: 'id = ?',
      whereArgs: [partId],
    );
  }

  Future<void> updateTalkPartDuration(int partId, int duration) async {
    if (_db == null) await initDatabase();
    await _db!.update(
      'talk_parts',
      {'duration_minutes': duration},
      where: 'id = ?',
      whereArgs: [partId],
    );
  }

  Future<void> deleteTalk(int talkId) async {
    if (_db == null) await initDatabase();
    await _db!.delete('talks', where: 'id = ?', whereArgs: [talkId]);
    // Cascade delete is handled by the table definition in some SQLite setups, 
    // but we can be explicit if needed.
  }
}
