import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/bible_providers.dart';

final atlasSearchQueryProvider = StateProvider<String>((ref) => '');

final atlasSelectedEraProvider = StateProvider<String?>((ref) => null);

final atlasSelectedCollectionProvider = StateProvider<int?>((ref) => null);

final atlasSelectedItemIdProvider = StateProvider<int?>((ref) => null);

final atlasTypeFilterProvider = StateProvider<Set<AtlasItemType>>(
  (ref) => AtlasItemType.values.toSet(),
);

final atlasCollectionsProvider = FutureProvider<List<AtlasCollection>>((ref) async {
  final database = ref.watch(bibleDatabaseProvider);
  return database.getAtlasCollections();
});

final atlasItemsProvider = FutureProvider<List<AtlasItem>>((ref) async {
  final database = ref.watch(bibleDatabaseProvider);
  final search = ref.watch(atlasSearchQueryProvider);
  final era = ref.watch(atlasSelectedEraProvider);
  final collectionId = ref.watch(atlasSelectedCollectionProvider);
  final types = ref.watch(atlasTypeFilterProvider);

  return database.getAtlasItems(
    search: search,
    era: era,
    collectionId: collectionId,
    types: types,
  );
});

final selectedAtlasItemProvider = Provider<AtlasItem?>((ref) {
  final selectedId = ref.watch(atlasSelectedItemIdProvider);
  final itemsAsync = ref.watch(atlasItemsProvider);
  return itemsAsync.maybeWhen(
    data: (items) {
      if (selectedId == null) {
        return items.isEmpty ? null : items.first;
      }
      for (final item in items) {
        if (item.id == selectedId) {
          return item;
        }
      }
      return items.isEmpty ? null : items.first;
    },
    orElse: () => null,
  );
});
