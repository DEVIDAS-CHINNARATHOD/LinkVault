// lib/features/links/data/repositories/links_repository.dart
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/link_entity.dart';

class LinksRepository {
  late final Box<LinkEntity> _box;
  static const _uuid = Uuid();

  LinksRepository() {
    _box = Hive.box<LinkEntity>(AppConstants.linksBox);
  }

  // ─── Local CRUD ────────────────────────────────────────────────────────────

  List<LinkEntity> getAll() => _box.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<LinkEntity> getFavorites() =>
      _box.values.where((l) => l.isFavorite).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<LinkEntity> getRecent({int limit = 10}) {
    final withDates = _box.values
        .where((l) => l.lastOpenedAt != null)
        .toList()
      ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    return withDates.take(limit).toList();
  }

  List<LinkEntity> getFrequent({int limit = 5}) {
    final all = _box.values.toList()
      ..sort((a, b) => b.clickCount.compareTo(a.clickCount));
    return all.where((l) => l.clickCount > 0).take(limit).toList();
  }

  List<LinkEntity> getByGroup(String groupId) =>
      _box.values.where((l) => l.groupId == groupId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<LinkEntity> search(String query) {
    final q = query.toLowerCase();
    return _box.values
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.url.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool isDuplicate(String url, {String? excludeId}) {
    return _box.values.any((l) =>
        l.url.toLowerCase() == url.toLowerCase() &&
        (excludeId == null || l.id != excludeId));
  }

  Future<void> save(LinkEntity link) async {
    await _box.put(link.id, link);
    _syncToSupabase(link);
  }

  Future<LinkEntity> create({
    required String title,
    required String url,
    String description = '',
    String? groupId,
    String? faviconUrl,
  }) async {
    final now = DateTime.now();
    final link = LinkEntity(
      id: _uuid.v4(),
      title: title,
      url: url,
      description: description,
      groupId: groupId,
      faviconUrl: faviconUrl,
      createdAt: now,
      updatedAt: now,
    );
    await save(link);
    return link;
  }

  Future<void> update(LinkEntity link) async {
    final updated = link.copyWith(updatedAt: DateTime.now());
    await _box.put(updated.id, updated);
    _syncToSupabase(updated);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _deleteFromSupabase(id);
  }

  Future<void> toggleFavorite(String id) async {
    final link = _box.get(id);
    if (link == null) return;
    await update(link.copyWith(isFavorite: !link.isFavorite));
  }

  Future<void> recordOpen(String id) async {
    final link = _box.get(id);
    if (link == null) return;
    final updated = link.copyWith(
      clickCount: link.clickCount + 1,
      lastOpenedAt: DateTime.now(),
    );
    await _box.put(id, updated);
    _syncToSupabase(updated);
  }

  /// Watch the box for reactive updates.
  Stream<BoxEvent> watch() => _box.watch();

  // ─── Supabase Sync (fire-and-forget) ──────────────────────────────────────

  void _syncToSupabase(LinkEntity link) {
    if (!SupabaseService.isAuthenticated) return;
    final userId = SupabaseService.userId;
    final data = link.toMap()..['user_id'] = userId;
    SupabaseService.client
        .from(SupabaseService.linksTable)
        .upsert(data)
        .then((_) {})
        .catchError((_) {});
  }

  void _deleteFromSupabase(String id) {
    if (!SupabaseService.isAuthenticated) return;
    SupabaseService.client
        .from(SupabaseService.linksTable)
        .delete()
        .eq('id', id)
        .then((_) {})
        .catchError((_) {});
  }

  Future<void> syncFromSupabase() async {
    if (!SupabaseService.isAuthenticated) return;
    try {
      final data = await SupabaseService.client
          .from(SupabaseService.linksTable)
          .select()
          .eq('user_id', SupabaseService.userId!);
      for (final row in data) {
        final link = LinkEntity.fromMap(row as Map<String, dynamic>);
        await _box.put(link.id, link);
      }
    } catch (_) {
      // Offline — local data is source of truth
    }
  }
}
