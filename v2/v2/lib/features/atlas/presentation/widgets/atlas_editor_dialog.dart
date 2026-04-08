import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';
import 'package:jw_study_v2/features/atlas/presentation/providers/atlas_providers.dart';
import 'package:jw_study_v2/features/atlas/presentation/widgets/atlas_map_canvas.dart';
import 'package:jw_study_v2/features/bible/domain/models/bible_models.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/bible_providers.dart';

class AtlasItemEditorDialog extends ConsumerStatefulWidget {
  final AtlasItem? initialItem;

  const AtlasItemEditorDialog({
    super.key,
    this.initialItem,
  });

  @override
  ConsumerState<AtlasItemEditorDialog> createState() {
    return _AtlasItemEditorDialogState();
  }
}

class _AtlasItemEditorDialogState
    extends ConsumerState<AtlasItemEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;
  late final TextEditingController _colorHexController;
  late final TextEditingController _startYearController;
  late final TextEditingController _endYearController;

  late AtlasItemType _type;
  late AtlasMapData _mapData;
  late String? _era;
  late int _importance;
  late List<AtlasLinkedVerse> _linkedVerses;
  late Set<int> _selectedCollectionIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _tagsController = TextEditingController(text: item?.tags.join(', ') ?? '');
    _colorHexController = TextEditingController(text: item?.colorHex ?? '');
    _startYearController = TextEditingController(
      text: item?.startDate == null ? '' : '${item!.startDate!.year}',
    );
    _endYearController = TextEditingController(
      text: item?.endDate == null ? '' : '${item!.endDate!.year}',
    );
    _type = item?.type ?? AtlasItemType.place;
    _mapData = item?.mapData ?? AtlasMapData.empty(_type.defaultShapeType);
    _era = item?.era;
    _importance = item?.importance ?? 3;
    _linkedVerses = [...?item?.linkedVerses];
    _selectedCollectionIds = {...?item?.collectionIds};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _colorHexController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  List<AtlasMapShapeType> get _allowedShapeTypes {
    switch (_type) {
      case AtlasItemType.place:
        return const [AtlasMapShapeType.point];
      case AtlasItemType.region:
        return const [AtlasMapShapeType.polygon];
      case AtlasItemType.route:
        return const [AtlasMapShapeType.polyline];
      case AtlasItemType.event:
        return const [
          AtlasMapShapeType.point,
          AtlasMapShapeType.polygon,
        ];
    }
  }

  AtlasMapShapeType get _activeShapeType {
    return _allowedShapeTypes.contains(_mapData.type)
        ? _mapData.type
        : _allowedShapeTypes.first;
  }

  bool get _hasValidGeometry {
    final pointCount = _normalizedMapData.points.length;
    switch (_normalizedMapData.type) {
      case AtlasMapShapeType.point:
        return pointCount >= 1;
      case AtlasMapShapeType.polygon:
        return pointCount >= 3;
      case AtlasMapShapeType.polyline:
        return pointCount >= 2;
    }
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty && _hasValidGeometry;
  }

  String get _geometryHint {
    switch (_activeShapeType) {
      case AtlasMapShapeType.point:
        return 'Ajoute 1 point minimum sur la carte.';
      case AtlasMapShapeType.polygon:
        return 'Ajoute au moins 3 points pour définir une zone.';
      case AtlasMapShapeType.polyline:
        return 'Ajoute au moins 2 points pour définir un trajet.';
    }
  }

  DateTime? _parseYear(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    final year = int.tryParse(text);
    if (year == null) {
      return null;
    }
    return DateTime(year);
  }

  AtlasMapData get _normalizedMapData {
    switch (_activeShapeType) {
      case AtlasMapShapeType.point:
        return _mapData.copyWith(
          type: AtlasMapShapeType.point,
          points: _mapData.points.isEmpty ? const [] : [_mapData.points.first],
        );
      case AtlasMapShapeType.polygon:
        return _mapData.copyWith(type: AtlasMapShapeType.polygon);
      case AtlasMapShapeType.polyline:
        return _mapData.copyWith(type: AtlasMapShapeType.polyline);
    }
  }

  Future<void> _openVerseSelector() async {
    final result = await showDialog<List<AtlasLinkedVerse>>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AtlasVerseSelectorDialog(
          initialSelection: _linkedVerses,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _linkedVerses = result;
    });
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(bibleDatabaseProvider).saveAtlasItem(
          id: widget.initialItem?.id,
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          mapData: _normalizedMapData,
          startDate: _parseYear(_startYearController),
          endDate: _parseYear(_endYearController),
          era: _era,
          tags: _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          importance: _importance,
          colorHex: _colorHexController.text.trim().isEmpty
              ? null
              : _colorHexController.text.trim(),
          verseIds: _linkedVerses.map((verse) => verse.verseId).toList(),
          collectionIds: _selectedCollectionIds.toList(),
        );

    ref.invalidate(atlasItemsProvider);
    ref.invalidate(atlasCollectionsProvider);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _replacePoint(int index, AtlasCoordinate value) {
    final updated = [..._mapData.points];
    while (updated.length <= index) {
      updated.add(const AtlasCoordinate(lat: 31.5, lng: 35.0));
    }
    updated[index] = value;
    setState(() {
      _mapData = _mapData.copyWith(points: updated);
    });
  }

  void _removePoint(int index) {
    final updated = [..._mapData.points]..removeAt(index);
    setState(() {
      _mapData = _mapData.copyWith(points: updated);
    });
  }

  void _addPoint() {
    setState(() {
      _mapData = _mapData.copyWith(
        type: _activeShapeType,
        points: [
          ..._mapData.points,
          const AtlasCoordinate(lat: 31.5, lng: 35.0),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(atlasCollectionsProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF171717),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      title: Text(
        widget.initialItem == null
            ? 'Ajouter à l’atlas'
            : 'Modifier l’élément atlas',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 1100,
        height: 720,
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<AtlasItemType>(
                      key: ValueKey('atlas-type-${_type.name}'),
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type d’élément',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasItemType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        final allowedShapeTypes = switch (value) {
                          AtlasItemType.place => const [AtlasMapShapeType.point],
                          AtlasItemType.region => const [AtlasMapShapeType.polygon],
                          AtlasItemType.route => const [AtlasMapShapeType.polyline],
                          AtlasItemType.event => const [
                              AtlasMapShapeType.point,
                              AtlasMapShapeType.polygon,
                            ],
                        };
                        final nextShapeType = allowedShapeTypes.contains(_mapData.type)
                            ? _mapData.type
                            : allowedShapeTypes.first;
                        setState(() {
                          _type = value;
                          _mapData = _mapData.copyWith(
                            type: nextShapeType,
                            points: nextShapeType == AtlasMapShapeType.point &&
                                    _mapData.points.isNotEmpty
                                ? [_mapData.points.first]
                                : _mapData.points,
                          );
                        });
                      },
                    ),
                    if (_allowedShapeTypes.length > 1) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AtlasMapShapeType>(
                        key: ValueKey(
                          'atlas-shape-${_type.name}-${_activeShapeType.name}',
                        ),
                        initialValue: _activeShapeType,
                        decoration: const InputDecoration(
                          labelText: 'Affichage carte',
                          border: OutlineInputBorder(),
                        ),
                        items: _allowedShapeTypes.map((shapeType) {
                          final label = switch (shapeType) {
                            AtlasMapShapeType.point => 'Point',
                            AtlasMapShapeType.polygon => 'Zone',
                            AtlasMapShapeType.polyline => 'Trajet',
                          };
                          return DropdownMenuItem<AtlasMapShapeType>(
                            value: shapeType,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _mapData = _mapData.copyWith(
                              type: value,
                              points: value == AtlasMapShapeType.point &&
                                      _mapData.points.isNotEmpty
                                  ? [_mapData.points.first]
                                  : _mapData.points,
                            );
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _imageUrlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Image / carte (URL optionnelle)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            key: ValueKey('atlas-era-${_era ?? 'none'}'),
                            initialValue: _era,
                            decoration: const InputDecoration(
                              labelText: 'Époque biblique',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Aucune'),
                              ),
                              ...bibleEras.map((era) {
                                return DropdownMenuItem<String?>(
                                  value: era,
                                  child: Text(era),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _era = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _tagsController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Tags (séparés par des virgules)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startYearController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Début / année',
                              hintText: '-1513 ou 33',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _endYearController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Fin / année',
                              hintText: '-1473 ou 70',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('atlas-importance-$_importance'),
                            initialValue: _importance,
                            decoration: const InputDecoration(
                              labelText: 'Importance',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Urgent')),
                              DropdownMenuItem(value: 2, child: Text('Haute')),
                              DropdownMenuItem(value: 3, child: Text('Normale')),
                              DropdownMenuItem(value: 4, child: Text('Basse')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _importance = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _colorHexController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Couleur carte (hex, optionnel)',
                        hintText: '#34D399',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Collections',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    collectionsAsync.when(
                      data: (collections) {
                        if (collections.isEmpty) {
                          return const Text(
                            'Aucune collection pour l’instant.',
                            style: TextStyle(color: Color(0xFF9CA3AF)),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: collections.map((collection) {
                            final selected =
                                collection.id != null &&
                                _selectedCollectionIds.contains(collection.id);
                            return FilterChip(
                              selected: selected,
                              label: Text(collection.name),
                              onSelected: (_) {
                                if (collection.id == null) {
                                  return;
                                }
                                setState(() {
                                  if (selected) {
                                    _selectedCollectionIds.remove(collection.id);
                                  } else {
                                    _selectedCollectionIds.add(collection.id!);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(strokeWidth: 2),
                      error: (error, stack) => Text(
                        'Erreur collections: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          'Versets associés',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _openVerseSelector,
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Choisir des versets'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_linkedVerses.isEmpty)
                      const Text(
                        'Aucun verset lié pour le moment.',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _linkedVerses.map((verse) {
                          return InputChip(
                            label: Text(
                              '${verse.bookName} ${verse.chapterNumber}:${verse.verseNumber}',
                            ),
                            onDeleted: () {
                              setState(() {
                                _linkedVerses.removeWhere(
                                  (item) => item.verseId == verse.verseId,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carte et géométrie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AtlasMapCanvas(
                      items: const [],
                      editingMapData: _normalizedMapData,
                      editingItemType: _type,
                      onEditingMapDataChanged: (mapData) {
                        setState(() {
                          _mapData = mapData;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _addPoint,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(
                          _activeShapeType == AtlasMapShapeType.point
                              ? 'Initialiser le point'
                              : 'Ajouter un point',
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mapData = AtlasMapData.empty(_activeShapeType);
                          });
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _geometryHint,
                    style: TextStyle(
                      color: _hasValidGeometry
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFFCA5A5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _normalizedMapData.points.length,
                      itemBuilder: (context, index) {
                        final point = _normalizedMapData.points[index];
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                if (_type == AtlasItemType.route)
                                  TextFormField(
                                    key: ValueKey(
                                      'route-label-$index-${point.label ?? ''}',
                                    ),
                                    initialValue: point.label ?? '',
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Étape ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      _replacePoint(
                                        index,
                                        point.copyWith(label: value),
                                      );
                                    },
                                  ),
                                if (_type == AtlasItemType.route)
                                  const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey(
                                          'lat-$index-${point.lat.toStringAsFixed(4)}',
                                        ),
                                        initialValue: point.lat.toStringAsFixed(4),
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: 'Latitude',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final lat = double.tryParse(value);
                                          if (lat == null) {
                                            return;
                                          }
                                          _replacePoint(index, point.copyWith(lat: lat));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey(
                                          'lng-$index-${point.lng.toStringAsFixed(4)}',
                                        ),
                                        initialValue: point.lng.toStringAsFixed(4),
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(
                                          labelText: 'Longitude',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final lng = double.tryParse(value);
                                          if (lng == null) {
                                            return;
                                          }
                                          _replacePoint(index, point.copyWith(lng: lng));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () => _removePoint(index),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _canSave && !_isSaving ? _save : null,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class AtlasVerseSelectorDialog extends ConsumerStatefulWidget {
  final List<AtlasLinkedVerse> initialSelection;

  const AtlasVerseSelectorDialog({
    super.key,
    this.initialSelection = const [],
  });

  @override
  ConsumerState<AtlasVerseSelectorDialog> createState() {
    return _AtlasVerseSelectorDialogState();
  }
}

class _AtlasVerseSelectorDialogState
    extends ConsumerState<AtlasVerseSelectorDialog> {
  BibleBook? _selectedBook;
  int _selectedChapter = 1;
  late final Map<int, AtlasLinkedVerse> _selectedVersesById;

  @override
  void initState() {
    super.initState();
    _selectedVersesById = {
      for (final verse in widget.initialSelection) verse.verseId: verse,
    };
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF171717),
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 40),
      title: const Text(
        'Associer des versets',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 900,
        height: 620,
        child: booksAsync.when(
          data: (books) {
            _selectedBook ??= books.isEmpty ? null : books.first;
            final selectedBook = _selectedBook;
            if (selectedBook == null) {
              return const Text(
                'Aucun livre biblique disponible.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              );
            }

            final versesAsync = ref.watch(
              bibleVersesProvider((selectedBook.id, _selectedChapter)),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BibleBook>(
                        key: ValueKey('atlas-book-${selectedBook.id}'),
                        initialValue: selectedBook,
                        decoration: const InputDecoration(
                          labelText: 'Livre',
                          border: OutlineInputBorder(),
                        ),
                        items: books.map((book) {
                          return DropdownMenuItem(
                            value: book,
                            child: Text(book.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedBook = value;
                            _selectedChapter = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('atlas-chapter-$_selectedChapter'),
                        initialValue: _selectedChapter,
                        decoration: const InputDecoration(
                          labelText: 'Chapitre',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(selectedBook.chaptersCount, (index) {
                          final chapterNumber = index + 1;
                          return DropdownMenuItem(
                            value: chapterNumber,
                            child: Text('$chapterNumber'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedChapter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedVersesById.isNotEmpty) ...[
                  const Text(
                    'Sélection actuelle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedVersesById.values.map((verse) {
                      return InputChip(
                        label: Text(
                          '${verse.bookName} ${verse.chapterNumber}:${verse.verseNumber}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedVersesById.remove(verse.verseId);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: versesAsync.when(
                    data: (verses) {
                      return ListView.separated(
                        itemCount: verses.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final verse = verses[index];
                          final selected = _selectedVersesById.containsKey(verse.id);
                          return CheckboxListTile(
                            value: selected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            title: Text(
                              '${selectedBook.name} $_selectedChapter:${verse.number}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              verse.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBDBDBD),
                                height: 1.4,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedVersesById[verse.id] = AtlasLinkedVerse(
                                    verseId: verse.id,
                                    bookId: selectedBook.id,
                                    bookName: selectedBook.name,
                                    chapterNumber: _selectedChapter,
                                    verseNumber: verse.number,
                                    verseText: verse.text,
                                  );
                                } else {
                                  _selectedVersesById.remove(verse.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Erreur de chargement: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
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
              'Erreur: $error',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _selectedVersesById.values.toList()
                ..sort((a, b) {
                  final byBook = a.bookName.compareTo(b.bookName);
                  if (byBook != 0) {
                    return byBook;
                  }
                  final byChapter = a.chapterNumber.compareTo(b.chapterNumber);
                  if (byChapter != 0) {
                    return byChapter;
                  }
                  return a.verseNumber.compareTo(b.verseNumber);
                }),
            );
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
