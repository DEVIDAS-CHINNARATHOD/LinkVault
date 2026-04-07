// lib/features/vault/presentation/pages/add_edit_vault_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../providers/vault_providers.dart';

class AddEditVaultScreen extends ConsumerStatefulWidget {
  final VaultEntryEntity? existingEntry;
  const AddEditVaultScreen({super.key, this.existingEntry});

  @override
  ConsumerState<AddEditVaultScreen> createState() =>
      _AddEditVaultScreenState();
}

class _AddEditVaultScreenState extends ConsumerState<AddEditVaultScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _appCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _notesCtrl;
  bool _obscurePass = true;
  bool _isSaving = false;

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _appCtrl = TextEditingController(text: e?.appName ?? '');
    _userCtrl = TextEditingController(text: e?.username ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    // Decrypt existing password for editing
    if (e != null) {
      try {
        final plain =
            ref.read(vaultNotifierProvider.notifier).decryptPassword(e);
        _passCtrl = TextEditingController(text: plain);
      } catch (_) {
        _passCtrl = TextEditingController();
      }
    } else {
      _passCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _appCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(vaultNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.update(
          widget.existingEntry!.copyWith(
            appName: _appCtrl.text.trim(),
            username: _userCtrl.text.trim(),
            notes: _notesCtrl.text.trim(),
          ),
          plainPassword: _passCtrl.text,
        );
      } else {
        await notifier.create(
          appName: _appCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          plainPassword: _passCtrl.text,
          notes: _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Credential' : 'New Credential'),
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
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                      color: AppColors.vault,
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
              // Security notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.vaultGlow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.vault.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppColors.vault, size: 16),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Passwords are encrypted with AES-256 before storage.',
                        style: TextStyle(
                          color: AppColors.vault,
                          fontSize: 12,
                          fontFamily: 'Sora',
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              _buildField(
                label: 'App / Website Name *',
                controller: _appCtrl,
                hint: 'e.g. GitHub, Gmail',
                icon: Icons.apps_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'App name is required'
                    : null,
              ).animate().fadeIn(delay: 80.ms),

              const SizedBox(height: 16),

              _buildField(
                label: 'Username / Email *',
                controller: _userCtrl,
                hint: 'user@example.com',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Username is required'
                    : null,
              ).animate().fadeIn(delay: 120.ms),

              const SizedBox(height: 16),

              // Password field
              _VaultLabel(label: 'Password *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Sora',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_fix_high_rounded,
                            size: 18, color: AppColors.vault),
                        tooltip: 'Generate password',
                        onPressed: _generatePassword,
                      ),
                    ],
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Password is required' : null,
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: 16),

              _buildField(
                label: 'Notes (optional)',
                controller: _notesCtrl,
                hint: 'Any additional notes...',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = List.generate(
        16, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]);
    _passCtrl.text = rand.join();
    setState(() => _obscurePass = false);
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VaultLabel(label: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Sora',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 44 : 0),
              child: Icon(icon, size: 18),
            ),
            alignLabelWithHint: maxLines > 1,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _VaultLabel extends StatelessWidget {
  final String label;
  const _VaultLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Sora',
        letterSpacing: 0.5,
      ),
    );
  }
}
