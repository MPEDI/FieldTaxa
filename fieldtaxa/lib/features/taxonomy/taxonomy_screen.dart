import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/taxonomy_provider.dart';

import '../../core/theme/app_theme.dart';

class TaxonomyScreen extends ConsumerWidget {
  const TaxonomyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(taxonomyProvider);

    return Scaffold(
      backgroundColor: context.appBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 60, 18, 16),
              child: Text('Taxonomy',
                  style: newsreaderStyle(24, context.appFg,
                      weight: FontWeight.w600)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _TaxonNodeRow(
                  node: tree[i], depth: 0),
              childCount: tree.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              child: _AddCategoryButton(onAdd: (name) =>
                  ref.read(taxonomyProvider.notifier).addNode(name, null)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxonNodeRow extends ConsumerStatefulWidget {
  final TaxonomyNode node;
  final int depth;

  const _TaxonNodeRow({required this.node, required this.depth});

  @override
  ConsumerState<_TaxonNodeRow> createState() => _TaxonNodeRowState();
}

class _TaxonNodeRowState extends ConsumerState<_TaxonNodeRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final depth = widget.depth;

    // Collect all descendant node names including self
    final names = <String>{};
    void gatherNames(TaxonomyNode n) {
      names.add(n.name);
      for (final c in n.children) gatherNames(c);
    }
    gatherNames(node);

    // Count total sightings (reactive via ref.watch)
    final items = ref.watch(itemsProvider);
    final sightings = ref.watch(sightingsProvider);
    final matchingIds = items
        .where((i) => i.tags.any((tp) => tp.any((t) => names.contains(t))))
        .map((i) => i.id)
        .toSet();
    final obsCount =
        sightings.where((s) => matchingIds.contains(s.itemId)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 18.0),
          child: Row(
            children: [
              // Chevron expand button
              SizedBox(
                width: 30,
                height: 44,
                child: node.children.isEmpty
                    ? const SizedBox()
                    : InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            setState(() => _expanded = !_expanded),
                        child: Center(
                          child: AnimatedRotation(
                            turns: _expanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.chevron_right_rounded,
                                color: context.appMuted, size: 18),
                          ),
                        ),
                      ),
              ),
              // Name button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      context.push('/taxonomy/observations/${node.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(node.name,
                            style: jakartaStyle(13.5, context.appFg,
                                weight: FontWeight.w500)),
                        if (obsCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.appTint,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text('$obsCount',
                                style: jakartaStyle(10, context.appPrimary2,
                                    weight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Add child button
              _TaxonAction(
                icon: Icons.add_rounded,
                bg: context.appSurface2,
                iconColor: context.appPrimary,
                onTap: () => _showAddDialog(context, node.id),
              ),
              const SizedBox(width: 4),
              // Move button — re-parent the node (and subtree)
              _TaxonAction(
                icon: Icons.drive_file_move_outline,
                bg: context.appSurface2,
                iconColor: context.appMuted,
                onTap: () => _showMoveSheet(context, node),
              ),
              const SizedBox(width: 4),
              // Delete button
              _TaxonAction(
                icon: Icons.delete_outline_rounded,
                bg: const Color(0xFFC82808).withValues(alpha: 0.07),
                iconColor: AppColors.deleteColor,
                onTap: () => _confirmDelete(context, node),
              ),
            ],
          ),
        ),
        if (_expanded && node.children.isNotEmpty)
          ...node.children.map((child) =>
              _TaxonNodeRow(node: child, depth: depth + 1)),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context, String parentId) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New category',
            style: newsreaderStyle(18, ctx.appFg, weight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Category name',
            filled: true,
            fillColor: ctx.appSurface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: jakartaStyle(13, ctx.appFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: jakartaStyle(13, ctx.appMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: ctx.appPrimary),
            child: Text('Add',
                style: jakartaStyle(13, Colors.white,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(taxonomyProvider.notifier).addNode(name, parentId);
    }
  }

  /// Bottom sheet listing all valid destination parents. Selecting one
  /// moves the node (and its subtree) there; all observation tags that
  /// pass through the node are rewritten automatically.
  Future<void> _showMoveSheet(BuildContext context, TaxonomyNode node) async {
    final tree = ref.read(taxonomyProvider);

    // Collect (node, depth) pairs, excluding the moved node and its subtree.
    final destinations = <(TaxonomyNode, int)>[];
    void walk(TaxonomyNode n, int depth) {
      if (n.id == node.id) return; // skip self + entire subtree
      destinations.add((n, depth));
      for (final c in n.children) {
        walk(c, depth + 1);
      }
    }

    for (final root in tree) {
      walk(root, 0);
    }

    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: ctx.appSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Move "${node.name}" to…',
                          style: newsreaderStyle(18, ctx.appFg,
                              weight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: jakartaStyle(13, ctx.appMuted)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                  children: [
                    // Top level option
                    _MoveDestRow(
                      label: 'Top level (root)',
                      depth: 0,
                      icon: Icons.home_outlined,
                      enabled: node.parentId != null,
                      onTap: () => Navigator.pop(ctx, '__root__'),
                    ),
                    ...destinations.map((d) => _MoveDestRow(
                          label: d.$1.name,
                          depth: d.$2 + 1,
                          icon: Icons.subdirectory_arrow_right_rounded,
                          enabled: d.$1.id != node.parentId,
                          onTap: () => Navigator.pop(ctx, d.$1.id),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    final newParentId = selected == '__root__' ? null : selected;
    final ok = await ref
        .read(taxonomyProvider.notifier)
        .moveNode(node.id, newParentId);
    // Observation tags were rewritten in the DB — refresh the items list.
    await ref.read(itemsProvider.notifier).reload();
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot move a category into its own subtree')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, TaxonomyNode node) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${node.name}"?',
            style: newsreaderStyle(18, ctx.appFg, weight: FontWeight.w600)),
        content: Text(
            'This will also delete all child categories.',
            style: jakartaStyle(13, ctx.appFg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: jakartaStyle(13, ctx.appMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.deleteColor),
            child: Text('Delete',
                style: jakartaStyle(13, Colors.white,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(taxonomyProvider.notifier).deleteNode(node.id);
    }
  }
}

class _MoveDestRow extends StatelessWidget {
  final String label;
  final int depth;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MoveDestRow({
    required this.label,
    required this.depth,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.only(
              left: depth * 18.0, top: 10, bottom: 10, right: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: context.appMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: jakartaStyle(13.5, context.appFg,
                        weight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              if (!enabled)
                Text('current',
                    style: jakartaStyle(11, context.appMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxonAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _TaxonAction({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final ValueChanged<String> onAdd;
  const _AddCategoryButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.appLine,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: context.appPrimary, size: 18),
            const SizedBox(width: 6),
            Text('Add category',
                style: jakartaStyle(13, context.appPrimary,
                    weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New category',
            style: newsreaderStyle(18, ctx.appFg, weight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Category name',
            filled: true,
            fillColor: ctx.appSurface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: jakartaStyle(13, ctx.appFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: jakartaStyle(13, ctx.appMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
                backgroundColor: ctx.appPrimary),
            child: Text('Add',
                style: jakartaStyle(13, Colors.white,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      onAdd(name);
    }
  }
}
