// lib/features/links/presentation/providers/links_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/links_repository.dart';
import '../../domain/entities/link_entity.dart';

// ─── Repository Provider ──────────────────────────────────────────────────

final linksRepositoryProvider = Provider<LinksRepository>((ref) {
  return LinksRepository();
});

// ─── State Notifiers ──────────────────────────────────────────────────────

class LinksNotifier extends AsyncNotifier<List<LinkEntity>> {
  LinksRepository get _repo => ref.read(linksRepositoryProvider);

  @override
  Future<List<LinkEntity>> build() async {
    return _repo.getAll();
  }

  void refresh() => state = AsyncValue.data(_repo.getAll());

  Future<void> create({
    required String title,
    required String url,
    String description = '',
    String? groupId,
    String? faviconUrl,
  }) async {
    await _repo.create(
      title: title,
      url: url,
      description: description,
      groupId: groupId,
      faviconUrl: faviconUrl,
    );
    refresh();
  }

  Future<void> update(LinkEntity link) async {
    await _repo.update(link);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> toggleFavorite(String id) async {
    await _repo.toggleFavorite(id);
    refresh();
  }

  Future<void> recordOpen(String id) async {
    await _repo.recordOpen(id);
    refresh();
  }

  bool isDuplicate(String url, {String? excludeId}) =>
      _repo.isDuplicate(url, excludeId: excludeId);
}

final linksNotifierProvider =
    AsyncNotifierProvider<LinksNotifier, List<LinkEntity>>(LinksNotifier.new);

// ─── Derived Providers ────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final activeGroupFilterProvider = StateProvider<String?>((ref) => null);

final filteredLinksProvider = Provider<List<LinkEntity>>((ref) {
  final links = ref.watch(linksNotifierProvider).valueOrNull ?? [];
  final query = ref.watch(searchQueryProvider);
  final groupId = ref.watch(activeGroupFilterProvider);

  var filtered = links;
  if (groupId != null) {
    filtered = filtered.where((l) => l.groupId == groupId).toList();
  }
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    filtered = filtered
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.url.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q))
        .toList();
  }
  return filtered;
});

final favoritesProvider = Provider<List<LinkEntity>>((ref) {
  final links = ref.watch(linksNotifierProvider).valueOrNull ?? [];
  return links.where((l) => l.isFavorite).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final recentLinksProvider = Provider<List<LinkEntity>>((ref) {
  final repo = ref.watch(linksRepositoryProvider);
  return repo.getRecent();
});

final frequentLinksProvider = Provider<List<LinkEntity>>((ref) {
  final repo = ref.watch(linksRepositoryProvider);
  return repo.getFrequent();
});
