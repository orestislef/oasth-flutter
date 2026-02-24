import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  static String get baseUrl =>
      kIsWeb ? 'api-proxy.php' : 'https://telematics.oasth.gr/api';
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
  http.Client? _httpClient;
  String _phpSessionId = '';
  String _csrfToken = '';
  String _lastTokenDate = '';
  bool _warmedUp = false;
  bool _warmingUp = false;

  http.Client _getClient() {
    _httpClient ??= http.Client();
    return _httpClient!;
  }

  /// Get current time in Greece timezone (EET/EEST with proper DST).
  DateTime _getGreeceTime() {
    final utcNow = DateTime.now().toUtc();

    // EU DST: last Sunday of March 01:00 UTC to last Sunday of October 01:00 UTC
    var marchDay = DateTime.utc(utcNow.year, 3, 31);
    while (marchDay.weekday != DateTime.sunday) {
      marchDay = marchDay.subtract(const Duration(days: 1));
    }
    final dstStart =
        DateTime.utc(marchDay.year, marchDay.month, marchDay.day, 1);

    var octDay = DateTime.utc(utcNow.year, 10, 31);
    while (octDay.weekday != DateTime.sunday) {
      octDay = octDay.subtract(const Duration(days: 1));
    }
    final dstEnd = DateTime.utc(octDay.year, octDay.month, octDay.day, 1);

    final isDst = utcNow.isAfter(dstStart) && utcNow.isBefore(dstEnd);
    return utcNow.add(Duration(hours: isDst ? 3 : 2));
  }

  String _getGreeceDateStr() {
    final gt = _getGreeceTime();
    return '${gt.year}${gt.month.toString().padLeft(2, '0')}${gt.day.toString().padLeft(2, '0')}';
  }

  /// Generate CSRF token from secret phrase + Greece timezone date (SHA-256).
  String _generateCsrfToken() {
    final dateStr = _getGreeceDateStr();
    final phrase = 'o@sthW38T3l3m@t!c\$\$-1$dateStr';
    final token = sha256.convert(utf8.encode(phrase)).toString();

    _lastTokenDate = dateStr;
    debugPrint('[CookieClient] Generated CSRF token for date: $dateStr');
    return token;
  }

  /// Regenerate the token if the Greece date has changed.
  void _refreshTokenIfNeeded() {
    final dateStr = _getGreeceDateStr();
    if (dateStr != _lastTokenDate) {
      debugPrint('[CookieClient] Date changed, regenerating CSRF token');
      _csrfToken = _generateCsrfToken();
    }
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
      // Generate CSRF token
      _csrfToken = _generateCsrfToken();

      // Call webGetLangs to obtain PHPSESSID cookie
      final client = _getClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}?act=webGetLangs'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9,el;q=0.8',
          'Referer': 'https://telematics.oasth.gr/',
          'Origin': 'https://telematics.oasth.gr',
          'Connection': 'keep-alive',
        },
      ).timeout(ApiConfig.defaultTimeout);

      _extractPhpSessionId(response.headers['set-cookie']);

      _warmedUp = true;
      debugPrint(
          '[CookieClient] Warmup complete - PHPSESSID: ${_phpSessionId.isNotEmpty ? 'obtained' : 'MISSING'}');
    } catch (e, stack) {
      debugPrint('[CookieClient] Warmup failed: $e');
      debugPrint('[CookieClient] Stack: $stack');
    } finally {
      _warmingUp = false;
    }
  }

  void _extractPhpSessionId(String? setCookieHeader) {
    if (setCookieHeader == null) return;
    final cookies = setCookieHeader.split(',');
    for (final cookieStr in cookies) {
      if (cookieStr.contains('PHPSESSID')) {
        final match = RegExp(r'PHPSESSID=([^;]+)').firstMatch(cookieStr);
        if (match != null) {
          _phpSessionId = match.group(1)!;
          debugPrint(
              '[CookieClient] Got PHPSESSID: ${_phpSessionId.substring(0, 8)}...');
        }
      }
    }
  }

  Future<http.Response> get(Uri url,
      {Map<String, String>? headers, Duration? timeout}) async {
    if (!_warmedUp) {
      await warmup();
    }

    _refreshTokenIfNeeded();

    final client = _getClient();
    final requestHeaders = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9,el;q=0.8',
      'Referer': 'https://telematics.oasth.gr/',
      'Origin': 'https://telematics.oasth.gr',
      'X-CSRF-TOKEN': _csrfToken,
      'Connection': 'keep-alive',
    };

    if (_phpSessionId.isNotEmpty) {
      requestHeaders['Cookie'] = 'PHPSESSID=$_phpSessionId';
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    final response = await client
        .get(url, headers: requestHeaders)
        .timeout(timeout ?? ApiConfig.defaultTimeout);

    // Update PHPSESSID if a new one is returned
    _extractPhpSessionId(response.headers['set-cookie']);

    return response;
  }

  void reset() {
    _warmedUp = false;
    _phpSessionId = '';
    _csrfToken = '';
    _lastTokenDate = '';
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
    const maxAttempts = 3;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('[API] Attempt ${attempt + 1}/$maxAttempts for $url');
          _cookieClient.reset();
          _initialized = false;
        }

        await _ensureInitialized();

        final response = await _cookieClient
            .get(Uri.parse(url), headers: ApiConfig.headers, timeout: timeout)
            .timeout(timeout ?? ApiConfig.defaultTimeout);

        if (response.statusCode == 401) {
          debugPrint(
              '[API] 401 for $url (attempt ${attempt + 1}/$maxAttempts)');
          if (attempt < maxAttempts - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          throw ApiError(
            'HTTP 401: Unauthorized',
            statusCode: 401,
            endpoint: endpoint,
          );
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
      } on TimeoutException {
        throw ApiError('Request timed out', endpoint: endpoint);
      } on FormatException catch (e) {
        throw ApiError('Invalid response format: ${e.message}',
            endpoint: endpoint);
      } on ApiError {
        rethrow;
      } catch (e) {
        throw ApiError('Network error: $e', endpoint: endpoint);
      }
    }

    throw ApiError('Max retries exceeded', endpoint: endpoint);
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
        final url = '${ApiConfig.baseUrl}?act=getNews&lang=$lang';
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
        final url = '${ApiConfig.baseUrl}?act=getStopArrivals&p1=$stopId';
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
        final url = '${ApiConfig.baseUrl}?act=getBusLocation&p1=$routeCode';
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
        final url = '${ApiConfig.baseUrl}?act=webGetLines';
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
        final url = '${ApiConfig.baseUrl}?act=getRoutesForLine&p1=$lineCode';
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
            '${ApiConfig.baseUrl}?act=webGetRoutesDetailsAndStops&p1=$routeCode';
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
        final url = '${ApiConfig.baseUrl}?act=webGetLinesWithMLInfo';
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
        final url = '${ApiConfig.baseUrl}?act=getStopNameAndXY&p1=$stopId';
        final response = await _httpGet(url, endpoint: 'getStopNameAndXY');
        final List<dynamic> data = json.decode(response.body);
        return StopsNameXy.fromMap(data);
      },
    );
  }

  static Future<WebStops> webGetStops(String routeCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}?act=webGetStops&p1=$routeCode';
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
        final url = '${ApiConfig.baseUrl}?act=webGetRoutes&p1=$p1';
        final response = await _httpGet(url, endpoint: 'webGetRoutes');
        final List<dynamic> data = json.decode(response.body);
        return Routes.fromMap(data);
      },
    );
  }

  static Future<RoutesForStop> getRoutesForStop(String stopCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}?act=webRoutesForStop&p1=$stopCode';
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
        final url = '${ApiConfig.baseUrl}?act=getLineName&p1=$lineCode';
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
            '${ApiConfig.baseUrl}?act=getLinesAndRoutesForMlandLCode&p1=$masterLineCode&p2=$lineId';
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
            '${ApiConfig.baseUrl}?act=getScheduleDaysMasterline&p1=$masterLineId';
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
            '${ApiConfig.baseUrl}?act=getSchedLines&p1=$p1&p2=$p2&p3=$p3';
        final response = await _httpGet(url, endpoint: 'getSchedLines');
        final Map<String, dynamic> data = json.decode(response.body);
        return SchedLines.fromMap(data);
      },
    );
  }

  static Future<StopBySip> getStopBySIP(String sip) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}?act=getStopBySIP&sip=$sip';
        final response = await _httpGet(url, endpoint: 'getStopBySIP');
        final Map<String, dynamic> data = json.decode(response.body);
        return StopBySip.fromMap(data);
      },
      cacheKey: 'stop_by_sip_$sip',
      cacheDuration: const Duration(minutes: 30),
    );
  }
// --- Offline Data: Full Download + Disk Cache ---

  /// Try to load lines/routes/stops graph from disk into in-memory cache.
  /// Returns true if disk cache was valid and loaded.
  static Future<bool> tryLoadFromDisk() async {
    try {
      final isValid = await SharedPreferencesHelper.isCacheValid();
      if (!isValid) return false;

      final linesJson = await SharedPreferencesHelper.getLinesCache();
      final graphJson = await SharedPreferencesHelper.getRoutesGraphCache();
      if (linesJson == null || graphJson == null) return false;

      _populateInMemoryCacheFromDisk(linesJson, graphJson);
      debugPrint('[Api] Loaded full data graph from disk cache');
      return true;
    } catch (e) {
      debugPrint('[Api] Failed to load disk cache: $e');
      return false;
    }
  }

  /// Parses disk-cached JSON and fills the in-memory _cache map so that
  /// subsequent getLines/getRoutesForLine/webGetStops calls return instantly.
  static void _populateInMemoryCacheFromDisk(
      String linesJson, String graphJson) {
    // Parse lines
    final List<dynamic> linesData = json.decode(linesJson);
    final lines = Lines.fromMap(linesData);
    _cache['lines'] = lines;
    _cacheTimestamps['lines'] = DateTime.now();

    // Parse routes graph: { lineCode: { routes: [ { routeCode, stops: [...] } ] } }
    final Map<String, dynamic> graph = json.decode(graphJson);
    final Set<Stop> allStops = {};

    for (final entry in graph.entries) {
      final lineCode = entry.key;
      final lineData = entry.value as Map<String, dynamic>;
      final routesList = lineData['routes'] as List<dynamic>;

      // Populate routes_for_line cache
      final lineRoutes = routesList.map((r) {
        final routeMap = r as Map<String, dynamic>;
        return LineRoute(
          routeCode: routeMap['route_code']?.toString() ?? '',
          routeDescription: routeMap['route_descr']?.toString() ?? '',
          routeDescriptionEng: routeMap['route_descr_eng']?.toString() ?? '',
        );
      }).toList();
      _cache['routes_for_line_$lineCode'] =
          RoutesForLine(routesForLine: lineRoutes);
      _cacheTimestamps['routes_for_line_$lineCode'] = DateTime.now();

      // Populate stops per route cache
      for (final routeMap in routesList) {
        final rMap = routeMap as Map<String, dynamic>;
        final routeCode = rMap['route_code']?.toString() ?? '';
        final stopsData = rMap['stops'] as List<dynamic>? ?? [];
        final stops = stopsData
            .map((s) => Stop.fromMap(s as Map<String, dynamic>))
            .toList();
        _cache['stops_$routeCode'] = WebStops(stops: stops);
        _cacheTimestamps['stops_$routeCode'] = DateTime.now();
        allStops.addAll(stops);
      }
    }

    // Also populate the flat all_stops cache
    _cache['all_stops'] = allStops.toList();
    _cacheTimestamps['all_stops'] = DateTime.now();
  }

  /// Downloads ALL lines, routes, and stops from API.
  /// Saves the full relational graph to disk for offline use.
  /// Returns flat stop list for backward compatibility.
  static Future<List<Stop>> downloadAllData() async {
    // Check disk cache first
    try {
      final isValid = await SharedPreferencesHelper.isCacheValid();
      if (isValid) {
        final linesJson = await SharedPreferencesHelper.getLinesCache();
        final graphJson = await SharedPreferencesHelper.getRoutesGraphCache();
        if (linesJson != null && graphJson != null) {
          _populateInMemoryCacheFromDisk(linesJson, graphJson);
          debugPrint('[Api] downloadAllData: using valid disk cache');
          return _cache['all_stops'] as List<Stop>? ?? [];
        }
      }
    } catch (e) {
      debugPrint('[Api] Disk cache check failed, will re-download: $e');
    }

    // Download from API
    await _ensureInitialized();

    final Lines lines = await webGetLines();
    final Map<String, dynamic> routesGraph = {};
    final Set<Stop> allStops = {};
    int totalRoutes = 0;

    // First pass: collect all routes per line
    final Map<String, RoutesForLine> allRoutes = {};
    for (final line in lines.lines) {
      final routesForLine = await getRoutesForLine(line.lineCode);
      allRoutes[line.lineCode] = routesForLine;
      totalRoutes += routesForLine.routesForLine.length;
    }

    int processedRoutes = 0;
    final DateTime startTime = DateTime.now();

    // Second pass: fetch stops for each route
    for (final line in lines.lines) {
      final routesForLine = allRoutes[line.lineCode]!;
      final routesList = <Map<String, dynamic>>[];

      final routes = routesForLine.routesForLine;
      const batchSize = 3;

      for (int i = 0; i < routes.length; i += batchSize) {
        final batch = routes.skip(i).take(batchSize).toList();
        final futures = batch.map((route) => webGetStops(route.routeCode));
        final results = await Future.wait(futures);

        for (int j = 0; j < batch.length; j++) {
          final route = batch[j];
          final webStops = results[j];
          allStops.addAll(webStops.stops);

          routesList.add({
            'route_code': route.routeCode,
            'route_descr': route.routeDescription,
            'route_descr_eng': route.routeDescriptionEng,
            'stops': webStops.stops.map((s) => s.toMap()).toList(),
          });

          processedRoutes++;
          if (processedRoutes > 0) {
            _updateProgress(processedRoutes, totalRoutes, startTime);
          }
        }
      }

      routesGraph[line.lineCode] = {
        'routes': routesList,
      };
    }

    // Save to disk
    final linesJson = json.encode(lines.lines.map((l) => l.toMap()).toList());
    final graphJson = json.encode(routesGraph);

    await SharedPreferencesHelper.setLinesCache(linesJson);
    await SharedPreferencesHelper.setRoutesGraphCache(graphJson);
    await SharedPreferencesHelper.setCacheTimestamp(
        DateTime.now().millisecondsSinceEpoch);

    // Also save flat stops list for backward compat
    final stopsList = allStops.toList();
    await _cacheStops(stopsList);

    // Populate in-memory cache
    _cache['all_stops'] = stopsList;
    _cacheTimestamps['all_stops'] = DateTime.now();

    debugPrint(
        '[Api] downloadAllData complete: ${lines.lines.length} lines, $totalRoutes routes, ${stopsList.length} stops');
    return stopsList;
  }

  static void dispose() {
    _cookieClient.close();
    clearCache();
  }
}
