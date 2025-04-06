import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system);

  Future<void> loadTheme() async {
    final box = await Hive.openBox('preferences');
    final saved = box.get(_key, defaultValue: 'dark');
    value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final box = await Hive.openBox('preferences');
    if (value == ThemeMode.dark) {
      value = ThemeMode.light;
      await box.put(_key, 'light');
    } else {
      value = ThemeMode.dark;
      await box.put(_key, 'dark');
    }
  }
}

// Global instance
final themeNotifier = ThemeNotifier();
