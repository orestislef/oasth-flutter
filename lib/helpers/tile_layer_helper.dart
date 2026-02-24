import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';

import '../enums/map_type.dart';
import 'map_type_helper.dart';
import 'package_info_plus_helper.dart';

class TileLayerHelper {
  final BuildContext context;
  final MapType mapType;

  static Future<CacheStore>? _cacheStoreFuture;
  static final Map<String, Widget> _tileLayerCache = {};
  static const Duration cacheMaxAge = Duration(days: 30);

  final String _languageCode;
  final String _countryCode;
  final bool _isDarkMode;

  TileLayerHelper({required this.context, required this.mapType})
      : _languageCode = Localizations.localeOf(context).languageCode,
        _countryCode = Localizations.localeOf(context).countryCode ?? 'US',
        _isDarkMode = Theme.of(context).brightness == Brightness.dark;

  static Future<CacheStore> _initCacheStore() async {
    _cacheStoreFuture ??= _getCacheStore();
    return _cacheStoreFuture!;
  }

  static Future<CacheStore> _getCacheStore() async {
    final dir = await getTemporaryDirectory();
    return FileCacheStore('${dir.path}/MapTiles');
  }

  static Future<void> clearCache() async {
    try {
      final store = await _initCacheStore();
      await store.clean();
      _cacheStoreFuture = null;
      _tileLayerCache.clear();
    } catch (e) {
      debugPrint('Error clearing map tile cache: $e');
    }
  }

  String _getCacheKey() {
    return '${mapType.toString()}_${_isDarkMode}_${_languageCode}_$_countryCode';
  }

  Widget getTileLayerWidget() {
    if (kIsWeb) {
      return _buildNonCachedTileLayer();
    }
    final cacheKey = _getCacheKey();
    if (_tileLayerCache.containsKey(cacheKey)) {
      return _tileLayerCache[cacheKey]!;
    }
    final tileLayerWidget = _createTileLayerWidget();
    _tileLayerCache[cacheKey] = tileLayerWidget;
    return tileLayerWidget;
  }

  Widget _createTileLayerWidget() {
    return FutureBuilder<CacheStore>(
      future: _initCacheStore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.transparent);
        }
        if (snapshot.hasError) {
          return _buildNonCachedTileLayer();
        }
        final cacheStore = snapshot.data!;
        return _buildCachedTileLayer(cacheStore);
      },
    );
  }

  Widget _buildCachedTileLayer(CacheStore cacheStore) {
    TileLayer tileLayer;
    switch (mapType) {
      case MapType.osm:
        tileLayer = _buildOsmTileLayer(
          tileProvider: CachedTileProvider(
            store: cacheStore,
          ),
        );
        break;
      case MapType.google:
        tileLayer = _buildGoogleTileLayer(
          tileProvider: CachedTileProvider(
            store: cacheStore,
          ),
        );
        if (_isDarkMode) {
          return RepaintBoundary(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.2,
                -0.5,
                -0.3,
                0,
                255,
                -0.3,
                -0.5,
                -0.2,
                0,
                255,
                -0.3,
                -0.2,
                -0.5,
                0,
                255,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: tileLayer,
            ),
          );
        }
        break;
      case MapType.satellite:
        tileLayer = _buildSatelliteTileLayer(
          tileProvider: CachedTileProvider(
            store: cacheStore,
          ),
        );
        break;
    }
    return RepaintBoundary(child: tileLayer);
  }

  Widget _buildNonCachedTileLayer() {
    TileLayer tileLayer;
    switch (mapType) {
      case MapType.osm:
        tileLayer = _buildOsmTileLayer();
        break;
      case MapType.google:
        tileLayer = _buildGoogleTileLayer();
        if (_isDarkMode) {
          return RepaintBoundary(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.2,
                -0.5,
                -0.3,
                0,
                255,
                -0.3,
                -0.5,
                -0.2,
                0,
                255,
                -0.3,
                -0.2,
                -0.5,
                0,
                255,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: tileLayer,
            ),
          );
        }
        break;
      case MapType.satellite:
        tileLayer = _buildSatelliteTileLayer();
        break;
    }
    return RepaintBoundary(child: tileLayer);
  }

  TileLayer _buildOsmTileLayer({TileProvider? tileProvider}) {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/{style}/{z}/{x}/{y}{scale}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      additionalOptions: {
        'style': _isDarkMode ? 'dark_all' : 'light_all',
        'scale': '@2x',
      },
      userAgentPackageName:
          PackageInfoPlusHelper.packageName ?? 'com.lefkaditishub.oasth',
      tileProvider: tileProvider,
      keepBuffer: 5,
    );
  }

  TileLayer _buildGoogleTileLayer({TileProvider? tileProvider}) {
    return TileLayer(
      urlTemplate:
          'https://mt{s}.google.com/vt/lyrs=m@221097000&hl={hl}&gl={gl}&x={x}&y={y}&z={z}',
      subdomains: const ['0', '1', '2', '3'],
      additionalOptions: {
        'userAgent':
            PackageInfoPlusHelper.packageName ?? 'com.lefkaditishub.oasth',
        'hl': _languageCode,
        'gl': _countryCode,
      },
      tileProvider: tileProvider,
      keepBuffer: 5,
    );
  }

  TileLayer _buildSatelliteTileLayer({TileProvider? tileProvider}) {
    return TileLayer(
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      tileProvider: tileProvider,
      keepBuffer: 5,
    );
  }
}

class MapTileLayer extends StatelessWidget {
  const MapTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MapType>(
      future: MapTypeHelper.getMapType(),
      builder: (context, snapshot) {
        final mapType = snapshot.data ?? MapType.google;
        return TileLayerHelper(
          context: context,
          mapType: mapType,
        ).getTileLayerWidget();
      },
    );
  }
}
