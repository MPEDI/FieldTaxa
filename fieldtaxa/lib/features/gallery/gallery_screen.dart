import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/photo_tile.dart';

const _galleryCap = 9;

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final grouped = _group(items);
    // Count only items that are visible in the gallery (have a category).
    final visibleCount =
        grouped.values.fold(0, (sum, list) => sum + list.length);

    return Scaffold(
      backgroundColor: context.appBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(total: visibleCount)),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 64, color: context.appMuted),
                    const SizedBox(height: 16),
                    Text('No observations yet',
                        style: jakartaStyle(14, context.appMuted,
                            weight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Tap the camera to get started',
                        style: jakartaStyle(12, context.appMuted)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final entry = grouped.entries.elementAt(i);
                  return _CategorySection(
                    name: entry.key,
                    items: entry.value,
                  );
                },
                childCount: grouped.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Map<String, List<FieldItem>> _group(List<FieldItem> items) {
    final map = <String, List<FieldItem>>{};
    for (final item in items) {
      final cat = item.topLevelCategory;
      if (cat.isEmpty) continue;
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }
}

class _Header extends StatelessWidget {
  final int total;
  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appChrome,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FieldTaxa',
                    style: newsreaderStyle(22, context.appFg,
                        weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Opacity(
                  opacity: 0.75,
                  child: Image.asset(
                    'assets/MPeditechLogo.png',
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$total',
                style: jakartaStyle(12, context.appMuted,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String name;
  final List<FieldItem> items;

  const _CategorySection({required this.name, required this.items});

  @override
  Widget build(BuildContext context) {
    final capped = items.take(_galleryCap).toList();
    final hasMore = items.length > _galleryCap;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: newsreaderStyle(19, context.appFg,
                        weight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appSurface2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${items.length}',
                    style: jakartaStyle(11, context.appMuted,
                        weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: capped.length,
            itemBuilder: (_, i) => PhotoTile(item: capped[i]),
          ),
          if (hasMore) ...[
            const SizedBox(height: 3),
            GestureDetector(
              onTap: () => context.push('/category/$name'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.appTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('See all ${items.length} →',
                        style: jakartaStyle(13, context.appPrimary,
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
