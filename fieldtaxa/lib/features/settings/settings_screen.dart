import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.appBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 60, 18, 20),
              child: Text('Settings',
                  style: newsreaderStyle(24, context.appFg,
                      weight: FontWeight.w600)),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // LANGUAGE
              _Section(
                title: 'LANGUAGE',
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.5,
                  children: [
                    _LangBtn(
                        code: 'en',
                        label: 'English',
                        current: settings.language,
                        onTap: () => notifier.setLanguage('en')),
                    _LangBtn(
                        code: 'de',
                        label: 'Deutsch',
                        current: settings.language,
                        onTap: () => notifier.setLanguage('de')),
                    _LangBtn(
                        code: 'it',
                        label: 'Italiano',
                        current: settings.language,
                        onTap: () => notifier.setLanguage('it')),
                    _LangBtn(
                        code: 'fr',
                        label: 'Français',
                        current: settings.language,
                        onTap: () => notifier.setLanguage('fr')),
                  ],
                ),
              ),
              // APPEARANCE
              _Section(
                title: 'APPEARANCE',
                child: _SegControl3<ThemePreference>(
                  values: ThemePreference.values,
                  current: settings.themeMode,
                  labels: const ['Light', 'Dark', 'System'],
                  onChanged: notifier.setTheme,
                ),
              ),
              // STORAGE
              _Section(
                title: 'STORAGE LIBRARY',
                child: Column(
                  children: StorageMode.values
                      .map((m) => _StorageRow(
                            mode: m,
                            current: settings.storageMode,
                            onTap: () => notifier.setStorageMode(m),
                          ))
                      .toList(),
                ),
              ),
              // COORDINATES
              _Section(
                title: 'COORDINATES',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SegControl2<CoordSystem>(
                      values: CoordSystem.values,
                      current: settings.coordSystem,
                      labels: const ['GPS', 'Swiss LV95'],
                      onChanged: notifier.setCoordSystem,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swiss territory only — LV95 outside Switzerland may be inaccurate.',
                      style: jakartaStyle(11, context.appMuted),
                    ),
                  ],
                ),
              ),
              // MAPS
              _Section(
                title: 'MAPS',
                child: _SegControl2<MapProvider>(
                  values: MapProvider.values,
                  current: settings.mapProvider,
                  labels: const ['System maps', 'Swisstopo'],
                  onChanged: notifier.setMapProvider,
                ),
              ),
              // ABOUT
              _Section(
                title: '',
                child: InkWell(
                  onTap: () => context.push('/settings/about'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: context.appPrimary, size: 18),
                        const SizedBox(width: 10),
                        Text('About',
                            style: jakartaStyle(14, context.appFg,
                                weight: FontWeight.w600)),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: context.appMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
                style: jakartaStyle(11, context.appMuted,
                    weight: FontWeight.w700)),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: context.appLine),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String code;
  final String label;
  final String current;
  final VoidCallback onTap;

  const _LangBtn({
    required this.code,
    required this.label,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = code == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? context.appPrimary : context.appSurface2,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(label,
              style: jakartaStyle(
                  13,
                  active ? Colors.white : context.appFg,
                  weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SegControl2<T> extends StatelessWidget {
  final List<T> values;
  final T current;
  final List<String> labels;
  final ValueChanged<T> onChanged;

  const _SegControl2({
    required this.values,
    required this.current,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: List.generate(values.length, (i) {
          final active = values[i] == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? context.appSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: active
                      ? Border.all(color: context.appLine)
                      : null,
                ),
                child: Center(
                  child: Text(labels[i],
                      style: jakartaStyle(
                          13,
                          active ? context.appPrimary : context.appMuted,
                          weight: active
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SegControl3<T> extends StatelessWidget {
  final List<T> values;
  final T current;
  final List<String> labels;
  final ValueChanged<T> onChanged;

  const _SegControl3({
    required this.values,
    required this.current,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SegControl2<T>(
        values: values,
        current: current,
        labels: labels,
        onChanged: onChanged);
  }
}

class _StorageRow extends StatelessWidget {
  final StorageMode mode;
  final StorageMode current;
  final VoidCallback onTap;

  const _StorageRow({
    required this.mode,
    required this.current,
    required this.onTap,
  });

  static const _labels = {
    StorageMode.appOnly: 'In-app only',
    StorageMode.rollOnly: 'Camera roll',
    StorageMode.both: 'Both',
  };

  @override
  Widget build(BuildContext context) {
    final active = mode == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? context.appPrimary : context.appLine,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? context.appPrimary : Colors.transparent,
                border: Border.all(
                  color: active ? context.appPrimary : context.appMuted,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(_labels[mode] ?? '',
                style: jakartaStyle(
                    13,
                    active ? context.appPrimary : context.appFg,
                    weight: active
                        ? FontWeight.w700
                        : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
