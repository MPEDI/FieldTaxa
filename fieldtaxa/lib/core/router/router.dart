import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/gallery/category_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/taxonomy/taxonomy_screen.dart';
import '../../features/taxonomy/taxon_observations_screen.dart';
import '../../features/capture/capture_screen.dart';
import '../../features/classify/classify_screen.dart';
import '../../features/viewer/photo_viewer_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (c, s) => _fade(s, const GalleryScreen()),
        ),
        GoRoute(
          path: '/category/:name',
          pageBuilder: (c, s) => _fade(
              s, CategoryScreen(categoryName: s.pathParameters['name']!)),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (c, s) => _fade(s, const SearchScreen()),
        ),
        GoRoute(
          path: '/taxonomy',
          pageBuilder: (c, s) => _fade(s, const TaxonomyScreen()),
        ),
        GoRoute(
          path: '/taxonomy/observations/:nodeId',
          pageBuilder: (c, s) => _fade(
              s,
              TaxonObservationsScreen(
                  nodeId: s.pathParameters['nodeId']!)),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (c, s) => _fade(s, const SettingsScreen()),
        ),
        GoRoute(
          path: '/settings/about',
          pageBuilder: (c, s) => _fade(s, const AboutScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/capture',
      pageBuilder: (c, s) => MaterialPage(child: const CaptureScreen()),
    ),
    GoRoute(
      path: '/classify/:draftId',
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>?;
        return _slideUp(
            s,
            ClassifyScreen(
              draftId: s.pathParameters['draftId']!,
              filePath: extra?['filePath'] as String?,
              initialTags: (extra?['tags'] as List?)
                      ?.map((e) =>
                          (e as List).map((x) => x as String).toList())
                      .toList() ??
                  [],
            ));
      },
    ),
    GoRoute(
      path: '/viewer/:itemId',
      pageBuilder: (c, s) => MaterialPage(
          child: PhotoViewerScreen(itemId: s.pathParameters['itemId']!)),
    ),
  ],
);

Page<void> _fade(GoRouterState s, Widget child) => CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, w) =>
          FadeTransition(opacity: anim, child: w),
    );

Page<void> _slideUp(GoRouterState s, Widget child) => CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, w) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: w),
      ),
    );
