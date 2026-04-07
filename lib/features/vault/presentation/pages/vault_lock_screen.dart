// lib/features/vault/presentation/pages/vault_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/biometric_service.dart';
import '../../../../services/encryption_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/glass/glass_card.dart';
import '../providers/vault_providers.dart';
import 'vault_screen.dart';
import 'vault_setup_screen.dart';

class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({super.key});

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final hasPassword = await EncryptionService.hasVaultPassword();
    if (!hasPassword && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VaultSetupScreen()),
      );
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
    if (available && enabled) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _isLoading = true);
    final ok =
        await ref.read(vaultNotifierProvider.notifier).unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) _navigateToVault();
  }

  Future<void> _unlock() async {
    if (_passwordCtrl.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final ok = await ref
        .read(vaultNotifierProvider.notifier)
        .unlock(_passwordCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _navigateToVault();
    } else {
      setState(() => _error = 'Incorrect password. Please try again.');
    }
  }

  void _navigateToVault() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VaultScreen()),
    );
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
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
                // Vault icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.vaultGlow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.vault.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.vault.withOpacity(0.2),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.vault, size: 40),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                const Text(
                  'Vault',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sora',
                    letterSpacing: -0.8,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 8),

                const Text(
                  'Enter your vault password to continue',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Sora',
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Password field
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderColor: _error != null
                      ? AppColors.error.withOpacity(0.4)
                      : AppColors.vault.withOpacity(0.3),
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _unlock(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Sora',
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(
                        letterSpacing: 4,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.key_rounded,
                          color: AppColors.vault, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontFamily: 'Sora',
                    ),
                    textAlign: TextAlign.center,
                  ).animate().shakeX(),
                ],

                const SizedBox(height: 20),

                // Unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vault,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unlock Vault'),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                // Biometric button
                if (_biometricAvailable && _biometricEnabled) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded,
                        color: AppColors.vault),
                    label: const Text(
                      'Use Biometrics',
                      style: TextStyle(
                        color: AppColors.vault,
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],

                const SizedBox(height: 40),

                // Back
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Sora',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
