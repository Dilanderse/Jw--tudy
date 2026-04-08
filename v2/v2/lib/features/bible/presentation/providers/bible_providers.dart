import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sources/bible_database_service.dart';
import '../../domain/models/bible_models.dart';

final bibleDatabaseProvider = Provider<BibleDatabaseService>((ref) {
  return BibleDatabaseService();
});

final bibleBooksProvider = FutureProvider<List<BibleBook>>((ref) async {
  final service = ref.watch(bibleDatabaseProvider);
  return service.getBooks();
});

final selectedBookProvider = StateProvider<BibleBook?>((ref) => null);
final selectedChapterProvider = StateProvider<int?>((ref) => null);

final bibleVersesProvider = FutureProvider.family<List<BibleVerse>, (String, int)>((ref, arg) async {
  final service = ref.watch(bibleDatabaseProvider);
  return service.getVerses(arg.$1, arg.$2);
});
