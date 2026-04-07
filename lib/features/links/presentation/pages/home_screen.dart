// lib/features/links/presentation/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_search_bar.dart';
import '../../domain/entities/link_entity.dart';
import '../providers/links_providers.dart';
import '../widgets/link_list_item.dart';
import 'add_edit_link_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Link',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sora',
                            letterSpacing: -0.8,
                          ),
                        ),
                        TextSpan(
                          text: 'Vault',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Sora',
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                onPressed: () {},
                color: AppColors.textSecondary,
              ),
            ],
          ),

          // ── Search Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText: 'Search links, groups...',
                onChanged: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
          ),

          // ── Search Results ────────────────────────────────────────────────
          if (isSearching) ...[
            _SearchResults(query: query),
          ] else ...[
            // ── Favorites ──────────────────────────────────────────────────
            _FavoritesSection(),

            // ── Recent ─────────────────────────────────────────────────────
            _RecentSection(),

            // ── Suggested ──────────────────────────────────────────────────
            _SuggestedSection(),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddLink(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Link',
            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 400.ms, duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _openAddLink(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditLinkScreen()),
    );
  }
}

// ── Favorites Section ────────────────────────────────────────────────────────

class _FavoritesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    if (favorites.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SectionHeader(
              title: '⭐  Favorites',
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _FavoriteChip(link: favorites[i]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ).animate().fadeIn(delay: 100.ms),
    );
  }
}

class _FavoriteChip extends ConsumerWidget {
  final LinkEntity link;
  const _FavoriteChip({required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(linksNotifierProvider.notifier).recordOpen(link.id);
        _launchUrl(link.url);
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassBase,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FaviconWidget(url: link.faviconUrl, size: 28),
            Text(
              link.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Sora',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    // ignore: deprecated_member_use
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Recent Section ────────────────────────────────────────────────────────────

class _RecentSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentLinksProvider);
    if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '🕐  Recent'),
            ...recent.take(5).map((link) => LinkListItem(
                  link: link,
                  onFavoriteToggle: () =>
                      ref.read(linksNotifierProvider.notifier).toggleFavorite(link.id),
                  onOpen: () =>
                      ref.read(linksNotifierProvider.notifier).recordOpen(link.id),
                  onDelete: () =>
                      ref.read(linksNotifierProvider.notifier).delete(link.id),
                )),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

// ── Suggested Section ─────────────────────────────────────────────────────────

class _SuggestedSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequent = ref.watch(frequentLinksProvider);
    if (frequent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '🔥  Frequently Used'),
            ...frequent.map((link) => LinkListItem(
                  link: link,
                  onFavoriteToggle: () =>
                      ref.read(linksNotifierProvider.notifier).toggleFavorite(link.id),
                  onOpen: () =>
                      ref.read(linksNotifierProvider.notifier).recordOpen(link.id),
                  onDelete: () =>
                      ref.read(linksNotifierProvider.notifier).delete(link.id),
                )),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms),
    );
  }
}

// ── Search Results ─────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(filteredLinksProvider);

    if (results.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No results found',
          subtitle: 'Try a different search term',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => LinkListItem(
            link: results[i],
            onFavoriteToggle: () =>
                ref.read(linksNotifierProvider.notifier).toggleFavorite(results[i].id),
            onOpen: () =>
                ref.read(linksNotifierProvider.notifier).recordOpen(results[i].id),
            onDelete: () =>
                ref.read(linksNotifierProvider.notifier).delete(results[i].id),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
          childCount: results.length,
        ),
      ),
    );
  }
}

// Needed imports not already at top
import 'package:url_launcher/url_launcher.dart';
