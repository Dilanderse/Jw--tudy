import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<String>((ref) => 'bible');

class AppNavigationItem {
  final String module;
  final String label;
  final String shortLabel;
  final String emoji;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavigationItem({
    required this.module,
    required this.label,
    required this.shortLabel,
    required this.emoji,
    required this.icon,
    required this.selectedIcon,
  });
}

const appNavigationItems = <AppNavigationItem>[
  AppNavigationItem(
    module: 'bible',
    label: 'Etude Biblique',
    shortLabel: 'Bible',
    emoji: '📔',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
  ),
  AppNavigationItem(
    module: 'chronology',
    label: 'Chronologie',
    shortLabel: 'Chrono',
    emoji: '⏳',
    icon: Icons.timeline_outlined,
    selectedIcon: Icons.timeline,
  ),
  AppNavigationItem(
    module: 'talks',
    label: 'Discours',
    shortLabel: 'Discours',
    emoji: '🎙️',
    icon: Icons.mic_none_rounded,
    selectedIcon: Icons.mic_rounded,
  ),
  AppNavigationItem(
    module: 'atlas',
    label: 'Atlas Biblique',
    shortLabel: 'Atlas',
    emoji: '🗺️',
    icon: Icons.public_outlined,
    selectedIcon: Icons.public,
  ),
  AppNavigationItem(
    module: 'favorites',
    label: 'Mes Favoris',
    shortLabel: 'Favoris',
    emoji: '⭐',
    icon: Icons.star_border_rounded,
    selectedIcon: Icons.star_rounded,
  ),
];

class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeModule = ref.watch(navigationProvider);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('📖', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'JW Workspace',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final item in appNavigationItems)
            _NavItem(
              emoji: item.emoji,
              label: item.label,
              isActive: activeModule == item.module,
              onTap: () => _selectModule(ref, item.module),
            ),
          const Spacer(),
          _NavItem(
            emoji: '⚙️',
            label: 'Parametres',
            isActive: false,
            onTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class BottomNavigation extends ConsumerWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeModule = ref.watch(navigationProvider);
    final selectedIndex = appNavigationItems.indexWhere(
      (item) => item.module == activeModule,
    );

    return NavigationBar(
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        _selectModule(ref, appNavigationItems[index].module);
      },
      destinations: [
        for (final item in appNavigationItems)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.shortLabel,
          ),
      ],
    );
  }
}

void _selectModule(WidgetRef ref, String module) {
  ref.read(navigationProvider.notifier).state = module;
}

class _NavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? Colors.white : const Color(0xFFACACAC),
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
