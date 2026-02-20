import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/line_name.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/lines_and_routes_for_m_land_l_code.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/news.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes.dart';
import 'package:oasth/api/responses/routes_for_line.dart';
import 'package:oasth/api/responses/routes_for_stop.dart';
import 'package:oasth/api/responses/sched_lines.dart';
import 'package:oasth/api/responses/schedule_days_master_line.dart';
import 'package:oasth/api/responses/stop_by_sip.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/api/responses/stop_name_xy.dart';
import 'package:oasth/api/responses/web_stops.dart';
import 'package:oasth/helpers/shared_preferences_helper.dart';
import 'package:oasth/helpers/string_helper.dart';
import 'package:oasth/helpers/text_broadcaster.dart';

class ApiConfig {
  static const String baseUrl = 'https://telematics.oasth.gr/api';
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration stopArrivalsTimeout = Duration(seconds: 8);
  static const Duration busLocationTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  static const Map<String, String> headers = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9,el;q=0.8',
  };
}

class ApiError extends Error {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiError(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() =>
      'ApiError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
}

class CookieClient {
  HttpClient? _httpClient;
  String _cookieString = '';
  bool _warmedUp = false;
  bool _warmingUp = false;

  HttpClient _getClient() {
    _httpClient ??= HttpClient()
      ..autoUncompress = true
      ..idleTimeout = const Duration(seconds: 30)
      ..connectionTimeout = const Duration(seconds: 15);
    return _httpClient!;
  }

  Future<void> warmup() async {
    if (_warmedUp) return;
    if (_warmingUp) {
      while (_warmingUp) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _warmingUp = true;
    try {
      final client = _getClient();
      final request =
          await client.getUrl(Uri.parse('https://telematics.oasth.gr/'));

      request.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      request.headers.set('Accept',
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');
      request.headers.set('Accept-Language', 'en-US,en;q=0.9,el;q=0.8');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close();

      final setCookies = response.headers['set-cookie'];
      if (setCookies != null && setCookies.isNotEmpty) {
        final cookies = <String>[];
        for (final cookieStr in setCookies) {
          final cookieValue = _parseCookieValue(cookieStr);
          if (cookieValue != null) {
            cookies.add(cookieValue);
          }
        }
        _cookieString = cookies.join('; ');
        debugPrint('[CookieClient] Extracted cookies: $_cookieString');
      }

      await response.drain();
      _warmedUp = true;
      debugPrint('[CookieClient] Warmup complete');
    } catch (e) {
      debugPrint('[CookieClient] Warmup failed: $e');
    } finally {
      _warmingUp = false;
    }
  }

  String? _parseCookieValue(String cookieHeader) {
    try {
      final parts = cookieHeader.split(';');
      if (parts.isEmpty) return null;
      final nameValue = parts[0].trim();
      if (!nameValue.contains('=')) return null;
      return nameValue;
    } catch (e) {
      return null;
    }
  }

  Future<http.Response> get(Uri url,
      {Map<String, String>? headers, Duration? timeout}) async {
    if (!_warmedUp) {
      await warmup();
    }

    final client = _getClient();
    final request = await client.getUrl(url);

    request.headers.set('User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    request.headers.set('Accept', 'application/json, text/plain, */*');
    request.headers.set('Accept-Language', 'en-US,en;q=0.9,el;q=0.8');
    request.headers.set('Referer', 'https://telematics.oasth.gr/');
    request.headers.set('Origin', 'https://telematics.oasth.gr');

    if (_cookieString.isNotEmpty) {
      request.headers.set('Cookie', _cookieString);
    }

    if (headers != null) {
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
    }

    final response =
        await request.close().timeout(timeout ?? ApiConfig.defaultTimeout);

    final newCookies = response.headers['set-cookie'];
    if (newCookies != null && newCookies.isNotEmpty) {
      final cookies = <String>[];
      if (_cookieString.isNotEmpty) cookies.add(_cookieString);
      for (final cookieStr in newCookies) {
        final cookieValue = _parseCookieValue(cookieStr);
        if (cookieValue != null) {
          cookies.add(cookieValue);
        }
      }
      _cookieString = cookies.join('; ');
    }

    final body = await response.transform(utf8.decoder).join();

    return http.Response(
      body,
      response.statusCode,
      headers: {
        'content-type':
            response.headers.contentType?.mimeType ?? 'application/json'
      },
      reasonPhrase: response.reasonPhrase,
    );
  }

  void reset() {
    _warmedUp = false;
    _cookieString = '';
  }

  void close() {
    _httpClient?.close();
    _httpClient = null;
  }
}

class Api {
  static final CookieClient _cookieClient = CookieClient();
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _cookieClient.warmup();
    _initialized = true;
  }

  static const Duration _linesCache = Duration(hours: 2);
  static const Duration _stopArrivalsCache = Duration(seconds: 30);
  static const Duration _routeDetailsCache = Duration(minutes: 30);

  static Future<T> _makeRequest<T>(
    Future<T> Function() request, {
    String? cacheKey,
    Duration? cacheDuration,
    int retries = ApiConfig.maxRetries,
  }) async {
    if (cacheKey != null && _isValidCache(cacheKey, cacheDuration)) {
      return _cache[cacheKey] as T;
    }

    final result = await _retryRequest(request, retries);

    if (cacheKey != null) {
      _cache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
    }

    return result;
  }

  static Future<T> _retryRequest<T>(
    Future<T> Function() request,
    int maxRetries,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
      }
    }
  }

  static bool _isValidCache(String key, Duration? duration) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    if (duration == null) return false;
    return DateTime.now().difference(_cacheTimestamps[key]!) < duration;
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void clearCacheForKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  static Future<http.Response> _httpGet(
    String url, {
    Duration? timeout,
    String? endpoint,
  }) async {
    try {
      await _ensureInitialized();

      final response = await _cookieClient
          .get(Uri.parse(url), headers: ApiConfig.headers)
          .timeout(timeout ?? ApiConfig.defaultTimeout);

      if (response.statusCode == 401) {
        debugPrint('[API] 401 for $url, resetting session and retrying...');
        _cookieClient.reset();
        await _ensureInitialized();
        final retryResponse = await _cookieClient
            .get(Uri.parse(url), headers: ApiConfig.headers, timeout: timeout)
            .timeout(timeout ?? ApiConfig.defaultTimeout);

        if (retryResponse.statusCode != 200) {
          throw ApiError(
            'HTTP ${retryResponse.statusCode}: ${retryResponse.reasonPhrase}',
            statusCode: retryResponse.statusCode,
            endpoint: endpoint,
          );
        }
        return retryResponse;
      }

      if (response.statusCode != 200) {
        debugPrint(
          '[API] ${response.statusCode} ${response.reasonPhrase} for $url\n'
          'Endpoint: ${endpoint ?? 'unknown'}\n'
          'Body: ${response.body}',
        );
        throw ApiError(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      return response;
    } on SocketException {
      throw ApiError('No internet connection', endpoint: endpoint);
    } on HttpException catch (e) {
      throw ApiError('HTTP error: ${e.message}', endpoint: endpoint);
    } on FormatException catch (e) {
      throw ApiError('Invalid response format: ${e.message}',
          endpoint: endpoint);
    } on TimeoutException {
      throw ApiError('Request timed out', endpoint: endpoint);
    }
  }

  // --- All Stops (heavy operation with progress) ---

  static Future<List<Stop>> getAllStops2() async {
    return await _makeRequest(
      () async => _getAllStops2Internal(),
      cacheKey: 'all_stops',
      cacheDuration: const Duration(hours: 6),
    );
  }

  static Future<List<Stop>> _getAllStops2Internal() async {
    await SharedPreferencesHelper.init();
    bool exists = await SharedPreferencesHelper.stopsListExists();

    if (exists) {
      String? stopsList = await SharedPreferencesHelper.getStopsList();
      if (stopsList != null) {
        try {
          List<Stop> stops = await compute(_parseStopsFromJson, stopsList);
          if (stops.isNotEmpty) return stops;
        } catch (e) {
          debugPrint('Error parsing cached stops: $e');
        }
      }
    }

    // Fetch from API - single pass: collect all routes first
    Lines lines = await webGetLines();
    final Map<String, RoutesForLine> allRoutes = {};
    int totalRoutes = 0;

    for (LineData line in lines.lines) {
      final routesForLine = await getRoutesForLine(line.lineCode);
      allRoutes[line.lineCode] = routesForLine;
      totalRoutes += routesForLine.routesForLine.length;
    }

    final Set<Stop> uniqueStops = {};
    int processedRoutes = 0;
    DateTime startTime = DateTime.now();

    // Process routes in parallel batches
    for (final entry in allRoutes.entries) {
      final routes = entry.value.routesForLine;
      const batchSize = 3;

      for (int i = 0; i < routes.length; i += batchSize) {
        final batch = routes.skip(i).take(batchSize).toList();
        final futures = batch.map((route) => webGetStops(route.routeCode));
        final results = await Future.wait(futures);

        for (WebStops webStops in results) {
          uniqueStops.addAll(webStops.stops);
          processedRoutes++;
          if (processedRoutes > 0) {
            _updateProgress(processedRoutes, totalRoutes, startTime);
          }
        }
      }
    }

    final stopsList = uniqueStops.toList();
    _cacheStops(stopsList);
    return stopsList;
  }

  static void _updateProgress(int processed, int total, DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    final percentage = (processed / total * 100);
    final estimatedTotal = elapsed * (total / processed);
    final remaining = estimatedTotal - elapsed;

    final progressMessage = '${percentage.toStringAsFixed(1)}%\n'
        '${StringHelper.formatSeconds(remaining.inSeconds)}\n'
        '$processed/$total routes';

    TextBroadcaster.addText(progressMessage);
  }

  static List<Stop> _parseStopsFromJson(String jsonString) {
    return List<Stop>.from(
      (jsonDecode(jsonString) as List<dynamic>?)?.map((o) => Stop.fromMap(o)) ??
          [],
    );
  }

  static Future<void> _cacheStops(List<Stop> stops) async {
    await SharedPreferencesHelper.clearStopsList();
    await SharedPreferencesHelper.setStopsList(
      jsonEncode(stops.map((s) => s.toMap()).toList()),
    );
  }

  // --- API Methods ---

  static Future<News> getNews(String lang) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getNews&lang=$lang';
        final response = await _httpGet(url, endpoint: 'getNews');
        final List<dynamic> data = json.decode(response.body);
        return News.fromMap(data);
      },
      cacheKey: 'news_$lang',
      cacheDuration: const Duration(minutes: 15),
    );
  }

  static Future<StopArrivals> getStopArrivals(String stopId) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getStopArrivals&p1=$stopId';
        final response = await _httpGet(
          url,
          timeout: ApiConfig.stopArrivalsTimeout,
          endpoint: 'getStopArrivals',
        );
        final List<dynamic> data = json.decode(response.body);
        return StopArrivals.fromMap(data);
      },
      cacheKey: 'arrivals_$stopId',
      cacheDuration: _stopArrivalsCache,
    );
  }

  static Future<BusLocation> getBusLocations(String routeCode) async {
    // No caching for real-time bus locations
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getBusLocation&p1=$routeCode';
        final response = await _httpGet(
          url,
          timeout: ApiConfig.busLocationTimeout,
          endpoint: 'getBusLocation',
        );
        final List<dynamic> data = json.decode(response.body);
        return BusLocation.fromMap(data);
      },
    );
  }

  static Future<Lines> webGetLines() async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetLines';
        final response = await _httpGet(url, endpoint: 'webGetLines');
        final List<dynamic> data = json.decode(response.body);
        return Lines.fromMap(data);
      },
      cacheKey: 'lines',
      cacheDuration: _linesCache,
    );
  }

  static Future<RoutesForLine> getRoutesForLine(String lineCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getRoutesForLine&p1=$lineCode';
        final response = await _httpGet(url, endpoint: 'getRoutesForLine');
        final List<dynamic> data = json.decode(response.body);
        return RoutesForLine.fromMap(data);
      },
      cacheKey: 'routes_for_line_$lineCode',
      cacheDuration: _routeDetailsCache,
    );
  }

  static Future<RouteDetailAndStops> webGetRoutesDetailsAndStops(
      String routeCode) async {
    return await _makeRequest(
      () async {
        final url =
            '${ApiConfig.baseUrl}/?act=webGetRoutesDetailsAndStops&p1=$routeCode';
        final response =
            await _httpGet(url, endpoint: 'webGetRoutesDetailsAndStops');
        final Map<String, dynamic> data = json.decode(response.body);
        return RouteDetailAndStops.fromMap(data);
      },
      cacheKey: 'route_details_$routeCode',
      cacheDuration: _routeDetailsCache,
    );
  }

  static Future<LinesWithMasterLineInfo> webGetLinesWithMLInfo() async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetLinesWithMLInfo';
        final response = await _httpGet(url, endpoint: 'webGetLinesWithMLInfo');
        final List<dynamic> data = json.decode(response.body);
        return LinesWithMasterLineInfo.fromMap(data);
      },
      cacheKey: 'lines_with_ml_info',
      cacheDuration: _linesCache,
    );
  }

  static Future<StopsNameXy> getStopNameAndXY(String stopId) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getStopNameAndXY&p1=$stopId';
        final response = await _httpGet(url, endpoint: 'getStopNameAndXY');
        final List<dynamic> data = json.decode(response.body);
        return StopsNameXy.fromMap(data);
      },
    );
  }

  static Future<WebStops> webGetStops(String routeCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetStops&p1=$routeCode';
        final response = await _httpGet(url, endpoint: 'webGetStops');
        final List<dynamic> data = json.decode(response.body);
        return WebStops.fromMap(data);
      },
      cacheKey: 'stops_$routeCode',
      cacheDuration: _routeDetailsCache,
    );
  }

  static Future<Routes> webGetRoutes(String p1) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetRoutes&p1=$p1';
        final response = await _httpGet(url, endpoint: 'webGetRoutes');
        final List<dynamic> data = json.decode(response.body);
        return Routes.fromMap(data);
      },
    );
  }

  static Future<RoutesForStop> getRoutesForStop(String stopCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webRoutesForStop&p1=$stopCode';
        final response = await _httpGet(url, endpoint: 'webRoutesForStop');
        final List<dynamic> data = json.decode(response.body);
        return RoutesForStop.fromMap(data);
      },
      cacheKey: 'routes_for_stop_$stopCode',
      cacheDuration: const Duration(minutes: 10),
    );
  }

  static Future<LineName> getLineName(String lineCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getLineName&p1=$lineCode';
        final response = await _httpGet(url, endpoint: 'getLineName');
        final List<dynamic> data = json.decode(response.body);
        return LineName.fromMap(data);
      },
      cacheKey: 'line_name_$lineCode',
      cacheDuration: _linesCache,
    );
  }

  static Future<LinesAndRoutesForMLandLCode>
      getLinesAndRoutesForMasterLineAndLineCode(
          String masterLineCode, String lineId) async {
    return await _makeRequest(
      () async {
        final url =
            '${ApiConfig.baseUrl}/?act=getLinesAndRoutesForMlandLCode&p1=$masterLineCode&p2=$lineId';
        final response =
            await _httpGet(url, endpoint: 'getLinesAndRoutesForMlandLCode');
        final List<dynamic> data = json.decode(response.body);
        return LinesAndRoutesForMLandLCode.fromMap(data);
      },
      cacheKey: 'ml_routes_${masterLineCode}_$lineId',
      cacheDuration: _routeDetailsCache,
    );
  }

  static Future<ScheduleDaysMasterLine> getScheduleDaysMasterLine(
      int masterLineId) async {
    return await _makeRequest(
      () async {
        final url =
            '${ApiConfig.baseUrl}/?act=getScheduleDaysMasterline&p1=$masterLineId';
        final response =
            await _httpGet(url, endpoint: 'getScheduleDaysMasterline');
        final List<dynamic> data = json.decode(response.body);
        return ScheduleDaysMasterLine.fromMap(data);
      },
    );
  }

  static Future<SchedLines> getSchedLines(int p1, int p2, int p3) async {
    return await _makeRequest(
      () async {
        final url =
            '${ApiConfig.baseUrl}/?act=getSchedLines&p1=$p1&p2=$p2&p3=$p3';
        final response = await _httpGet(url, endpoint: 'getSchedLines');
        final Map<String, dynamic> data = json.decode(response.body);
        return SchedLines.fromMap(data);
      },
    );
  }

  static Future<StopBySip> getStopBySIP(String sip) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getStopBySIP&sip=$sip';
        final response = await _httpGet(url, endpoint: 'getStopBySIP');
        final Map<String, dynamic> data = json.decode(response.body);
        return StopBySip.fromMap(data);
      },
      cacheKey: 'stop_by_sip_$sip',
      cacheDuration: const Duration(minutes: 30),
    );
  }

  static void dispose() {
    _cookieClient.close();
    clearCache();
  }
}
