import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../bible/presentation/providers/bible_providers.dart';
import '../providers/talk_providers.dart';
import '../../domain/models/talk_models.dart';
import '../utils/talk_text_highlighting.dart';

class TalkEditorView extends ConsumerStatefulWidget {
  final Talk talk;
  const TalkEditorView({super.key, required this.talk});

  @override
  ConsumerState<TalkEditorView> createState() => _TalkEditorViewState();
}

class _TalkEditorViewState extends ConsumerState<TalkEditorView> {
  late List<TalkHighlightingTextEditingController> _controllers;
  late List<int> _durations;
  late List<FocusNode> _focusNodes;
  late List<TextSelection?> _lastExpandedSelections;

  @override
  void initState() {
    super.initState();
    _controllers = widget.talk.parts
        .map((p) => TalkHighlightingTextEditingController(text: p.content))
        .toList();
    _durations = widget.talk.parts.map((p) => p.durationMinutes).toList();
    _focusNodes = List.generate(widget.talk.parts.length, (_) => FocusNode());
    _lastExpandedSelections = List<TextSelection?>.filled(
      widget.talk.parts.length,
      null,
    );

    for (var index = 0; index < _controllers.length; index++) {
      _controllers[index].addListener(() {
        final selection = _controllers[index].selection;
        if (selection.isValid && !selection.isCollapsed) {
          _lastExpandedSelections[index] = selection;
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < AppBreakpoints.compact;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white54),
          onPressed: () => ref.read(selectedTalkProvider.notifier).state = null,
        ),
        title: const Text(
          'Éditeur de Discours',
          style: TextStyle(fontSize: 14, color: Colors.white54),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 40,
          vertical: compact ? 16 : 20,
        ),
        child: Column(
          children: [
            _buildThemeHeader(compact),
            SizedBox(height: compact ? 36 : 60),
            _buildPartsGrid(screenWidth),
            SizedBox(height: compact ? 40 : 80),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeHeader(bool compact) {
    return Center(
      child: Column(
        children: [
          const Text(
            'THÈME',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.talk.theme,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          _buildTimingSummary(),
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSummary() {
    final allocated = _durations.reduce((a, b) => a + b);
    final total = widget.talk.totalDurationMinutes;
    final isExceeded = allocated > total;
    final isCorrect = allocated == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isExceeded
            ? Colors.red.withValues(alpha: 0.1)
            : isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isExceeded ? Colors.redAccent : Colors.white54,
          ),
          Text(
            '$allocated / $total min',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isExceeded ? Colors.redAccent : Colors.white70,
            ),
          ),
          if (isExceeded) ...[
            Text(
              '(+${allocated - total} min)',
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartsGrid(double screenWidth) {
    int preferredColumns = 2;
    if (widget.talk.numberOfParts == 3 || widget.talk.numberOfParts >= 5) {
      preferredColumns = 3;
    }

    final maxColumnsForWidth = screenWidth >= AppBreakpoints.large
        ? 3
        : screenWidth >= AppBreakpoints.medium
        ? 2
        : 1;
    final crossAxisCount = preferredColumns > maxColumnsForWidth
        ? maxColumnsForWidth
        : preferredColumns;
    final spacing = crossAxisCount == 1 ? 20.0 : 32.0;
    final childAspectRatio = crossAxisCount == 1 ? 0.95 : 0.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: widget.talk.numberOfParts,
      itemBuilder: (context, index) {
        return _buildPartCard(index);
      },
    );
  }

  Widget _buildPartCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PARTIE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildDurationInput(index),
            ],
          ),
          const SizedBox(height: 20),
          _buildHighlightToolbar(index),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFFEFEFEF),
              ),
              decoration: const InputDecoration(
                hintText: 'Saisis le contenu ici...',
                hintStyle: TextStyle(color: Colors.white10),
                border: InputBorder.none,
              ),
              onChanged: (val) => _savePart(index, val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightToolbar(int index) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _toggleHighlight(index),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.22)),
            backgroundColor: primaryColor.withValues(alpha: 0.08),
          ),
          icon: const Icon(Icons.highlight_alt_rounded, size: 16),
          label: const Text('Mettre en évidence'),
        ),
        const Text(
          'Sélectionne un verset, puis clique. Tu peux aussi taper ==texte==.',
          style: TextStyle(fontSize: 11, color: Colors.white30, height: 1.4),
        ),
      ],
    );
  }

  void _savePart(int index, String content) async {
    final part = widget.talk.parts[index];
    await ref.read(bibleDatabaseProvider).updateTalkPart(part.id, content);
  }

  void _toggleHighlight(int index) {
    final controller = _controllers[index];
    final selection =
        controller.selection.isValid && !controller.selection.isCollapsed
        ? controller.selection
        : (_lastExpandedSelections[index] ?? controller.selection);
    final result = toggleTalkHighlight(
      text: controller.text,
      selection: selection,
    );

    controller.value = controller.value.copyWith(
      text: result.text,
      selection: result.selection,
      composing: TextRange.empty,
    );
    _lastExpandedSelections[index] = result.selection.isCollapsed
        ? null
        : result.selection;
    _savePart(index, result.text);
    FocusScope.of(context).requestFocus(_focusNodes[index]);
  }

  Widget _buildDurationInput(int index) {
    return Container(
      width: 80,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: '${_durations[index]}',
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                final d = int.tryParse(val);
                if (d != null) {
                  setState(() {
                    _durations[index] = d;
                  });
                  _savePartDuration(index, d);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'min',
              style: TextStyle(fontSize: 10, color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  void _savePartDuration(int index, int duration) async {
    final part = widget.talk.parts[index];
    await ref
        .read(bibleDatabaseProvider)
        .updateTalkPartDuration(part.id, duration);
  }
}
