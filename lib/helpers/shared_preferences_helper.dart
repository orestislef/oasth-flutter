import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keySearchRadius = 'search_radius';
  static const String _keyCacheTimestamp = 'cache_timestamp';
  static const String _keyMapType = 'map_type';
  static const int _maxRecentSearches = 10;
  static const double _defaultSearchRadius = 500.0;

  // File names for large data (stored as files, not SharedPreferences)
  static const String _linesCacheFile = 'lines_cache.json';
  static const String _routesGraphCacheFile = 'routes_graph_cache.json';
  static const String _stopsListFile = 'stops_list.json';

  static String? _cacheDir;

  static Future<String> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/oasth_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDir = cacheDir.path;
    return _cacheDir!;
  }

  static Future<void> init() async {
    await SharedPreferences.getInstance();
    await _getCacheDir();
    await _migrateFromSharedPreferences();
  }

  /// One-time migration: move large data from SharedPreferences to files.
  static Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool migrated = false;

    // Migrate lines cache
    final linesData = prefs.getString('lines_cache');
    if (linesData != null) {
      await _writeFile(_linesCacheFile, linesData);
      await prefs.remove('lines_cache');
      migrated = true;
    }

    // Migrate routes graph cache
    final graphData = prefs.getString('routes_graph_cache');
    if (graphData != null) {
      await _writeFile(_routesGraphCacheFile, graphData);
      await prefs.remove('routes_graph_cache');
      migrated = true;
    }

    // Migrate stops list
    final stopsData = prefs.getString('keyStopsList');
    if (stopsData != null) {
      await _writeFile(_stopsListFile, stopsData);
      await prefs.remove('keyStopsList');
      migrated = true;
    }

    if (migrated) {
      debugPrint('[Cache] Migrated large data from SharedPreferences to files');
    }
  }

  static Future<void> _writeFile(String fileName, String content) async {
    final dir = await _getCacheDir();
    final file = File('$dir/$fileName');
    await file.writeAsString(content, flush: true);
  }

  static Future<String?> _readFile(String fileName) async {
    final dir = await _getCacheDir();
    final file = File('$dir/$fileName');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  static Future<void> _deleteFile(String fileName) async {
    final dir = await _getCacheDir();
    final file = File('$dir/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<bool> _fileExists(String fileName) async {
    final dir = await _getCacheDir();
    final file = File('$dir/$fileName');
    return file.exists();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _deleteFile(_linesCacheFile);
    await _deleteFile(_routesGraphCacheFile);
    await _deleteFile(_stopsListFile);
  }

  // --- Full data cache (lines + routes + stops graph) --- stored as files ---

  static Future<void> setLinesCache(String json) async {
    await _writeFile(_linesCacheFile, json);
  }

  static Future<String?> getLinesCache() async {
    return await _readFile(_linesCacheFile);
  }

  static Future<void> setRoutesGraphCache(String json) async {
    await _writeFile(_routesGraphCacheFile, json);
  }

  static Future<String?> getRoutesGraphCache() async {
    return await _readFile(_routesGraphCacheFile);
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
    await _deleteFile(_linesCacheFile);
    await _deleteFile(_routesGraphCacheFile);
    await _deleteFile(_stopsListFile);
  }

  // --- Stops list cache --- stored as file ---

  static Future<void> clearStopsList() async {
    await _deleteFile(_stopsListFile);
  }

  static Future<bool> stopsListExists() async {
    return await _fileExists(_stopsListFile);
  }

  static Future<void> setStopsList(String stopsList) async {
    await _writeFile(_stopsListFile, stopsList);
  }

  static Future<String?> getStopsList() async {
    return await _readFile(_stopsListFile);
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
