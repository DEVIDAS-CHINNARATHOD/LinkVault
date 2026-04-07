// lib/features/links/presentation/widgets/link_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../../domain/entities/link_entity.dart';
import '../../../../core/utils/url_utils.dart';

class LinkListItem extends StatelessWidget {
  final LinkEntity link;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  const LinkListItem({
    super.key,
    required this.link,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
    this.onOpen,
  });

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      onOpen?.call();
    } else {
      if (context.mounted) {
        showCopySnackbar(context, 'Could not open URL');
      }
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link.url));
    showCopySnackbar(context, 'URL copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => _openUrl(context),
      onLongPress: () => _showOptions(context),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Favicon
            FaviconWidget(url: link.faviconUrl, size: 36),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Sora',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    UrlUtils.extractDomain(link.url),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontFamily: 'Sora',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (link.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      link.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Sora',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy
                _IconBtn(
                  icon: Icons.copy_rounded,
                  size: 16,
                  onTap: () => _copyUrl(context),
                ),
                // Favorite
                _IconBtn(
                  icon: link.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                  color: link.isFavorite ? AppColors.warning : null,
                  onTap: onFavoriteToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LinkOptionsSheet(
        link: link,
        onEdit: onEdit,
        onDelete: () {
          Navigator.pop(context);
          onDelete?.call();
        },
        onCopy: () {
          Navigator.pop(context);
          _copyUrl(context);
        },
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const _IconBtn({
    required this.icon,
    this.size = 18,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: size, color: color ?? AppColors.textMuted),
      ),
    );
  }
}

class _LinkOptionsSheet extends StatelessWidget {
  final LinkEntity link;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const _LinkOptionsSheet({
    required this.link,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              link.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              UrlUtils.extractDomain(link.url),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.copy_rounded,
              label: 'Copy URL',
              onTap: onCopy,
            ),
            _OptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Link',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.error,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(label,
          style: TextStyle(
            color: c,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Sora',
          )),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
