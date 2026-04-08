import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/features/bible/domain/models/bible_models.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/bible_providers.dart';

final bookIntroVideoProvider = FutureProvider.family<BookIntroVideo?, String>((ref, bookId) async {
  final database = ref.watch(bibleDatabaseProvider);
  return await database.getBookIntroVideo(bookId);
});
