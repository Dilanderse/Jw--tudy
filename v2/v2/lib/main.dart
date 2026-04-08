import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:media_kit/media_kit.dart'; // Added for MediaKit.ensureInitialized
import 'core/layout/app_breakpoints.dart';
import 'core/app_theme.dart';
import 'features/atlas/presentation/widgets/atlas_studio_view.dart';
import 'features/bible/presentation/widgets/sidebar_navigation.dart';
import 'features/bible/presentation/widgets/bible_grids.dart';
import 'features/bible/presentation/widgets/bible_reader_view.dart';
import 'features/bible/presentation/providers/bible_providers.dart';
import 'features/talks/presentation/providers/talk_providers.dart';
import 'features/talks/presentation/widgets/talk_list_view.dart';
import 'features/talks/presentation/widgets/talk_editor_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // Added MediaKit initialization
  VideoPlayerMediaKit.ensureInitialized(linux: true);
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'JW Study v2',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: JWStudyApp()));
}

class JWStudyApp extends StatelessWidget {
  const JWStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JW Study v2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeModule = ref.watch(navigationProvider);
    final selectedBook = ref.watch(selectedBookProvider);
    final selectedChapter = ref.watch(selectedChapterProvider);
    final selectedTalk = ref.watch(selectedTalkProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useBottomNavigation = screenWidth < AppBreakpoints.medium;
    final content = Container(
      color: Theme.of(context).colorScheme.surface,
      child: _buildBody(
        activeModule,
        selectedBook != null,
        selectedChapter != null,
        selectedTalk != null,
        ref,
      ),
    );

    return Scaffold(
      body: useBottomNavigation
          ? content
          : Row(
              children: [
                const SidebarNavigation(),
                Expanded(child: content),
              ],
            ),
      bottomNavigationBar: useBottomNavigation
          ? const BottomNavigation()
          : null,
    );
  }

  Widget _buildBody(
    String activeModule,
    bool hasBook,
    bool hasChapter,
    bool hasTalk,
    WidgetRef ref,
  ) {
    if (activeModule == 'talks') {
      if (hasTalk) {
        return TalkEditorView(talk: ref.watch(selectedTalkProvider)!);
      }
      return const TalkListView();
    }

    if (activeModule == 'atlas') {
      return const AtlasStudioView();
    }

    if (activeModule != 'bible') {
      return Center(
        child: Text(
          'Module: ${activeModule.toUpperCase()} (Bientôt disponible)',
          style: const TextStyle(fontSize: 24, color: Colors.white30),
        ),
      );
    }

    if (hasBook && hasChapter) {
      return const BibleReaderView();
    } else if (hasBook) {
      return const ChapterSelectionGrid();
    } else {
      return const BookSelectionGrid();
    }
  }
}
