import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';

const _uuid = Uuid();

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
    return 0;
  }
}

// ─── Camera capture sheet ─────────────────────────────────────────────────────

Future<void> _showCaptureSheet(BuildContext context) async {
  final router = GoRouter.of(context);

  final choice = await showModalBottomSheet<({bool video, bool fromGallery})>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CaptureChoiceSheet(),
  );
  if (choice == null) return;

  final picker = ImagePicker();
  final XFile? file;
  if (choice.video) {
    file = choice.fromGallery
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.camera);
  } else {
    file = choice.fromGallery
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.camera);
  }

  if (file != null) {
    router.push('/classify/${_uuid.v4()}', extra: {
      'filePath': file.path,
      'tags': <List<String>>[],
    });
  }
}

class _CaptureChoiceSheet extends StatelessWidget {
  const _CaptureChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _CaptureOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () => Navigator.pop(
                  context, (video: false, fromGallery: false)),
            ),
            _CaptureOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Library',
              onTap: () => Navigator.pop(
                  context, (video: false, fromGallery: true)),
            ),
            _CaptureOption(
              icon: Icons.videocam_rounded,
              label: 'Record Video',
              onTap: () => Navigator.pop(
                  context, (video: true, fromGallery: false)),
            ),
            _CaptureOption(
              icon: Icons.video_library_outlined,
              label: 'Choose Video',
              onTap: () => Navigator.pop(
                  context, (video: true, fromGallery: true)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CaptureOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CaptureOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.appPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: jakartaStyle(15, context.appFg,
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav bar ───────────────────────────────────────────────────────────

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
        border:
            Border(top: BorderSide(color: context.appLine, width: 0.5)),
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
              // Camera FAB — opens choice sheet immediately
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showCaptureSheet(context),
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
