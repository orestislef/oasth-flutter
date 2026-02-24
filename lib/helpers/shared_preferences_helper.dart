import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyStopsList = 'keyStopsList';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keySearchRadius = 'search_radius';
  static const String _keyLinesCache = 'lines_cache';
  static const String _keyRoutesGraphCache = 'routes_graph_cache';
  static const String _keyCacheTimestamp = 'cache_timestamp';
  static const String _keyMapType = 'map_type';
  static const int _maxRecentSearches = 10;
  static const double _defaultSearchRadius = 500.0;

  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- Full data cache (lines + routes + stops graph) ---

  static Future<void> setLinesCache(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLinesCache, json);
  }

  static Future<String?> getLinesCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLinesCache);
  }

  static Future<void> setRoutesGraphCache(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoutesGraphCache, json);
  }

  static Future<String?> getRoutesGraphCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRoutesGraphCache);
  }

  static Future<void> setCacheTimestamp(int epochMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCacheTimestamp, epochMs);
  }

  static Future<int?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCacheTimestamp);
  }

  static Future<bool> isCacheValid(
      {Duration maxAge = const Duration(days: 30)}) async {
    final timestamp = await getCacheTimestamp();
    if (timestamp == null) return false;
    final cached = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cached) < maxAge;
  }

  static Future<void> clearDataCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLinesCache);
    await prefs.remove(_keyRoutesGraphCache);
    await prefs.remove(_keyCacheTimestamp);
    await prefs.remove(_keyStopsList);
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

  // --- Map type ---

  static Future<void> setMapType(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMapType, id);
  }

  static Future<int?> getMapType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMapType);
  }
}
