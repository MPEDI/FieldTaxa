import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(currentIndex: idx),
    );
  }

  int _indexFor(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/taxonomy')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0; // gallery + category
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final primary = context.appPrimary;
    final muted = context.appMuted;
    final chrome = context.appChrome;

    return Container(
      decoration: BoxDecoration(
        color: chrome,
        border: Border(
            top: BorderSide(color: context.appLine, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Gallery',
                active: currentIndex == 0,
                onTap: () => context.go('/'),
                primary: primary,
                muted: muted,
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                active: currentIndex == 1,
                onTap: () => context.go('/search'),
                primary: primary,
                muted: muted,
              ),
              // Camera FAB
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/capture'),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          color: context.isDark
                              ? AppColors.fgDark
                              : Colors.white,
                          size: 24),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.account_tree_rounded,
                label: 'Taxonomy',
                active: currentIndex == 3,
                onTap: () => context.go('/taxonomy'),
                primary: primary,
                muted: muted,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: currentIndex == 4,
                onTap: () => context.go('/settings'),
                primary: primary,
                muted: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color primary;
  final Color muted;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.primary,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? primary : muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: jakartaStyle(10, color, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
