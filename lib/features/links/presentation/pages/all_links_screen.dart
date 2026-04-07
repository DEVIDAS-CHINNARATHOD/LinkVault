// lib/features/links/presentation/pages/all_links_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../../groups/presentation/providers/groups_providers.dart';
import '../providers/links_providers.dart';
import '../widgets/link_list_item.dart';
import 'add_edit_link_screen.dart';

class AllLinksScreen extends ConsumerWidget {
  const AllLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(filteredLinksProvider);
    final groups = ref.watch(groupsNotifierProvider).valueOrNull ?? [];
    final activeGroup = ref.watch(activeGroupFilterProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditLinkScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AppSearchBar(
              hintText: 'Search all links...',
              onChanged: (q) =>
                  ref.read(searchQueryProvider.notifier).state = q,
            ),
          ),

          // Group filter chips
          if (groups.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groups.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    // "All" chip
                    return _FilterChip(
                      label: 'All',
                      isSelected: activeGroup == null,
                      onTap: () => ref
                          .read(activeGroupFilterProvider.notifier)
                          .state = null,
                    );
                  }
                  final group = groups[i - 1];
                  return _FilterChip(
                    label: group.name,
                    isSelected: activeGroup == group.id,
                    color: group.color,
                    onTap: () => ref
                        .read(activeGroupFilterProvider.notifier)
                        .state = group.id,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Links list
          Expanded(
            child: links.isEmpty
                ? EmptyState(
                    icon: Icons.link_off_rounded,
                    title: query.isNotEmpty
                        ? 'No results for "$query"'
                        : 'No links yet',
                    subtitle: query.isNotEmpty
                        ? 'Try a different search term'
                        : 'Tap + to add your first link',
                    actionLabel: query.isEmpty ? 'Add Link' : null,
                    onAction: query.isEmpty
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddEditLinkScreen()),
                            )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: links.length,
                    itemBuilder: (context, i) {
                      final link = links[i];
                      return LinkListItem(
                        link: link,
                        onFavoriteToggle: () => ref
                            .read(linksNotifierProvider.notifier)
                            .toggleFavorite(link.id),
                        onOpen: () => ref
                            .read(linksNotifierProvider.notifier)
                            .recordOpen(link.id),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AddEditLinkScreen(existingLink: link)),
                        ),
                        onDelete: () async {
                          final ok = await _confirmDelete(context, link.title);
                          if (ok) {
                            ref
                                .read(linksNotifierProvider.notifier)
                                .delete(link.id);
                          }
                        },
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: i * 40),
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete link?'),
            content: Text('Delete "$title"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final String? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  Color get _accent {
    if (color == null) return AppColors.accent;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withOpacity(0.15) : AppColors.glassBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accent.withOpacity(0.6) : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Sora',
          ),
        ),
      ),
    );
  }
}
