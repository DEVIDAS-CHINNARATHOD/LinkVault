// lib/features/groups/data/repositories/groups_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/group_entity.dart';

class GroupsRepository {
  late final Box<GroupEntity> _box;
  static const _uuid = Uuid();

  GroupsRepository() {
    _box = Hive.box<GroupEntity>(AppConstants.groupsBox);
    _seedDefaults();
  }

  void _seedDefaults() {
    if (_box.isNotEmpty) return;
    final defaults = [
      ('GitHub', 'code', '#24292e'),
      ('APIs', 'api', '#3B82F6'),
      ('Tools', 'tools', '#10B981'),
      ('Docs', 'description', '#F59E0B'),
      ('Design', 'palette', '#EC4899'),
      ('Articles', 'article', '#8B5CF6'),
    ];
    for (final d in defaults) {
      final now = DateTime.now();
      final group = GroupEntity(
        id: _uuid.v4(),
        name: d.$1,
        icon: d.$2,
        color: d.$3,
        createdAt: now,
      );
      _box.put(group.id, group);
    }
  }

  List<GroupEntity> getAll() => _box.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  GroupEntity? getById(String id) => _box.get(id);

  GroupEntity? getByName(String name) => _box.values
      .where((g) => g.name.toLowerCase() == name.toLowerCase())
      .firstOrNull;

  Future<GroupEntity> create({
    required String name,
    String icon = 'folder',
    String color = '#3B82F6',
  }) async {
    final group = GroupEntity(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );
    await _box.put(group.id, group);
    _syncToSupabase(group);
    return group;
  }

  Future<void> update(GroupEntity group) async {
    await _box.put(group.id, group);
    _syncToSupabase(group);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _deleteFromSupabase(id);
  }

  Stream<BoxEvent> watch() => _box.watch();

  void _syncToSupabase(GroupEntity group) {
    if (!SupabaseService.isAuthenticated) return;
    final data = group.toMap()..['user_id'] = SupabaseService.userId;
    SupabaseService.client
        .from(SupabaseService.groupsTable)
        .upsert(data)
        .then((_) {})
        .catchError((_) {});
  }

  void _deleteFromSupabase(String id) {
    if (!SupabaseService.isAuthenticated) return;
    SupabaseService.client
        .from(SupabaseService.groupsTable)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((_) {});
  }
}
