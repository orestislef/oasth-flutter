import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyStopsList = 'keyStopsList';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keySearchRadius = 'search_radius';
  static const int _maxRecentSearches = 10;
  static const double _defaultSearchRadius = 500.0;

  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- Stops list cache ---

  static Future<void> clearStopsList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStopsList);
  }

  static Future<bool> stopsListExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyStopsList);
  }

  static Future<void> setStopsList(String stopsList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStopsList, stopsList);
  }

  static Future<String?> getStopsList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStopsList);
  }

  // --- Recent searches ---

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentSearches) ?? [];
  }

  static Future<void> addRecentSearch(String search) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_keyRecentSearches) ?? [];
    searches.remove(search);
    searches.insert(0, search);
    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }
    await prefs.setStringList(_keyRecentSearches, searches);
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentSearches);
  }

  // --- Search radius ---

  static Future<double> getSearchRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySearchRadius) ?? _defaultSearchRadius;
  }

  static Future<void> setSearchRadius(double radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySearchRadius, radius);
  }
}