import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import: uses file I/O on mobile/desktop, SharedPreferences on web
import 'file_cache_web.dart' if (dart.library.io) 'file_cache_io.dart'
    as file_cache;

class SharedPreferencesHelper {
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keySearchRadius = 'search_radius';
  static const String _keyCacheTimestamp = 'cache_timestamp';
  static const String _keyMapType = 'map_type';
  static const int _maxRecentSearches = 10;
  static const double _defaultSearchRadius = 500.0;

  // File names for large data (stored as files on mobile, SharedPreferences on web)
  static const String _linesCacheFile = 'lines_cache.json';
  static const String _routesGraphCacheFile = 'routes_graph_cache.json';
  static const String _stopsListFile = 'stops_list.json';

  static Future<void> init() async {
    await SharedPreferences.getInstance();
    await file_cache.initCacheDir();
    await _migrateFromSharedPreferences();
  }

  /// One-time migration: move large data from SharedPreferences to file cache.
  /// On web this moves from one SharedPreferences key to another (file_xxx prefix).
  static Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool migrated = false;

    // Migrate lines cache
    final linesData = prefs.getString('lines_cache');
    if (linesData != null) {
      await file_cache.writeFileCache(_linesCacheFile, linesData);
      await prefs.remove('lines_cache');
      migrated = true;
    }

    // Migrate routes graph cache
    final graphData = prefs.getString('routes_graph_cache');
    if (graphData != null) {
      await file_cache.writeFileCache(_routesGraphCacheFile, graphData);
      await prefs.remove('routes_graph_cache');
      migrated = true;
    }

    // Migrate stops list
    final stopsData = prefs.getString('keyStopsList');
    if (stopsData != null) {
      await file_cache.writeFileCache(_stopsListFile, stopsData);
      await prefs.remove('keyStopsList');
      migrated = true;
    }

    if (migrated) {
      debugPrint('[Cache] Migrated large data from SharedPreferences to file cache');
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await file_cache.deleteFileCache(_linesCacheFile);
    await file_cache.deleteFileCache(_routesGraphCacheFile);
    await file_cache.deleteFileCache(_stopsListFile);
  }

  // --- Full data cache (lines + routes + stops graph) ---

  static Future<bool> setLinesCache(String json) async {
    return await file_cache.writeFileCache(_linesCacheFile, json);
  }

  static Future<String?> getLinesCache() async {
    return await file_cache.readFileCache(_linesCacheFile);
  }

  static Future<bool> setRoutesGraphCache(String json) async {
    return await file_cache.writeFileCache(_routesGraphCacheFile, json);
  }

  static Future<String?> getRoutesGraphCache() async {
    return await file_cache.readFileCache(_routesGraphCacheFile);
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
    await prefs.remove(_keyCacheTimestamp);
    await file_cache.deleteFileCache(_linesCacheFile);
    await file_cache.deleteFileCache(_routesGraphCacheFile);
    await file_cache.deleteFileCache(_stopsListFile);
  }

  // --- Stops list cache ---

  static Future<void> clearStopsList() async {
    await file_cache.deleteFileCache(_stopsListFile);
  }

  static Future<bool> stopsListExists() async {
    return await file_cache.fileCacheExists(_stopsListFile);
  }

  static Future<void> setStopsList(String stopsList) async {
    await file_cache.writeFileCache(_stopsListFile, stopsList);
  }

  static Future<String?> getStopsList() async {
    return await file_cache.readFileCache(_stopsListFile);
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
