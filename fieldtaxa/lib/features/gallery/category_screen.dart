import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/items_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/photo_tile.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryName;
  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider)
        .where((i) => i.topLevelCategory == categoryName)
        .toList();

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appChrome,
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 16, color: context.appPrimary),
              Text('Gallery',
                  style: jakartaStyle(14, context.appPrimary,
                      weight: FontWeight.w700)),
            ],
          ),
        ),
        leadingWidth: 90,
        title: Text(categoryName,
            style: newsreaderStyle(17, context.appFg,
                weight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${items.length}',
                style: jakartaStyle(12, context.appMuted,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(3),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => PhotoTile(item: items[i]),
        ),
      ),
    );
  }
}
