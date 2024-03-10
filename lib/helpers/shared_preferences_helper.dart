import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyStopsList = 'keyStopsList';

  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  static Future<void> clearAll() async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
  }

  static Future<void> clearStopsList() async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyStopsList);
    });
  }

  static Future<bool> stopsListExists() async {
    return await SharedPreferences.getInstance().then((prefs) {
      return prefs.containsKey(_keyStopsList);
    });
  }

  static Future<void> setStopsList(String stopsList) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyStopsList, stopsList);
    });
  }

  static Future<String?> getStopsList() async {
    return await SharedPreferences.getInstance().then((prefs) {
      return prefs.getString(_keyStopsList);
    });
  }
}