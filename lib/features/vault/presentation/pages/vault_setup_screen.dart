// lib/features/vault/presentation/pages/vault_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/biometric_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../providers/vault_providers.dart';
import 'vault_screen.dart';

class VaultSetupScreen extends ConsumerStatefulWidget {
  const VaultSetupScreen({super.key});

  @override
  ConsumerState<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends ConsumerState<VaultSetupScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _enableBiometrics = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isAvailable();
    setState(() => _biometricAvailable = available);
  }

  Future<void> _setup() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(vaultNotifierProvider.notifier).setPassword(pass);

    if (_enableBiometrics) {
      await BiometricService.setEnabled(true);
    }

    if (mounted) {
      ref.read(vaultUnlockedProvider.notifier).state = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.vaultGlow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.vault.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.vault, size: 40),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                const Text(
                  'Set Vault Password',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sora',
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 8),

                const Text(
                  'This password protects your encrypted credentials.\nChoose something strong and memorable.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Sora',
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 36),

                // Password
                _PasswordField(
                  ctrl: _passCtrl,
                  hint: 'Create password',
                  obscure: _obscure1,
                  onToggle: () => setState(() => _obscure1 = !_obscure1),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 14),

                // Confirm
                _PasswordField(
                  ctrl: _confirmCtrl,
                  hint: 'Confirm password',
                  obscure: _obscure2,
                  onToggle: () => setState(() => _obscure2 = !_obscure2),
                  onSubmit: _setup,
                ).animate().fadeIn(delay: 300.ms),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontFamily: 'Sora'),
                      textAlign: TextAlign.center),
                ],

                // Biometrics toggle
                if (_biometricAvailable) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded,
                            color: AppColors.vault, size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enable Biometrics',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Sora',
                                  )),
                              Text('Fingerprint or face unlock',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontFamily: 'Sora',
                                  )),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enableBiometrics,
                          onChanged: (v) =>
                              setState(() => _enableBiometrics = v),
                          activeColor: AppColors.vault,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setup,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vault,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Vault'),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: AppColors.textMuted, fontFamily: 'Sora')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback? onSubmit;

  const _PasswordField({
    required this.ctrl,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.vault.withOpacity(0.25),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Sora',
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AppColors.vault, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
