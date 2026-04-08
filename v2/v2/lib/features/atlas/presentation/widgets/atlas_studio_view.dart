import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/core/layout/app_breakpoints.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';
import 'package:jw_study_v2/features/atlas/presentation/providers/atlas_providers.dart';
import 'package:jw_study_v2/features/atlas/presentation/widgets/atlas_editor_dialog.dart';
import 'package:jw_study_v2/features/atlas/presentation/widgets/atlas_map_canvas.dart';
import 'package:jw_study_v2/features/bible/domain/models/bible_models.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/bible_providers.dart';
import 'package:jw_study_v2/features/bible/presentation/widgets/sidebar_navigation.dart';

class AtlasStudioView extends ConsumerWidget {
  const AtlasStudioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(atlasItemsProvider);
    final selectedItem = ref.watch(selectedAtlasItemProvider);
    final collectionsAsync = ref.watch(atlasCollectionsProvider);

    return Container(
      color: const Color(0xFF141414),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.large;
          final padding = constraints.maxWidth < AppBreakpoints.compact
              ? 12.0
              : 20.0;
          final sidebarHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight * 0.48).clamp(440.0, 680.0).toDouble()
              : 560.0;
          final workspaceHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight * 0.58).clamp(460.0, 760.0).toDouble()
              : 640.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: itemsAsync.when(
              data: (items) {
                if (compact) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: sidebarHeight,
                          child: _AtlasSidebar(
                            items: items,
                            collectionsAsync: collectionsAsync,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: workspaceHeight,
                          child: _AtlasWorkspace(
                            items: items,
                            selectedItem: selectedItem,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AtlasDetailPanel(
                          item: selectedItem,
                          allItems: items,
                          collectionsAsync: collectionsAsync,
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 340,
                      child: _AtlasSidebar(
                        items: items,
                        collectionsAsync: collectionsAsync,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _AtlasWorkspace(
                        items: items,
                        selectedItem: selectedItem,
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 360,
                      child: _AtlasDetailPanel(
                        item: selectedItem,
                        allItems: items,
                        collectionsAsync: collectionsAsync,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Erreur Atlas: $error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AtlasSidebar extends ConsumerStatefulWidget {
  final List<AtlasItem> items;
  final AsyncValue<List<AtlasCollection>> collectionsAsync;

  const _AtlasSidebar({required this.items, required this.collectionsAsync});

  @override
  ConsumerState<_AtlasSidebar> createState() => _AtlasSidebarState();
}

class _AtlasSidebarState extends ConsumerState<_AtlasSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(atlasSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final collectionsAsync = widget.collectionsAsync;
    final search = ref.watch(atlasSearchQueryProvider);
    final selectedTypes = ref.watch(atlasTypeFilterProvider);
    final selectedEra = ref.watch(atlasSelectedEraProvider);
    final selectedCollection = ref.watch(atlasSelectedCollectionProvider);

    if (_searchController.text != search) {
      _searchController.value = TextEditingValue(
        text: search,
        selection: TextSelection.collapsed(offset: search.length),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Atlas Biblique',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openCollectionEditor(context, ref),
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'Nouvelle collection',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Studio d’annotation cartographique et chronologique.',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                ref.read(atlasSearchQueryProvider.notifier).state = value,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un lieu, une route, un événement...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AtlasItemType.values.map((type) {
              final selected = selectedTypes.contains(type);
              return FilterChip(
                selected: selected,
                label: Text(type.label),
                onSelected: (_) {
                  final updated = {...selectedTypes};
                  if (selected) {
                    updated.remove(type);
                  } else {
                    updated.add(type);
                  }
                  ref.read(atlasTypeFilterProvider.notifier).state =
                      updated.isEmpty ? AtlasItemType.values.toSet() : updated;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            key: ValueKey('atlas-era-$selectedEra'),
            initialValue: selectedEra,
            decoration: const InputDecoration(
              labelText: 'Filtre époque',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Toutes les époques'),
              ),
              ...bibleEras.map((era) {
                return DropdownMenuItem<String?>(value: era, child: Text(era));
              }),
            ],
            onChanged: (value) {
              ref.read(atlasSelectedEraProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 14),
          collectionsAsync.when(
            data: (collections) {
              return DropdownButtonFormField<int?>(
                key: ValueKey('atlas-collection-$selectedCollection'),
                initialValue: selectedCollection,
                decoration: const InputDecoration(
                  labelText: 'Filtre collection',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Toutes les collections'),
                  ),
                  ...collections.map((collection) {
                    return DropdownMenuItem<int?>(
                      value: collection.id,
                      child: Text(collection.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  ref.read(atlasSelectedCollectionProvider.notifier).state =
                      value;
                },
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openItemEditor(context),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Ajouter à l’atlas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${items.length} élément${items.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Commence par créer un lieu, une région, un trajet ou un événement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _AtlasListCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openItemEditor(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const AtlasItemEditorDialog(),
    );
  }

  Future<void> _openCollectionEditor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Nouvelle collection atlas',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                await ref
                    .read(bibleDatabaseProvider)
                    .saveAtlasCollection(
                      name: name,
                      description: descriptionController.text.trim(),
                    );
                ref.invalidate(atlasCollectionsProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }
}

class _AtlasListCard extends ConsumerWidget {
  final AtlasItem item;

  const _AtlasListCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(atlasSelectedItemIdProvider);
    final isSelected =
        selectedId == item.id ||
        (selectedId == null &&
            ref.watch(selectedAtlasItemProvider)?.id == item.id);

    return InkWell(
      onTap: () {
        ref.read(atlasSelectedItemIdProvider.notifier).state = item.id;
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF262626) : const Color(0xFF202020),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AtlasTypePill(type: item.type),
                const Spacer(),
                Text(
                  '${item.linkedVerses.length} v.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.45),
              ),
            ],
            if (item.era != null || item.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.era != null) _MetaChip(label: item.era!),
                  for (final tag in item.tags.take(3)) _MetaChip(label: tag),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AtlasWorkspace extends ConsumerWidget {
  final List<AtlasItem> items;
  final AtlasItem? selectedItem;

  const _AtlasWorkspace({required this.items, required this.selectedItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Carte / Timeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (selectedItem != null)
                  OutlinedButton.icon(
                    onPressed: () => _openItemEditor(context, selectedItem!),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const TabBar(
              tabs: [
                Tab(text: 'Carte interactive'),
                Tab(text: 'Timeline'),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TabBarView(
                children: [
                  AtlasMapCanvas(
                    items: items,
                    selectedItemId: selectedItem?.id,
                  ),
                  _AtlasTimeline(items: items),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemEditor(BuildContext context, AtlasItem item) async {
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AtlasItemEditorDialog(initialItem: item),
    );
  }
}

class _AtlasTimeline extends ConsumerWidget {
  final List<AtlasItem> items;

  const _AtlasTimeline({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedItems = [...items]
      ..sort((a, b) {
        final aYear = a.startDate?.year ?? 999999;
        final bYear = b.startDate?.year ?? 999999;
        if (aYear != bYear) {
          return aYear.compareTo(bYear);
        }
        return a.title.compareTo(b.title);
      });

    if (sortedItems.isEmpty) {
      return const Center(
        child: Text(
          'La timeline se remplira dès que tu ajouteras des éléments avec une date ou une époque.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
        ),
      );
    }

    return ListView.separated(
      itemCount: sortedItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return InkWell(
          onTap: () {
            ref.read(atlasSelectedItemIdProvider.notifier).state = item.id;
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.startDate == null ? 'N/D' : '${item.startDate!.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AtlasTypePill(type: item.type),
                          const SizedBox(width: 8),
                          if (item.era != null) _MetaChip(label: item.era!),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AtlasDetailPanel extends ConsumerWidget {
  final AtlasItem? item;
  final List<AtlasItem> allItems;
  final AsyncValue<List<AtlasCollection>> collectionsAsync;

  const _AtlasDetailPanel({
    required this.item,
    required this.allItems,
    required this.collectionsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Text(
            'Sélectionne un élément atlas pour voir sa fiche détaillée.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
          ),
        ),
      );
    }

    final relatedItems = allItems
        .where((candidate) {
          if (candidate.id == item!.id) {
            return false;
          }
          final sameEra = item!.era != null && item!.era == candidate.era;
          final sharedVerse = candidate.linkedVerses.any(
            (verse) => item!.linkedVerses.any(
              (linked) => linked.verseId == verse.verseId,
            ),
          );
          return sameEra || sharedVerse;
        })
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                _AtlasTypePill(type: item!.type),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item!.era != null) _MetaChip(label: item!.era!),
                if (item!.category != null) _MetaChip(label: item!.category!),
                _MetaChip(label: 'Importance ${item!.importance}'),
              ],
            ),
            if (item!.description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                item!.description,
                style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.55),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: AtlasMapCanvas(items: [item!], selectedItemId: item!.id),
            ),
            const SizedBox(height: 18),
            if (item!.tags.isNotEmpty) ...[
              const Text(
                'Tags',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item!.tags
                    .map((tag) => _MetaChip(label: tag))
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            const Text(
              'Versets liés',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (item!.linkedVerses.isEmpty)
              const Text(
                'Aucun verset lié.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              )
            else
              Column(
                children: item!.linkedVerses.map((verse) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${verse.bookName} ${verse.chapterNumber}:${verse.verseNumber}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      verse.verseText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        height: 1.4,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openVerse(context, ref, verse),
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            collectionsAsync.when(
              data: (collections) {
                final linkedCollections = collections
                    .where(
                      (collection) =>
                          item!.collectionIds.contains(collection.id),
                    )
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collections',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (linkedCollections.isEmpty)
                      const Text(
                        'Aucune collection.',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: linkedCollections
                            .map(
                              (collection) => _MetaChip(label: collection.name),
                            )
                            .toList(),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            if (relatedItems.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Éléments liés',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...relatedItems.map((related) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    related.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    related.type.label,
                    style: const TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                  onTap: () {
                    ref.read(atlasSelectedItemIdProvider.notifier).state =
                        related.id;
                  },
                );
              }),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openItemEditor(context, item!),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteItem(context, ref, item!),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFCA5A5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemEditor(BuildContext context, AtlasItem item) async {
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AtlasItemEditorDialog(initialItem: item),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    AtlasItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: const Text(
            'Supprimer cet élément ?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'L’élément "${item.title}" sera retiré de la carte, de la timeline et de ses liaisons versets.',
            style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(bibleDatabaseProvider).deleteAtlasItem(item.id!);
    ref.invalidate(atlasItemsProvider);
    ref.read(atlasSelectedItemIdProvider.notifier).state = null;
  }

  Future<void> _openVerse(
    BuildContext context,
    WidgetRef ref,
    AtlasLinkedVerse verse,
  ) async {
    final books = await ref.read(bibleBooksProvider.future);
    BibleBook? book;
    for (final candidate in books) {
      if (candidate.id == verse.bookId) {
        book = candidate;
        break;
      }
    }
    if (book == null) {
      return;
    }

    ref.read(navigationProvider.notifier).state = 'bible';
    ref.read(selectedBookProvider.notifier).state = book;
    ref.read(selectedChapterProvider.notifier).state = verse.chapterNumber;
  }
}

class _AtlasTypePill extends StatelessWidget {
  final AtlasItemType type;

  const _AtlasTypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AtlasItemType.place => const Color(0xFFF87171),
      AtlasItemType.region => const Color(0xFF34D399),
      AtlasItemType.route => const Color(0xFF60A5FA),
      AtlasItemType.event => const Color(0xFFFBBF24),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
