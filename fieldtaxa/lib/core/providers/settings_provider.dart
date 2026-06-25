import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      themeMode: ThemePreference.values[prefs.getInt('theme') ?? 2],
      language: prefs.getString('language') ?? 'en',
      storageMode: StorageMode.values[prefs.getInt('storage') ?? 0],
      coordSystem: CoordSystem.values[prefs.getInt('coord') ?? 0],
      mapProvider: MapProvider.values[prefs.getInt('map') ?? 0],
    );
  }

  Future<void> setTheme(ThemePreference t) async {
    state = AppSettings(
      themeMode: t,
      language: state.language,
      storageMode: state.storageMode,
      coordSystem: state.coordSystem,
      mapProvider: state.mapProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', t.index);
  }

  Future<void> setLanguage(String lang) async {
    state = AppSettings(
      themeMode: state.themeMode,
      language: lang,
      storageMode: state.storageMode,
      coordSystem: state.coordSystem,
      mapProvider: state.mapProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> setStorageMode(StorageMode m) async {
    state = AppSettings(
      themeMode: state.themeMode,
      language: state.language,
      storageMode: m,
      coordSystem: state.coordSystem,
      mapProvider: state.mapProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('storage', m.index);
  }

  Future<void> setCoordSystem(CoordSystem c) async {
    state = AppSettings(
      themeMode: state.themeMode,
      language: state.language,
      storageMode: state.storageMode,
      coordSystem: c,
      mapProvider: state.mapProvider,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coord', c.index);
  }

  Future<void> setMapProvider(MapProvider m) async {
    state = AppSettings(
      themeMode: state.themeMode,
      language: state.language,
      storageMode: state.storageMode,
      coordSystem: state.coordSystem,
      mapProvider: m,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('map', m.index);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (_) => SettingsNotifier());

final themeModeProvider = Provider<ThemeMode>((ref) {
  final pref = ref.watch(settingsProvider).themeMode;
  return switch (pref) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  };
});

final localeProvider = Provider<Locale>((ref) {
  final lang = ref.watch(settingsProvider).language;
  return Locale(lang);
});
