import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';
import 'package:jw_study_v2/features/atlas/presentation/providers/atlas_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../domain/models/bible_models.dart';
import '../providers/bible_providers.dart';
import 'sidebar_navigation.dart';
import 'video_player.dart';

class BibleReaderView extends ConsumerWidget {
  const BibleReaderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBook = ref.watch(selectedBookProvider);
    final selectedChapter = ref.watch(selectedChapterProvider);

    if (selectedBook == null || selectedChapter == null) {
      return const SizedBox.shrink();
    }

    final versesAsync = ref.watch(
      bibleVersesProvider((selectedBook.id, selectedChapter)),
    );

    return Container(
      color: const Color(0xFF191919),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1500),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    children: [
                      _BreadcrumbItem(
                        label: 'Étude Biblique',
                        onTap: () {
                          ref.read(selectedBookProvider.notifier).state = null;
                          ref.read(selectedChapterProvider.notifier).state = null;
                        },
                      ),
                      const _BreadcrumbSeparator(),
                      _BreadcrumbItem(
                        label: selectedBook.name,
                        onTap: () {
                          ref.read(selectedChapterProvider.notifier).state = null;
                        },
                      ),
                      const _BreadcrumbSeparator(),
                      Text(
                        'Chapitre $selectedChapter',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '📔',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chapitre $selectedChapter',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedBook.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFACACAC),
                  ),
                ),
                const SizedBox(height: 48),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 40),
                versesAsync.when(
                  data: (verses) => _ChapterLayout(verses: verses),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, st) => Center(
                    child: Text(
                      'Erreur: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterLayout extends StatelessWidget {
  final List<BibleVerse> verses;

  const _ChapterLayout({required this.verses});

  @override
  Widget build(BuildContext context) {
    final splitIndex = verses.length ~/ 2;
    final leftVerses = verses.take(splitIndex).toList(growable: false);
    final rightVerses = verses.skip(splitIndex).toList(growable: false);
    final leftEntries = _collectChapterUserNoteEntries(leftVerses);
    final rightEntries = _collectChapterUserNoteEntries(rightVerses);

    return LayoutBuilder(
      builder: (context, constraints) {
        final versesView = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _VerseList(verses: verses),
          ),
        );

        if (constraints.maxWidth < 1260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              versesView,
              const SizedBox(height: 32),
              _ChapterNotesColumn(
                title: 'Notes gauche',
                rangeLabel: _buildVerseRangeLabel(
                  leftVerses,
                  'Première moitié du chapitre',
                ),
                entries: leftEntries,
              ),
              const SizedBox(height: 20),
              _ChapterNotesColumn(
                title: 'Notes droite',
                rangeLabel: _buildVerseRangeLabel(
                  rightVerses,
                  'Deuxième moitié du chapitre',
                ),
                entries: rightEntries,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: _ChapterNotesColumn(
                title: 'Notes gauche',
                rangeLabel: _buildVerseRangeLabel(
                  leftVerses,
                  'Première moitié du chapitre',
                ),
                entries: leftEntries,
              ),
            ),
            const SizedBox(width: 28),
            Expanded(child: versesView),
            const SizedBox(width: 28),
            SizedBox(
              width: 320,
              child: _ChapterNotesColumn(
                title: 'Notes droite',
                rangeLabel: _buildVerseRangeLabel(
                  rightVerses,
                  'Deuxième moitié du chapitre',
                ),
                entries: rightEntries,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VerseList extends StatelessWidget {
  final List<BibleVerse> verses;

  const _VerseList({required this.verses});

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Text(
          'Aucun verset trouvé pour ce chapitre.',
          style: TextStyle(color: Color(0xFFACACAC)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < verses.length; index++) ...[
          _VerseItem(verse: verses[index]),
          if (index < verses.length - 1) const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BreadcrumbItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFACACAC),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '/',
        style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
      ),
    );
  }
}

class _ChapterUserNoteEntry {
  final BibleVerse verse;
  final UserNote note;

  const _ChapterUserNoteEntry({
    required this.verse,
    required this.note,
  });
}

List<_ChapterUserNoteEntry> _collectChapterUserNoteEntries(
  List<BibleVerse> verses,
) {
  final entries = <_ChapterUserNoteEntry>[];

  for (final verse in verses) {
    final noteCopies = [...verse.userNotes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final note in noteCopies) {
      entries.add(_ChapterUserNoteEntry(verse: verse, note: note));
    }
  }

  return entries;
}

String _buildVerseRangeLabel(List<BibleVerse> verses, String fallback) {
  if (verses.isEmpty) {
    return fallback;
  }

  if (verses.first.number == verses.last.number) {
    return 'Verset ${verses.first.number}';
  }

  return 'Versets ${verses.first.number}-${verses.last.number}';
}

String _noteTypeLabel(UserNoteType type) {
  switch (type) {
    case UserNoteType.image:
      return 'Photo';
    case UserNoteType.video:
      return 'Vidéo';
    case UserNoteType.text:
      return 'Texte';
  }
}

IconData _noteTypeIcon(UserNoteType type) {
  switch (type) {
    case UserNoteType.image:
      return Icons.photo_library_outlined;
    case UserNoteType.video:
      return Icons.play_circle_outline;
    case UserNoteType.text:
      return Icons.note_alt_outlined;
  }
}

Color _noteTypeAccent(UserNoteType type) {
  switch (type) {
    case UserNoteType.image:
      return const Color(0xFF60A5FA);
    case UserNoteType.video:
      return const Color(0xFFF87171);
    case UserNoteType.text:
      return const Color(0xFFFDE047);
  }
}

bool _isRemoteResource(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

bool _isYoutubeVideo(String value) {
  return YoutubePlayerController.convertUrlToId(value.trim()) != null;
}

String? _youtubeThumbnailUrl(String value) {
  final videoId = YoutubePlayerController.convertUrlToId(value.trim());
  if (videoId == null) {
    return null;
  }
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

Future<void> _launchMediaSource(String source) async {
  final uri = _isRemoteResource(source) ? Uri.parse(source) : Uri.file(source);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ChapterNotesColumn extends StatelessWidget {
  final String title;
  final String rangeLabel;
  final List<_ChapterUserNoteEntry> entries;

  const _ChapterNotesColumn({
    required this.title,
    required this.rangeLabel,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rangeLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: const Text(
                'Aucune note enregistrée dans cette partie du chapitre.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF8B8B8B),
                ),
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChapterUserNoteCard(entry: entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterUserNoteCard extends StatelessWidget {
  final _ChapterUserNoteEntry entry;

  const _ChapterUserNoteCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final note = entry.note;
    final accent = _noteTypeAccent(note.noteType);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _UserNoteDetailDialog(entry: entry),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Verset ${entry.verse.number}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                _NoteTypeChip(type: note.noteType),
              ],
            ),
            if (note.hasTitle) ...[
              const SizedBox(height: 12),
              Text(
                note.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (note.noteType == UserNoteType.text)
              Text(
                note.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            if (note.noteType == UserNoteType.image)
              note.hasMediaSource
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NoteImagePreview(
                          source: note.mediaSource!,
                          height: 132,
                        ),
                        if (note.content.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const _MissingMediaState(),
            if (note.noteType == UserNoteType.video)
              note.hasMediaSource
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NoteVideoCardPreview(
                          source: note.mediaSource!,
                          height: 132,
                        ),
                        if (note.content.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const _MissingMediaState(),
          ],
        ),
      ),
    );
  }
}

class _MissingMediaState extends StatelessWidget {
  const _MissingMediaState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Source média introuvable.',
        style: TextStyle(color: Color(0xFFACACAC)),
      ),
    );
  }
}

class _NoteTypeChip extends StatelessWidget {
  final UserNoteType type;

  const _NoteTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final accent = _noteTypeAccent(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_noteTypeIcon(type), size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            _noteTypeLabel(type),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseItem extends ConsumerStatefulWidget {
  final BibleVerse verse;

  const _VerseItem({required this.verse});

  @override
  ConsumerState<_VerseItem> createState() => _VerseItemState();
}

class _VerseItemState extends ConsumerState<_VerseItem> {
  TextSelection? _capturedSelection;

  BibleVerse get verse => widget.verse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${widget.verse.number}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (verseContext) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText.rich(
                      _buildAnnotatedText(),
                      onSelectionChanged: (selection, cause) {
                        _handleSelectionChanged(selection);
                      },
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.white,
                      ),
                    ),
                    if (_capturedSelection != null) ...[
                      const SizedBox(height: 12),
                      _buildSelectionActions(verseContext),
                    ],
                    if (widget.verse.userNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${widget.verse.userNotes.length} note${widget.verse.userNotes.length > 1 ? 's' : ''} dans la colonne latérale',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C7C7C),
                        ),
                      ),
                    ],
                    if (widget.verse.highlights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2413),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFDE047).withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              '${widget.verse.highlights.length} surlignage${widget.verse.highlights.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFDE68A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showHighlightManager(verseContext),
                            icon: const Icon(Icons.format_color_text_outlined),
                            label: const Text('Gérer les surlignages'),
                          ),
                        ],
                      ),
                    ],
                    if (widget.verse.strongTags.isNotEmpty ||
                        widget.verse.atlasLinks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _VerseExtras(verse: widget.verse),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSelectionChanged(TextSelection selection) {
    final normalizedSelection = TextSelection(
      baseOffset: selection.start.clamp(0, verse.text.length).toInt(),
      extentOffset: selection.end.clamp(0, verse.text.length).toInt(),
    );

    if (normalizedSelection.isCollapsed) {
      if (_capturedSelection != null) {
        setState(() {
          _capturedSelection = null;
        });
      }
      return;
    }

    setState(() {
      _capturedSelection = normalizedSelection;
    });
  }

  Widget _buildSelectionActions(BuildContext context) {
    final selection = _capturedSelection;
    if (selection == null || selection.isCollapsed) {
      return const SizedBox.shrink();
    }
    final overlappingHighlights = _findHighlightsOverlappingSelection(selection);

    final colors = [
      {'color': const Color(0xAAFFEB3B), 'hex': '#AAFFEB3B'},
      {'color': const Color(0xAA4CAF50), 'hex': '#AA4CAF50'},
      {'color': const Color(0xAA2196F3), 'hex': '#AA2196F3'},
      {'color': const Color(0xAAE91E63), 'hex': '#AAE91E63'},
      {'color': const Color(0xAA9C27B0), 'hex': '#AA9C27B0'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notes,
                size: 16,
                color: Color(0xFFACACAC),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedExcerpt(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD1D5DB),
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _capturedSelection = null;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                tooltip: 'Fermer',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final color in colors)
                InkWell(
                  onTap: () => _saveHighlight(color['hex']! as String),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color['color']! as Color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _showNoteEditor(context),
                icon: const Icon(Icons.edit_note),
                label: const Text('Ajouter une note'),
              ),
              if (overlappingHighlights.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _removeHighlights(overlappingHighlights),
                  icon: const Icon(Icons.format_clear),
                  label: Text(
                    overlappingHighlights.length == 1
                        ? 'Supprimer le surlignage'
                        : 'Supprimer ${overlappingHighlights.length} surlignages',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFCA5A5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<UserHighlight> _findHighlightsOverlappingSelection(
    TextSelection selection,
  ) {
    return verse.highlights.where((highlight) {
      return selection.start < highlight.endOffset &&
          selection.end > highlight.startOffset;
    }).toList();
  }

  String _selectedExcerpt() {
    final selection = _capturedSelection;
    if (selection == null || selection.isCollapsed) {
      return '';
    }

    final excerpt = verse.text
        .substring(selection.start, selection.end)
        .replaceAll('\n', ' ')
        .trim();

    if (excerpt.length <= 140) {
      return excerpt;
    }

    return '${excerpt.substring(0, 140)}...';
  }

  Future<void> _saveHighlight(String colorHex) async {
    final selection = _capturedSelection;
    if (selection == null || selection.isCollapsed) {
      return;
    }

    await ref.read(bibleDatabaseProvider).saveHighlight(
          verse.id,
          selection.start,
          selection.end,
          colorHex,
        );
    ref.invalidate(bibleVersesProvider);

    if (mounted) {
      setState(() {
        _capturedSelection = null;
      });
    }
  }

  Future<void> _showNoteEditor(BuildContext context) async {
    final selection = _capturedSelection;
    if (selection == null || selection.isCollapsed) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _UserNoteEditorDialog(
          verse: verse,
          capturedSelection: selection,
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        _capturedSelection = null;
      });
    }
  }

  Future<void> _removeHighlights(List<UserHighlight> highlights) async {
    if (highlights.isEmpty) {
      return;
    }

    for (final highlight in highlights) {
      if (highlight.id == null) {
        continue;
      }
      await ref.read(bibleDatabaseProvider).removeHighlight(highlight.id!);
    }

    ref.invalidate(bibleVersesProvider);

    if (mounted) {
      setState(() {
        _capturedSelection = null;
      });
    }
  }

  Future<void> _showHighlightManager(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _VerseHighlightManagerDialog(verse: verse);
      },
    );
  }

  TextSpan _buildAnnotatedText() {
    final text = verse.text;
    if (verse.highlights.isEmpty) {
      return TextSpan(text: text);
    }

    final spans = <InlineSpan>[];
    final offsets = <int>{0, text.length};

    for (final highlight in verse.highlights) {
      offsets.add(highlight.startOffset);
      offsets.add(highlight.endOffset);
    }

    final sortedOffsets = offsets.toList()..sort();

    for (int index = 0; index < sortedOffsets.length - 1; index++) {
      final start = sortedOffsets[index];
      final end = sortedOffsets[index + 1];
      if (start == end) {
        continue;
      }

      final segmentText = text.substring(start, end);
      final activeHighlights = verse.highlights
          .where((highlight) {
            return start >= highlight.startOffset &&
                end <= highlight.endOffset;
          })
          .toList();

      Color? backgroundColor;
      if (activeHighlights.isNotEmpty) {
        final lastHex = activeHighlights.last.colorHex;
        backgroundColor = Color(
          int.parse(lastHex.replaceFirst('#', '0x')),
        ).withValues(alpha: 0.3);
      }

      spans.add(
        TextSpan(
          text: segmentText,
          style: TextStyle(backgroundColor: backgroundColor),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}

class _VerseExtras extends ConsumerWidget {
  final BibleVerse verse;

  const _VerseExtras({required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in verse.strongTags)
          InkWell(
            onTap: () => _showStrongPopup(context, tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '(${tag.strongNumber})',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        for (final atlasLink in verse.atlasLinks)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: InkWell(
              onTap: () => _openAtlasItem(ref, atlasLink),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _atlasLinkColor(atlasLink.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _atlasLinkColor(atlasLink.type).withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 14,
                      color: _atlasLinkColor(atlasLink.type),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        atlasLink.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _atlasLinkColor(atlasLink.type),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _atlasLinkColor(AtlasItemType type) {
    switch (type) {
      case AtlasItemType.place:
        return const Color(0xFFF87171);
      case AtlasItemType.region:
        return const Color(0xFF34D399);
      case AtlasItemType.route:
        return const Color(0xFF60A5FA);
      case AtlasItemType.event:
        return const Color(0xFFFBBF24);
    }
  }

  void _openAtlasItem(WidgetRef ref, AtlasVerseLinkBadge atlasLink) {
    ref.read(atlasSearchQueryProvider.notifier).state = '';
    ref.read(atlasSelectedEraProvider.notifier).state = null;
    ref.read(atlasSelectedCollectionProvider.notifier).state = null;
    ref.read(atlasTypeFilterProvider.notifier).state =
        AtlasItemType.values.toSet();
    ref.read(atlasSelectedItemIdProvider.notifier).state =
        atlasLink.atlasItemId;
    ref.read(navigationProvider.notifier).state = 'atlas';
  }

  void _showStrongPopup(BuildContext context, StrongTag tag) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STRONG ${tag.strongNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFACACAC),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tag.tokenText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (tag.lemma != null)
                  Text(
                    tag.lemma!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFACACAC),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const Divider(height: 32),
                const Text(
                  'DÉFINITION',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recherche de la définition complète...',
                  style: TextStyle(
                    color: Color(0xFFEFEFEF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserNoteEditorDialog extends ConsumerStatefulWidget {
  final BibleVerse verse;
  final TextSelection capturedSelection;

  const _UserNoteEditorDialog({
    required this.verse,
    required this.capturedSelection,
  });

  @override
  ConsumerState<_UserNoteEditorDialog> createState() {
    return _UserNoteEditorDialogState();
  }
}

class _VerseHighlightManagerDialog extends ConsumerStatefulWidget {
  final BibleVerse verse;

  const _VerseHighlightManagerDialog({required this.verse});

  @override
  ConsumerState<_VerseHighlightManagerDialog> createState() {
    return _VerseHighlightManagerDialogState();
  }
}

class _VerseHighlightManagerDialogState
    extends ConsumerState<_VerseHighlightManagerDialog> {
  late List<UserHighlight> _highlights;

  @override
  void initState() {
    super.initState();
    _highlights = [...widget.verse.highlights]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _excerptFor(UserHighlight highlight) {
    final start = highlight.startOffset.clamp(0, widget.verse.text.length);
    final end = highlight.endOffset.clamp(0, widget.verse.text.length);
    if (start >= end) {
      return '';
    }

    final excerpt = widget.verse.text.substring(start, end).trim();
    if (excerpt.length <= 160) {
      return excerpt;
    }

    return '${excerpt.substring(0, 160)}...';
  }

  Color _colorFor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0x')));
  }

  Future<void> _deleteHighlight(UserHighlight highlight) async {
    if (highlight.id == null) {
      return;
    }

    await ref.read(bibleDatabaseProvider).removeHighlight(highlight.id!);
    ref.invalidate(bibleVersesProvider);

    if (!mounted) {
      return;
    }

    setState(() {
      _highlights.removeWhere((item) => item.id == highlight.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF202020),
      title: Text(
        'Surlignages du verset ${widget.verse.number}',
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_highlights.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Il n’y a plus de surlignage sur ce verset.',
                    style: TextStyle(
                      color: Color(0xFFACACAC),
                      height: 1.5,
                    ),
                  ),
                ),
              for (final highlight in _highlights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _colorFor(highlight.colorHex).withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _colorFor(
                                  highlight.colorHex,
                                ).withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _excerptFor(highlight),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Caractères ${highlight.startOffset}-${highlight.endOffset}',
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () => _deleteHighlight(highlight),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Supprimer'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFCA5A5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Fermer',
            style: TextStyle(color: Color(0xFFACACAC)),
          ),
        ),
      ],
    );
  }
}

class _UserNoteEditorDialogState
    extends ConsumerState<_UserNoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _sourceController;
  late final TextEditingController _captionController;
  UserNoteType _selectedType = UserNoteType.text;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _textController = TextEditingController();
    _sourceController = TextEditingController();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _sourceController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_selectedType == UserNoteType.text) {
      return _textController.text.trim().isNotEmpty;
    }
    return _sourceController.text.trim().isNotEmpty;
  }

  String get _selectedExcerpt {
    final start = widget.capturedSelection.start
        .clamp(0, widget.verse.text.length)
        .toInt();
    final end = widget.capturedSelection.end
        .clamp(0, widget.verse.text.length)
        .toInt();
    if (start >= end) {
      return '';
    }

    final excerpt = widget.verse.text.substring(start, end).trim();
    if (excerpt.length <= 140) {
      return excerpt;
    }
    return '${excerpt.substring(0, 140)}...';
  }

  Future<void> _pickMediaFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: _selectedType == UserNoteType.image
          ? FileType.image
          : FileType.video,
    );

    final pickedPath = result?.files.single.path;
    if (pickedPath == null || pickedPath.trim().isEmpty) {
      return;
    }

    _sourceController.text = pickedPath;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveNote() async {
    if (!_canSave || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = _selectedType == UserNoteType.text
        ? _textController.text.trim()
        : _captionController.text.trim();
    final mediaSource = _selectedType.isMedia
        ? _sourceController.text.trim()
        : null;

    await ref.read(bibleDatabaseProvider).saveNote(
          verseId: widget.verse.id,
          start: widget.capturedSelection.start,
          end: widget.capturedSelection.end,
          title: title.isEmpty ? null : title,
          content: content,
          noteType: _selectedType,
          mediaSource:
              mediaSource == null || mediaSource.isEmpty ? null : mediaSource,
        );

    ref.invalidate(bibleVersesProvider);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF202020),
      title: const Text(
        'Ajouter une note',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedExcerpt.isNotEmpty) ...[
                const Text(
                  'Texte sélectionné',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    _selectedExcerpt,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              CupertinoSlidingSegmentedControl<UserNoteType>(
                backgroundColor: const Color(0xFF2B2B2B),
                thumbColor: const Color(0xFF3B3B3B),
                groupValue: _selectedType,
                onValueChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedType = value;
                  });
                },
                children: const {
                  UserNoteType.text: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text('Texte'),
                  ),
                  UserNoteType.image: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text('Photo'),
                  ),
                  UserNoteType.video: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text('Vidéo'),
                  ),
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Titre de la note (optionnel)',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              if (_selectedType == UserNoteType.text)
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Écris ta réflexion sur ce passage...',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: OutlineInputBorder(),
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sourceController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _selectedType == UserNoteType.image
                              ? 'URL ou chemin du fichier image'
                              : 'URL YouTube, URL vidéo ou chemin local',
                          hintStyle: const TextStyle(color: Colors.white24),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickMediaFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choisir'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_sourceController.text.trim().isNotEmpty) ...[
                  if (_selectedType == UserNoteType.image)
                    _NoteImagePreview(
                      source: _sourceController.text.trim(),
                      height: 180,
                    ),
                  if (_selectedType == UserNoteType.video)
                    _NoteVideoCardPreview(
                      source: _sourceController.text.trim(),
                      height: 180,
                    ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Légende ou description (optionnel)',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Color(0xFFACACAC)),
          ),
        ),
        ElevatedButton(
          onPressed: _canSave && !_isSaving ? _saveNote : null,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _UserNoteDetailDialog extends ConsumerWidget {
  final _ChapterUserNoteEntry entry;

  const _UserNoteDetailDialog({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = entry.note;

    return AlertDialog(
      backgroundColor: const Color(0xFF202020),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verset ${entry.verse.number}',
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
                if (note.hasTitle)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NoteTypeChip(type: note.noteType),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.noteType == UserNoteType.text &&
                  note.hasTitle) ...[
                Text(
                  note.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (note.noteType == UserNoteType.text)
                SelectableText(
                  note.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              if (note.noteType == UserNoteType.image)
                note.hasMediaSource
                    ? _NoteImagePreview(
                        source: note.mediaSource!,
                        height: 320,
                        fit: BoxFit.contain,
                      )
                    : const _MissingMediaState(),
              if (note.noteType == UserNoteType.video)
                note.hasMediaSource
                    ? _UserNoteVideoViewer(source: note.mediaSource!)
                    : const _MissingMediaState(),
              if (note.noteType != UserNoteType.text &&
                  note.hasTitle) ...[
                const SizedBox(height: 16),
                const Text(
                  'Titre',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
              if (note.noteType != UserNoteType.text &&
                  note.content.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Légende',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
              if (note.hasMediaSource) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _launchMediaSource(note.mediaSource!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir dans une autre application'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (note.id != null)
          TextButton.icon(
            onPressed: () async {
              await ref.read(bibleDatabaseProvider).removeNote(note.id!);
              ref.invalidate(bibleVersesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF87171),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Fermer',
            style: TextStyle(color: Color(0xFFACACAC)),
          ),
        ),
      ],
    );
  }
}

class _NoteImagePreview extends StatelessWidget {
  final String source;
  final double height;
  final BoxFit fit;

  const _NoteImagePreview({
    required this.source,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final image = _isRemoteResource(source)
        ? Image.network(
            source,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return const _MediaLoadError(label: 'Impossible de charger l’image');
            },
          )
        : Image.file(
            File(source),
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return const _MediaLoadError(label: 'Impossible de charger l’image');
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.2),
        child: image,
      ),
    );
  }
}

class _NoteVideoCardPreview extends StatelessWidget {
  final String source;
  final double height;

  const _NoteVideoCardPreview({
    required this.source,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = _youtubeThumbnailUrl(source);
    final isRemote = _isRemoteResource(source);
    final sourceLabel = _isYoutubeVideo(source)
        ? 'YouTube'
        : isRemote
            ? 'Vidéo en ligne'
            : 'Fichier local';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF121212),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail != null)
              Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            if (thumbnail == null)
              Container(
                color: const Color(0xFF151515),
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 52,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                sourceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaLoadError extends StatelessWidget {
  final String label;

  const _MediaLoadError({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151515),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFACACAC)),
      ),
    );
  }
}

class _UserNoteVideoViewer extends StatelessWidget {
  final String source;

  const _UserNoteVideoViewer({required this.source});

  @override
  Widget build(BuildContext context) {
    if (_isYoutubeVideo(source)) {
      return VerseVideoPlayer(videoUrl: source);
    }

    return _DirectVideoPlayer(source: source);
  }
}

class _DirectVideoPlayer extends StatefulWidget {
  final String source;

  const _DirectVideoPlayer({required this.source});

  @override
  State<_DirectVideoPlayer> createState() => _DirectVideoPlayerState();
}

class _DirectVideoPlayerState extends State<_DirectVideoPlayer> {
  late final VideoPlayerController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = _isRemoteResource(widget.source)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      _controller.addListener(_refresh);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = '$error';
        });
      }
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _MediaLoadError(label: 'Impossible de lire la vidéo');
    }

    if (!_controller.value.isInitialized) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final aspectRatio = _controller.value.aspectRatio == 0
        ? 16 / 9
        : _controller.value.aspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: _togglePlayback,
                  child: VideoPlayer(_controller),
                ),
                if (!_controller.value.isPlaying)
                  Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: _togglePlayback,
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  min: 0,
                  max: _controller.value.duration.inMilliseconds.toDouble(),
                  value: _controller.value.position.inMilliseconds
                      .clamp(
                        0,
                        _controller.value.duration.inMilliseconds,
                      )
                      .toDouble(),
                  onChanged: (value) {
                    _controller.seekTo(
                      Duration(milliseconds: value.round()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
