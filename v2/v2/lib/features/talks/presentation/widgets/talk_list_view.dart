import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../bible/presentation/providers/bible_providers.dart';
import '../providers/talk_providers.dart';
import '../../domain/models/talk_models.dart';

class TalkListView extends ConsumerWidget {
  const TalkListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talksAsync = ref.watch(talksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.compact;
          final horizontalPadding = compact ? 20.0 : 40.0;
          final verticalPadding = compact ? 28.0 : 60.0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎙️ Mes Discours',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTalkDialog(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouveau Discours'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🎙️ Mes Discours',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateTalkDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nouveau Discours'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: compact ? 28 : 48),
                Expanded(
                  child: talksAsync.when(
                    data: (talks) => talks.isEmpty
                        ? _buildEmptyState()
                        : _buildTalkGrid(
                            context,
                            ref,
                            talks,
                            constraints.maxWidth,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Erreur: $err')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('🎙️', style: TextStyle(fontSize: 64)),
          SizedBox(height: 24),
          Text(
            'Aucun discours pour le moment',
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 8),
          Text(
            'Clique sur le bouton "Nouveau" pour commencer',
            style: TextStyle(fontSize: 14, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildTalkGrid(
    BuildContext context,
    WidgetRef ref,
    List<Talk> talks,
    double availableWidth,
  ) {
    final compact = availableWidth < AppBreakpoints.compact;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 360 : 320,
        crossAxisSpacing: compact ? 16 : 24,
        mainAxisSpacing: compact ? 16 : 24,
        childAspectRatio: compact ? 1.2 : 1.5,
      ),
      itemCount: talks.length,
      itemBuilder: (context, index) {
        final talk = talks[index];
        return InkWell(
          onTap: () {
            ref.read(selectedTalkProvider.notifier).state = talk;
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talk.theme,
                  style: TextStyle(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${talk.numberOfParts} parties • ${talk.totalDurationMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(talk.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateTalkDialog(BuildContext context, WidgetRef ref) {
    String theme = '';
    int parts = 4;
    int totalDuration = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Nouveau Discours'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Thème du discours',
                      hintText: 'ex: Pourquoi aimer Dieu ?',
                    ),
                    onChanged: (val) => theme = val,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      const Text(
                        'Nombre de parties:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      DropdownButton<int>(
                        value: parts,
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: [2, 3, 4, 5, 6].map((i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(
                              i.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => parts = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      const Text(
                        'Durée totale (min):',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: '30',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onChanged: (val) {
                            final d = int.tryParse(val);
                            if (d != null) totalDuration = d;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (theme.trim().isNotEmpty) {
                  final navigator = Navigator.of(context);
                  await ref
                      .read(bibleDatabaseProvider)
                      .createTalk(theme.trim(), parts, totalDuration);
                  ref.invalidate(talksProvider);
                  navigator.pop();
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
