// lib/features/groups/presentation/pages/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../../../links/presentation/providers/links_providers.dart';
import '../../domain/entities/group_entity.dart';
import '../providers/groups_providers.dart';
import 'group_links_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsNotifierProvider);
    final allLinks = ref.watch(linksNotifierProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateGroupDialog(context, ref),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_outlined,
              title: 'No groups yet',
              subtitle: 'Create groups to organize your links',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              final count = allLinks.where((l) => l.groupId == group.id).length;
              return _GroupCard(
                group: group,
                linkCount: count,
              ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).scale(
                    begin: const Offset(0.92, 0.92),
                    delay: Duration(milliseconds: i * 60),
                  );
            },
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreateGroupDialog(
        onCreate: (name, icon, color) {
          ref.read(groupsNotifierProvider.notifier).create(
                name: name,
                icon: icon,
                color: color,
              );
        },
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final GroupEntity group;
  final int linkCount;

  const _GroupCard({required this.group, required this.linkCount});

  Color get _color {
    try {
      return Color(int.parse(group.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: _color.withOpacity(0.07),
      borderColor: _color.withOpacity(0.2),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupLinksScreen(group: group),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFromName(group.icon),
              color: _color,
              size: 22,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sora',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$linkCount ${linkCount == 1 ? 'link' : 'links'}',
                style: TextStyle(
                  color: _color.withOpacity(0.7),
                  fontSize: 12,
                  fontFamily: 'Sora',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFromName(String name) {
    const map = {
      'code': Icons.code_rounded,
      'api': Icons.api_rounded,
      'tools': Icons.build_rounded,
      'description': Icons.description_rounded,
      'palette': Icons.palette_rounded,
      'article': Icons.article_rounded,
      'folder': Icons.folder_rounded,
      'link': Icons.link_rounded,
      'cloud': Icons.cloud_rounded,
      'star': Icons.star_rounded,
      'lock': Icons.lock_rounded,
      'video': Icons.play_circle_rounded,
      'social': Icons.people_rounded,
    };
    return map[name] ?? Icons.folder_rounded;
  }
}

// ── Create Group Dialog ────────────────────────────────────────────────────────

class _CreateGroupDialog extends StatefulWidget {
  final Function(String name, String icon, String color) onCreate;
  const _CreateGroupDialog({required this.onCreate});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'folder';
  String _selectedColor = '#3B82F6';

  static const _icons = [
    ('folder', Icons.folder_rounded),
    ('code', Icons.code_rounded),
    ('api', Icons.api_rounded),
    ('tools', Icons.build_rounded),
    ('description', Icons.description_rounded),
    ('palette', Icons.palette_rounded),
    ('article', Icons.article_rounded),
    ('cloud', Icons.cloud_rounded),
    ('star', Icons.star_rounded),
    ('video', Icons.play_circle_rounded),
    ('social', Icons.people_rounded),
  ];

  static const _colors = [
    '#3B82F6', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#EC4899', '#06B6D4', '#6366F1',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Group',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sora',
                )),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontFamily: 'Sora'),
              decoration: const InputDecoration(hintText: 'Group name'),
            ),
            const SizedBox(height: 20),
            const Text('Icon',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((e) {
                final selected = _selectedIcon == e.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = e.$1),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentGlow : AppColors.glassBase,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.glassBorder,
                      ),
                    ),
                    child: Icon(e.$2,
                        color: selected ? AppColors.accent : AppColors.textMuted,
                        size: 18),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _colors.map((c) {
                final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
                final selected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.textPrimary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      widget.onCreate(
                        _nameCtrl.text.trim(),
                        _selectedIcon,
                        _selectedColor,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
