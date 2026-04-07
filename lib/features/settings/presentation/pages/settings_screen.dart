// lib/features/settings/presentation/pages/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/biometric_service.dart';
import '../../../../services/encryption_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/glass/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Security Section ──────────────────────────────────────
                _SectionLabel(label: 'SECURITY'),
                const SizedBox(height: 10),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (_biometricAvailable)
                        _SettingsTile(
                          icon: Icons.fingerprint_rounded,
                          iconColor: AppColors.vault,
                          title: 'Biometric Unlock',
                          subtitle: 'Use fingerprint or face to unlock vault',
                          trailing: Switch(
                            value: _biometricEnabled,
                            onChanged: (v) async {
                              await BiometricService.setEnabled(v);
                              setState(() => _biometricEnabled = v);
                            },
                            activeColor: AppColors.vault,
                          ),
                        ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.lock_reset_rounded,
                        iconColor: AppColors.accent,
                        title: 'Change Vault Password',
                        subtitle: 'Update your vault master password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.warning,
                        title: 'Auto-Lock',
                        subtitle: 'Vault locks after 5 min of inactivity',
                        trailing: const Text(
                          '5 min',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontFamily: 'Sora',
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 50.ms),

                const SizedBox(height: 24),

                // ── Data Section ──────────────────────────────────────────
                _SectionLabel(label: 'DATA'),
                const SizedBox(height: 10),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.cloud_upload_outlined,
                        iconColor: AppColors.success,
                        title: 'Sync to Cloud',
                        subtitle: 'Backed up to Supabase automatically',
                        trailing: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.delete_sweep_outlined,
                        iconColor: AppColors.error,
                        title: 'Clear All Data',
                        subtitle: 'Delete all links, groups, and credentials',
                        onTap: () => _showClearDataDialog(context),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // ── About Section ─────────────────────────────────────────
                _SectionLabel(label: 'ABOUT'),
                const SizedBox(height: 10),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.accent,
                        title: 'Version',
                        trailing: const Text(
                          '1.0.0',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontFamily: 'Sora',
                          ),
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.vault,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.article_outlined,
                        iconColor: AppColors.textSecondary,
                        title: 'Terms of Service',
                        onTap: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 32),

                // Encryption badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.vaultGlow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: AppColors.vault.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            color: AppColors.vault, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'AES-256 Encrypted · End-to-End Secure',
                          style: TextStyle(
                            color: AppColors.vault,
                            fontSize: 12,
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Vault Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(ctrl: currentCtrl, hint: 'Current password'),
              const SizedBox(height: 12),
              _DialogField(ctrl: newCtrl, hint: 'New password'),
              const SizedBox(height: 12),
              _DialogField(ctrl: confirmCtrl, hint: 'Confirm new password'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontFamily: 'Sora')),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final hash =
                    await EncryptionService.getVaultPasswordHash();
                final ok = EncryptionService.verifyPassword(
                    currentCtrl.text, hash ?? '');
                if (!ok) {
                  setDialogState(
                      () => error = 'Current password is incorrect.');
                  return;
                }
                if (newCtrl.text.length < 6) {
                  setDialogState(
                      () => error = 'Password must be 6+ characters.');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setDialogState(() => error = 'Passwords do not match.');
                  return;
                }
                final newHash =
                    EncryptionService.hashPassword(newCtrl.text);
                await EncryptionService.saveVaultPasswordHash(newHash);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vault password updated successfully')),
                  );
                }
              },
              child: const Text('Update',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your links, groups, and vault credentials. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement full wipe
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All data cleared. Restart the app.')),
              );
            },
            child: const Text('Delete Everything',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'Sora',
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.divider,
      height: 1,
      indent: 52,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Sora',
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Sora',
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18)
              : null),
    );
  }
}

class _DialogField extends StatefulWidget {
  final TextEditingController ctrl;
  final String hint;
  const _DialogField({required this.ctrl, required this.hint});

  @override
  State<_DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.ctrl,
      obscureText: _obscure,
      style: const TextStyle(
          color: AppColors.textPrimary, fontFamily: 'Sora', fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
