// lib/features/vault/presentation/providers/vault_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vault_repository.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../../../../services/encryption_service.dart';
import '../../../../services/biometric_service.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository();
});

// Vault lock state
final vaultUnlockedProvider = StateProvider<bool>((ref) => false);
final vaultLockedAtProvider = StateProvider<DateTime?>((ref) => null);

class VaultNotifier extends AsyncNotifier<List<VaultEntryEntity>> {
  VaultRepository get _repo => ref.read(vaultRepositoryProvider);

  @override
  Future<List<VaultEntryEntity>> build() async => _repo.getAll();

  void refresh() => state = AsyncValue.data(_repo.getAll());

  Future<bool> unlock(String password) async {
    final hash = await EncryptionService.getVaultPasswordHash();
    if (hash == null) return false;
    final ok = EncryptionService.verifyPassword(password, hash);
    if (ok) {
      ref.read(vaultUnlockedProvider.notifier).state = true;
      ref.read(vaultLockedAtProvider.notifier).state = DateTime.now();
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics() async {
    final isEnabled = await BiometricService.isEnabled();
    if (!isEnabled) return false;
    final ok = await BiometricService.authenticate(
        reason: 'Authenticate to unlock your vault');
    if (ok) {
      ref.read(vaultUnlockedProvider.notifier).state = true;
      ref.read(vaultLockedAtProvider.notifier).state = DateTime.now();
    }
    return ok;
  }

  void lock() {
    ref.read(vaultUnlockedProvider.notifier).state = false;
  }

  void refreshActivity() {
    ref.read(vaultLockedAtProvider.notifier).state = DateTime.now();
  }

  Future<bool> setPassword(String password) async {
    final hash = EncryptionService.hashPassword(password);
    await EncryptionService.saveVaultPasswordHash(hash);
    return true;
  }

  Future<bool> hasPassword() => EncryptionService.hasVaultPassword();

  Future<void> create({
    required String appName,
    required String username,
    required String plainPassword,
    String notes = '',
  }) async {
    await _repo.create(
      appName: appName,
      username: username,
      plainPassword: plainPassword,
      notes: notes,
    );
    refresh();
  }

  Future<void> update(VaultEntryEntity entry, {String? plainPassword}) async {
    await _repo.update(entry, plainPassword: plainPassword);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  String decryptPassword(VaultEntryEntity entry) =>
      _repo.decryptPassword(entry);
}

final vaultNotifierProvider =
    AsyncNotifierProvider<VaultNotifier, List<VaultEntryEntity>>(
        VaultNotifier.new);

final vaultSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredVaultProvider = Provider<List<VaultEntryEntity>>((ref) {
  final entries = ref.watch(vaultNotifierProvider).valueOrNull ?? [];
  final query = ref.watch(vaultSearchQueryProvider);
  if (query.isEmpty) return entries;
  final q = query.toLowerCase();
  return entries
      .where((e) =>
          e.appName.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q))
      .toList();
});
