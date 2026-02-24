import 'package:flutter/material.dart';
import 'package:oasth/helpers/theme_mode_helper.dart';

class ThemeModeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    mode.value = await ThemeModeHelper.getThemeMode();
  }

  static Future<void> set(ThemeMode newMode) async {
    mode.value = newMode;
    await ThemeModeHelper.setThemeMode(newMode);
  }
}
