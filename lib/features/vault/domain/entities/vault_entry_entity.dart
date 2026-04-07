// lib/features/vault/domain/entities/vault_entry_entity.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

part 'vault_entry_entity.g.dart';

@HiveType(typeId: HiveTypeIds.vaultEntry)
class VaultEntryEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String appName;

  @HiveField(2)
  String username;

  /// Stored encrypted — never plain text on disk.
  @HiveField(3)
  String passwordEncrypted;

  @HiveField(4)
  String notes;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  VaultEntryEntity({
    required this.id,
    required this.appName,
    required this.username,
    required this.passwordEncrypted,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultEntryEntity.fromMap(Map<String, dynamic> map) => VaultEntryEntity(
        id: map['id'] as String,
        appName: map['app_name'] as String,
        username: map['username'] as String,
        passwordEncrypted: map['password_encrypted'] as String,
        notes: map['notes'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'app_name': appName,
        'username': username,
        'password_encrypted': passwordEncrypted,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  VaultEntryEntity copyWith({
    String? appName,
    String? username,
    String? passwordEncrypted,
    String? notes,
  }) =>
      VaultEntryEntity(
        id: id,
        appName: appName ?? this.appName,
        username: username ?? this.username,
        passwordEncrypted: passwordEncrypted ?? this.passwordEncrypted,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
