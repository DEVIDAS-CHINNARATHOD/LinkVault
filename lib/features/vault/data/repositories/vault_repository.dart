// lib/features/vault/data/repositories/vault_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/encryption_service.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/vault_entry_entity.dart';

class VaultRepository {
  late final Box<VaultEntryEntity> _box;
  static const _uuid = Uuid();

  VaultRepository() {
    _box = Hive.box<VaultEntryEntity>(AppConstants.vaultBox);
  }

  List<VaultEntryEntity> getAll() => _box.values.toList()
    ..sort((a, b) => a.appName.compareTo(b.appName));

  List<VaultEntryEntity> search(String query) {
    final q = query.toLowerCase();
    return _box.values
        .where((v) =>
            v.appName.toLowerCase().contains(q) ||
            v.username.toLowerCase().contains(q))
        .toList();
  }

  /// Decrypts and returns the plain password for a vault entry.
  String decryptPassword(VaultEntryEntity entry) {
    return EncryptionService.decrypt(entry.passwordEncrypted);
  }

  Future<VaultEntryEntity> create({
    required String appName,
    required String username,
    required String plainPassword,
    String notes = '',
  }) async {
    final encrypted = EncryptionService.encrypt(plainPassword);
    final now = DateTime.now();
    final entry = VaultEntryEntity(
      id: _uuid.v4(),
      appName: appName,
      username: username,
      passwordEncrypted: encrypted,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(entry.id, entry);
    _syncToSupabase(entry);
    return entry;
  }

  Future<void> update(VaultEntryEntity entry, {String? plainPassword}) async {
    final updated = entry.copyWith(
      passwordEncrypted: plainPassword != null
          ? EncryptionService.encrypt(plainPassword)
          : null,
    );
    await _box.put(updated.id, updated);
    _syncToSupabase(updated);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _deleteFromSupabase(id);
  }

  Stream<BoxEvent> watch() => _box.watch();

  void _syncToSupabase(VaultEntryEntity entry) {
    if (!SupabaseService.isAuthenticated) return;
    // Only sync encrypted password — never plain text.
    final data = entry.toMap()..['user_id'] = SupabaseService.userId;
    SupabaseService.client
        .from(SupabaseService.vaultTable)
        .upsert(data)
        .then((_) {})
        .catchError((_) {});
  }

  void _deleteFromSupabase(String id) {
    if (!SupabaseService.isAuthenticated) return;
    SupabaseService.client
        .from(SupabaseService.vaultTable)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((_) {});
  }
}
