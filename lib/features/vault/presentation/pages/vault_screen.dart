// lib/features/vault/presentation/pages/vault_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../providers/vault_providers.dart';
import 'add_edit_vault_screen.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultNotifierProvider);
    final isUnlocked = ref.watch(vaultUnlockedProvider);

    if (!isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.vaultGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: AppColors.vault, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Vault'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded, size: 20),
            tooltip: 'Lock Vault',
            onPressed: () {
              ref.read(vaultNotifierProvider.notifier).lock();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: AppSearchBar(
              hintText: 'Search credentials...',
              onChanged: (q) =>
                  ref.read(vaultSearchQueryProvider.notifier).state = q,
            ),
          ),
          Expanded(
            child: vaultAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error))),
              data: (_) {
                final entries = ref.watch(filteredVaultProvider);
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.password_rounded,
                    title: 'Vault is empty',
                    subtitle:
                        'Tap + to securely store your first credential',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _VaultEntryCard(
                    entry: entries[i],
                    index: i,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditVaultScreen()),
        ),
        backgroundColor: AppColors.vault,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Credential',
            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Vault Entry Card ──────────────────────────────────────────────────────────

class _VaultEntryCard extends ConsumerStatefulWidget {
  final VaultEntryEntity entry;
  final int index;

  const _VaultEntryCard({required this.entry, required this.index});

  @override
  ConsumerState<_VaultEntryCard> createState() => _VaultEntryCardState();
}

class _VaultEntryCardState extends ConsumerState<_VaultEntryCard> {
  bool _showPassword = false;
  String? _decryptedPassword;

  void _togglePassword() {
    if (!_showPassword) {
      _decryptedPassword = ref
          .read(vaultNotifierProvider.notifier)
          .decryptPassword(widget.entry);
    }
    setState(() => _showPassword = !_showPassword);
    // Auto-hide after 10 seconds
    if (_showPassword) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) setState(() => _showPassword = false);
      });
    }
  }

  void _copyUsername(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.entry.username));
    _showSnack(context, 'Username copied');
  }

  void _copyPassword(BuildContext context) {
    final pass = ref
        .read(vaultNotifierProvider.notifier)
        .decryptPassword(widget.entry);
    Clipboard.setData(ClipboardData(text: pass));
    _showSnack(context, 'Password copied');
    // Clear clipboard after 30s for security
    Future.delayed(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Text(msg),
        ]),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.vault.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.vaultGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    entry.appName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.vault,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Sora',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.appName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Sora',
                        )),
                    if (entry.notes.isNotEmpty)
                      Text(entry.notes,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'Sora',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Edit / Delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 18),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddEditVaultScreen(existingEntry: entry)),
                    );
                  } else if (val == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Sora',
                              fontSize: 14))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(
                              color: AppColors.error,
                              fontFamily: 'Sora',
                              fontSize: 14))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Username row
          _CredRow(
            label: 'Username',
            value: entry.username,
            onCopy: () => _copyUsername(context),
          ),

          const SizedBox(height: 10),

          // Password row
          _CredRow(
            label: 'Password',
            value: _showPassword ? (_decryptedPassword ?? '•••') : '••••••••••',
            isPassword: true,
            showPassword: _showPassword,
            onToggle: _togglePassword,
            onCopy: () => _copyPassword(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 60));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete credential?'),
        content: Text(
            'This will permanently delete "${widget.entry.appName}" from your vault.'),
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
    );
    if (confirm == true) {
      ref
          .read(vaultNotifierProvider.notifier)
          .delete(widget.entry.id);
    }
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPassword;
  final bool showPassword;
  final VoidCallback? onToggle;
  final VoidCallback onCopy;

  const _CredRow({
    required this.label,
    required this.value,
    this.isPassword = false,
    this.showPassword = false,
    this.onToggle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Sora',
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Sora',
                  letterSpacing: isPassword && !showPassword ? 3 : 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isPassword && onToggle != null)
          IconButton(
            icon: Icon(
              showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            onPressed: onToggle,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        IconButton(
          icon: const Icon(Icons.copy_rounded,
              size: 16, color: AppColors.textMuted),
          onPressed: onCopy,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
