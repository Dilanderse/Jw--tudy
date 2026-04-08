import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../domain/models/bible_models.dart';
import '../providers/bible_providers.dart';
import 'book_intro_video_panel.dart';

// ... rest of the file ...

class BookSelectionGrid extends ConsumerStatefulWidget {
  const BookSelectionGrid({super.key});

  @override
  ConsumerState<BookSelectionGrid> createState() => _BookSelectionGridState();
}

class _BookSelectionGridState extends ConsumerState<BookSelectionGrid> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < AppBreakpoints.compact;
    final horizontalPadding = compact ? 20.0 : 60.0;
    final verticalPadding = compact ? 28.0 : 60.0;

    return booksAsync.when(
      data: (books) {
        final filteredBooks = books
            .where(
              (b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        final oldTestament = filteredBooks
            .where((b) => b.testament == Testament.old)
            .toList();
        final newTestament = filteredBooks
            .where((b) => b.testament == Testament.newTestament)
            .toList();

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 28 : 40),
              child: Row(
                children: const [
                  Text(
                    'Étude Biblique',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFACACAC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Bibliothèque',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: compact ? 34 : null),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explorez et étudiez les Écritures Saintes',
              style: TextStyle(color: Color(0xFFACACAC), fontSize: 16),
            ),
            SizedBox(height: compact ? 32 : 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 12),
                        const Text(
                          'Reprendre la lecture',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Continuez votre étude là où vous l’avez laissée.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Ouvrir',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reprendre la lecture',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Continuez votre étude là où vous l’avez laissée.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Ouvrir',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: compact ? 32 : 48),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFFACACAC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Rechercher un livre...',
                        hintStyle: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 40 : 60),
            if (oldTestament.isNotEmpty) ...[
              _BookSection(
                title: 'Écritures Hébraïques et Araméennes',
                subtitle: 'Ancien Testament',
                books: oldTestament,
              ),
              SizedBox(height: compact ? 48 : 80),
            ],
            if (newTestament.isNotEmpty) ...[
              _BookSection(
                title: 'Écritures Grecques Chrétiennes',
                subtitle: 'Nouveau Testament',
                books: newTestament,
              ),
              SizedBox(height: compact ? 48 : 100),
            ],
            if (filteredBooks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'Aucun livre trouvé.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
    );
  }
}

class _BookSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<BibleBook> books;

  const _BookSection({
    required this.title,
    required this.subtitle,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 80,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) => _BookItem(book: books[index]),
        ),
      ],
    );
  }
}

class _BookItem extends ConsumerWidget {
  final BibleBook book;

  const _BookItem({required this.book});

  String _getCategory() {
    // Basic mapping for categories based on book sort order
    final id = book.sortOrder;
    if (id <= 5) return 'Pentateuque';
    if (id <= 17) return 'Histoire';
    if (id <= 22) return 'Poésie';
    if (id <= 39) return 'Prophètes';
    if (id <= 43) return 'Évangiles';
    if (id == 44) return 'Histoire';
    if (id <= 57) return 'Lettres';
    if (id <= 65) return 'Lettres';
    return 'Prophétie';
  }

  Color _getCategoryColor() {
    final cat = _getCategory();
    switch (cat) {
      case 'Pentateuque':
        return Colors.teal.withValues(alpha: 0.2);
      case 'Histoire':
        return Colors.orange.withValues(alpha: 0.2);
      case 'Poésie':
        return Colors.purple.withValues(alpha: 0.2);
      case 'Prophètes':
        return Colors.red.withValues(alpha: 0.2);
      case 'Évangiles':
        return Colors.blue.withValues(alpha: 0.2);
      case 'Lettres':
        return Colors.green.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Color _getTextColor() {
    final cat = _getCategory();
    switch (cat) {
      case 'Pentateuque':
        return Colors.tealAccent;
      case 'Histoire':
        return Colors.orangeAccent;
      case 'Poésie':
        return Colors.purpleAccent;
      case 'Prophètes':
        return Colors.redAccent;
      case 'Évangiles':
        return Colors.blueAccent;
      case 'Lettres':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(selectedBookProvider.notifier).state = book;
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              book.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _getCategory(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor().withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChapterSelectionGrid extends ConsumerWidget {
  const ChapterSelectionGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBook = ref.watch(selectedBookProvider);

    if (selectedBook == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.medium;
        final contentPadding = compact
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 28)
            : const EdgeInsets.fromLTRB(60, 60, 40, 60);
        final chapterContent = SingleChildScrollView(
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _BreadcrumbLink(
                      label: 'Étude Biblique',
                      onTap: () =>
                          ref.read(selectedBookProvider.notifier).state = null,
                    ),
                    const _BreadcrumbSep(),
                    Text(
                      selectedBook.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Text('📘', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                selectedBook.name,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: compact ? 34 : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sélectionnez un chapitre pour commencer la lecture',
                style: TextStyle(color: Color(0xFFACACAC), fontSize: 16),
              ),
              SizedBox(height: compact ? 32 : 48),
              Divider(color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 32),
              const Text(
                'Chapitres',
                style: TextStyle(
                  color: Color(0xFFACACAC),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 60,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: selectedBook.chaptersCount,
                itemBuilder: (context, index) {
                  final chapterNum = index + 1;
                  return InkWell(
                    onTap: () {
                      ref.read(selectedChapterProvider.notifier).state =
                          chapterNum;
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        '$chapterNum',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (compact) ...[
                const SizedBox(height: 28),
                BookIntroVideoPanel(
                  bookId: selectedBook.id,
                  bookName: selectedBook.name,
                ),
              ],
            ],
          ),
        );

        if (compact) {
          return chapterContent;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: chapterContent),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 360,
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: BookIntroVideoPanel(
                  bookId: selectedBook.id,
                  bookName: selectedBook.name,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BreadcrumbLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BreadcrumbLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC)),
        ),
      ),
    );
  }
}

class _BreadcrumbSep extends StatelessWidget {
  const _BreadcrumbSep();
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
