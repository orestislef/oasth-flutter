import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation: stores large data in IndexedDB instead of localStorage.
/// IndexedDB can store hundreds of MB, unlike localStorage's ~5MB limit.

const String _dbName = 'oasth_cache';
const String _storeName = 'files';
const int _dbVersion = 1;

Future<web.IDBDatabase> _openDB() async {
  final completer = Completer<web.IDBDatabase>();
  final request = web.window.indexedDB.open(_dbName, _dbVersion);

  request.onupgradeneeded = ((web.Event _) {
    final db = request.result as web.IDBDatabase;
    if (!db.objectStoreNames.contains(_storeName)) {
      db.createObjectStore(_storeName);
    }
  }).toJS;

  request.onsuccess = ((web.Event _) {
    completer.complete(request.result as web.IDBDatabase);
  }).toJS;

  request.onerror = ((web.Event _) {
    completer.completeError('Failed to open IndexedDB');
  }).toJS;

  return completer.future;
}

Future<void> initCacheDir() async {
  // Create the DB/store on first use
  try {
    final db = await _openDB();
    db.close();
    debugPrint('[WebCache] IndexedDB initialized');
  } catch (e) {
    debugPrint('[WebCache] IndexedDB init failed: $e');
  }
}

Future<bool> writeFileCache(String fileName, String content) async {
  try {
    final db = await _openDB();
    final tx = db.transaction(_storeName.toJS, 'readwrite');
    final store = tx.objectStore(_storeName);
    store.put(content.toJS, fileName.toJS);

    final completer = Completer<bool>();
    tx.oncomplete = ((web.Event _) {
      completer.complete(true);
    }).toJS;
    tx.onerror = ((web.Event _) {
      completer.complete(false);
    }).toJS;

    final result = await completer.future;
    db.close();
    if (result) {
      debugPrint(
          '[WebCache] Saved $fileName (${(content.length / 1024).toStringAsFixed(0)} KB)');
    } else {
      debugPrint('[WebCache] Failed to save $fileName');
    }
    return result;
  } catch (e) {
    debugPrint(
        '[WebCache] Error writing $fileName (${(content.length / 1024).toStringAsFixed(0)} KB): $e');
    return false;
  }
}

Future<String?> readFileCache(String fileName) async {
  try {
    final db = await _openDB();
    final tx = db.transaction(_storeName.toJS, 'readonly');
    final store = tx.objectStore(_storeName);
    final request = store.get(fileName.toJS);

    final completer = Completer<String?>();
    request.onsuccess = ((web.Event _) {
      final result = request.result;
      if (result != null && !result.isUndefined) {
        completer.complete((result as JSString).toDart);
      } else {
        completer.complete(null);
      }
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.complete(null);
    }).toJS;

    final value = await completer.future;
    db.close();
    return value;
  } catch (e) {
    debugPrint('[WebCache] Error reading $fileName: $e');
    return null;
  }
}

Future<void> deleteFileCache(String fileName) async {
  try {
    final db = await _openDB();
    final tx = db.transaction(_storeName.toJS, 'readwrite');
    final store = tx.objectStore(_storeName);
    store.delete(fileName.toJS);

    final completer = Completer<void>();
    tx.oncomplete = ((web.Event _) {
      completer.complete();
    }).toJS;
    tx.onerror = ((web.Event _) {
      completer.complete();
    }).toJS;

    await completer.future;
    db.close();
  } catch (e) {
    debugPrint('[WebCache] Error deleting $fileName: $e');
  }
}

Future<bool> fileCacheExists(String fileName) async {
  try {
    final db = await _openDB();
    final tx = db.transaction(_storeName.toJS, 'readonly');
    final store = tx.objectStore(_storeName);
    final request = store.count(fileName.toJS);

    final completer = Completer<bool>();
    request.onsuccess = ((web.Event _) {
      final result = request.result;
      final count =
          (result != null && !result.isUndefined) ? (result as JSNumber).toDartInt : 0;
      completer.complete(count > 0);
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.complete(false);
    }).toJS;

    final exists = await completer.future;
    db.close();
    return exists;
  } catch (e) {
    debugPrint('[WebCache] Error checking $fileName: $e');
    return false;
  }
}
