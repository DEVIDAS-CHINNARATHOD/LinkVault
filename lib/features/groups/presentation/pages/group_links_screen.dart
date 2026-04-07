// lib/features/groups/presentation/pages/group_links_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../../links/presentation/pages/add_edit_link_screen.dart';
import '../../../links/presentation/providers/links_providers.dart';
import '../../../links/presentation/widgets/link_list_item.dart';
import '../../domain/entities/group_entity.dart';

class GroupLinksScreen extends ConsumerWidget {
  final GroupEntity group;
  const GroupLinksScreen({super.key, required this.group});

  Color get _color {
    try {
      return Color(int.parse(group.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLinks = ref.watch(linksNotifierProvider).valueOrNull ?? [];
    final groupLinks =
        allLinks.where((l) => l.groupId == group.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(group.name),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${groupLinks.length}',
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sora',
                ),
              ),
            ),
          ],
        ),
      ),
      body: groupLinks.isEmpty
          ? EmptyState(
              icon: Icons.link_off_rounded,
              title: 'No links in ${group.name}',
              subtitle: 'Add links and assign them to this group',
              actionLabel: 'Add Link',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditLinkScreen()),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: groupLinks.length,
              itemBuilder: (context, i) {
                final link = groupLinks[i];
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
                        builder: (_) => AddEditLinkScreen(existingLink: link)),
                  ),
                  onDelete: () => ref
                      .read(linksNotifierProvider.notifier)
                      .delete(link.id),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
              },
            ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditLinkScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
