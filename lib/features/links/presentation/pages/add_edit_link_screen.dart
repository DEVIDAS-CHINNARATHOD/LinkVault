// lib/features/links/presentation/pages/add_edit_link_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../services/metadata_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../../../groups/presentation/providers/groups_providers.dart';
import '../../domain/entities/link_entity.dart';
import '../providers/links_providers.dart';

class AddEditLinkScreen extends ConsumerStatefulWidget {
  final LinkEntity? existingLink;

  const AddEditLinkScreen({super.key, this.existingLink});

  @override
  ConsumerState<AddEditLinkScreen> createState() => _AddEditLinkScreenState();
}

class _AddEditLinkScreenState extends ConsumerState<AddEditLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedGroupId;
  String? _faviconUrl;
  bool _isFetchingMeta = false;
  bool _isSaving = false;
  String? _duplicateError;
  String? _suggestedGroup;

  bool get _isEdit => widget.existingLink != null;

  @override
  void initState() {
    super.initState();
    final link = widget.existingLink;
    _urlCtrl = TextEditingController(text: link?.url ?? '');
    _titleCtrl = TextEditingController(text: link?.title ?? '');
    _descCtrl = TextEditingController(text: link?.description ?? '');
    _selectedGroupId = link?.groupId;
    _faviconUrl = link?.faviconUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    final rawUrl = _urlCtrl.text.trim();
    final url = UrlUtils.normalize(rawUrl);
    if (url == null) return;
    _urlCtrl.text = url;

    setState(() => _isFetchingMeta = true);
    final meta = await MetadataService.fetch(url);
    setState(() {
      _isFetchingMeta = false;
      if (meta.title != null && _titleCtrl.text.isEmpty) {
        _titleCtrl.text = meta.title!;
      }
      if (meta.description != null && _descCtrl.text.isEmpty) {
        _descCtrl.text = meta.description!;
      }
      _faviconUrl = meta.favicon;

      // Auto-suggest group
      final suggestion =
          UrlUtils.suggestGroup(url, AppConstants.urlKeywordGroups);
      if (suggestion != null && _selectedGroupId == null) {
        _suggestedGroup = suggestion;
      }
    });
  }

  void _applySuggestedGroup(String groupName) {
    final repo = ref.read(groupsRepositoryProvider);
    final group = repo.getByName(groupName);
    if (group != null) {
      setState(() {
        _selectedGroupId = group.id;
        _suggestedGroup = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final url = UrlUtils.normalize(_urlCtrl.text.trim());
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    // Duplicate check
    final isDup = ref
        .read(linksNotifierProvider.notifier)
        .isDuplicate(url, excludeId: widget.existingLink?.id);
    if (isDup) {
      setState(() => _duplicateError = 'This link already exists in your vault.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(linksNotifierProvider.notifier);
      if (_isEdit) {
        final updated = widget.existingLink!.copyWith(
          title: _titleCtrl.text.trim(),
          url: url,
          groupId: _selectedGroupId,
          faviconUrl: _faviconUrl,
        );
        // Use copyWith with description manually
        await notifier.update(LinkEntity(
          id: updated.id,
          title: updated.title,
          url: updated.url,
          description: _descCtrl.text.trim(),
          groupId: updated.groupId,
          isFavorite: updated.isFavorite,
          clickCount: updated.clickCount,
          lastOpenedAt: updated.lastOpenedAt,
          createdAt: updated.createdAt,
          updatedAt: DateTime.now(),
          faviconUrl: updated.faviconUrl,
        ));
      } else {
        await notifier.create(
          title: _titleCtrl.text.trim(),
          url: url,
          description: _descCtrl.text.trim(),
          groupId: _selectedGroupId,
          faviconUrl: _faviconUrl,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsNotifierProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Link' : 'Add Link'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Sora',
                    )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── URL Field ─────────────────────────────────────────────────
              _FieldLabel(label: 'URL *'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _urlCtrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://example.com',
                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        errorText: _duplicateError,
                      ),
                      onChanged: (_) {
                        if (_duplicateError != null) {
                          setState(() => _duplicateError = null);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'URL is required';
                        if (UrlUtils.normalize(v.trim()) == null) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    onTap: _fetchMetadata,
                    child: _isFetchingMeta
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accent, size: 20),
                  ),
                ],
              ).animate().fadeIn(delay: 50.ms),

              // Suggested group chip
              if (_suggestedGroup != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _applySuggestedGroup(_suggestedGroup!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Suggested group: $_suggestedGroup — tap to apply',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontFamily: 'Sora',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Title Field ───────────────────────────────────────────────
              const _FieldLabel(label: 'Title *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Sora',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'My awesome link',
                  prefixIcon: Icon(Icons.title_rounded, size: 18),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Description Field ─────────────────────────────────────────
              const _FieldLabel(label: 'Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Sora',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Optional notes about this link...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(Icons.notes_rounded, size: 18),
                  ),
                  alignLabelWithHint: true,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Group Selector ────────────────────────────────────────────
              const _FieldLabel(label: 'Group'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // No group
                  _GroupChip(
                    label: 'None',
                    isSelected: _selectedGroupId == null,
                    onTap: () => setState(() => _selectedGroupId = null),
                    color: AppColors.textMuted,
                  ),
                  ...groups.map((g) => _GroupChip(
                        label: g.name,
                        isSelected: _selectedGroupId == g.id,
                        onTap: () => setState(() => _selectedGroupId = g.id),
                        color: _hexToColor(g.color),
                      )),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Sora',
          letterSpacing: 0.5,
        ));
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _GroupChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.glassBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Sora',
          ),
        ),
      ),
    );
  }
}
