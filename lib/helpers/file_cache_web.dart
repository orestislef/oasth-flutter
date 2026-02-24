import 'package:shared_preferences/shared_preferences.dart';

/// Web implementation: stores "file" data in SharedPreferences (localStorage).
/// dart:io is not available on web, so we use SharedPreferences as fallback.

Future<void> initCacheDir() async {
  // No-op on web
}

Future<void> writeFileCache(String fileName, String content) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('file_$fileName', content);
}

Future<String?> readFileCache(String fileName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('file_$fileName');
}

Future<void> deleteFileCache(String fileName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('file_$fileName');
}

Future<bool> fileCacheExists(String fileName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('file_$fileName');
}
