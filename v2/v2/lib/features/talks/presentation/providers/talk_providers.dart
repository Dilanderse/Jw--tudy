import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bible/presentation/providers/bible_providers.dart';
import '../../domain/models/talk_models.dart';

final talksProvider = FutureProvider<List<Talk>>((ref) async {
  final service = ref.watch(bibleDatabaseProvider);
  return service.getTalks();
});

final selectedTalkProvider = StateProvider<Talk?>((ref) => null);
