import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Mobile/desktop implementation: stores large data as files on disk.

String? _cacheDir;

Future<void> initCacheDir() async {
  if (_cacheDir != null) return;
  final dir = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${dir.path}/oasth_cache');
  if (!await cacheDir.exists()) {
    await cacheDir.create(recursive: true);
  }
  _cacheDir = cacheDir.path;
}

Future<void> writeFileCache(String fileName, String content) async {
  await initCacheDir();
  final file = File('$_cacheDir/$fileName');
  await file.writeAsString(content, flush: true);
}

Future<String?> readFileCache(String fileName) async {
  await initCacheDir();
  final file = File('$_cacheDir/$fileName');
  if (await file.exists()) return await file.readAsString();
  return null;
}

Future<void> deleteFileCache(String fileName) async {
  await initCacheDir();
  final file = File('$_cacheDir/$fileName');
  if (await file.exists()) await file.delete();
}

Future<bool> fileCacheExists(String fileName) async {
  await initCacheDir();
  final file = File('$_cacheDir/$fileName');
  return file.exists();
}
