import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/line_name.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/lines_and_routes_for_m_land_l_code.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
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

import '../responses/news.dart';

class ApiConfig {
  static const String baseUrl = 'https://telematics.oasth.gr/api';
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration stopArrivalsTimeout = Duration(seconds: 8);
  static const Duration busLocationTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const int maxConcurrentRequests = 5;
  
  static const Map<String, String> headers = {
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Content-Length': '0',
    'Cookie': 'PHPSESSID=9a3fb5k0rnuiutkokifbfjkv97',
    'DNT': '1',
    'Host': 'telematics.oasth.gr',
    'Origin': 'https://telematics.oasth.gr',
    'Pragma': 'no-cache',
    'Referer': 'https://telematics.oasth.gr/en/',
    'Sec-CH-UA': '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
    'Sec-CH-UA-Mobile': '?0',
    'Sec-CH-UA-Platform': '"macOS"',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
  };
}

class ApiError extends Error {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiError(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() => 'ApiError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
}

class Api {
  static final http.Client _client = (() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    httpClient.idleTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  })();

  // In-memory cache for frequently accessed data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache durations for different types of data
  static const Duration _linesCache = Duration(hours: 2);
  static const Duration _stopArrivalsCache = Duration(seconds: 30);
  static const Duration _busLocationCache = Duration(seconds: 15);
  static const Duration _routeDetailsCache = Duration(minutes: 30);

  // Semaphore for limiting concurrent requests
  static int _currentRequests = 0;

  static Future<T> _makeRequest<T>(
    Future<T> Function() request, {
    String? cacheKey,
    Duration? cacheDuration,
    int retries = ApiConfig.maxRetries,
  }) async {
    // Check cache first
    if (cacheKey != null && _isValidCache(cacheKey, cacheDuration)) {
      return _cache[cacheKey] as T;
    }

    // Limit concurrent requests
    while (_currentRequests >= ApiConfig.maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _currentRequests++;
    
    try {
      final result = await _retryRequest(request, retries);
      
      // Cache the result
      if (cacheKey != null) {
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return result;
    } finally {
      _currentRequests--;
    }
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
        
        // Exponential backoff
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
      final response = await _client
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(timeout ?? ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
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
      throw ApiError('Invalid response format: ${e.message}', endpoint: endpoint);
    }
  }

  static Future<http.Response> _httpPost(
    String url, {
    Duration? timeout,
    String? endpoint,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(timeout ?? ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
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
      throw ApiError('Invalid response format: ${e.message}', endpoint: endpoint);
    }
  }

  // Optimized getAllStops2 with parallel processing and better progress tracking
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
          if (stops.isNotEmpty) {
            return stops;
          }
        } catch (e) {
          debugPrint('Error parsing cached stops: $e');
        }
      }
    }

    // If no cached data, fetch from API
    Lines lines = await webGetLines();
    final Set<Stop> uniqueStops = {};
    int processedRoutes = 0;
    int totalRoutes = 0;
    
    // First, count total routes for accurate progress
    for (LineData line in lines.lines) {
      RoutesForLine routesForLine = await getRoutesForLine(line.lineCode!);
      totalRoutes += routesForLine.routesForLine.length;
    }
    
    DateTime startTime = DateTime.now();
    
    // Process routes in parallel batches
    for (LineData line in lines.lines) {
      RoutesForLine routesForLine = await getRoutesForLine(line.lineCode!);
      
      // Process routes in parallel (batch of 3 to avoid overwhelming the server)
      const batchSize = 3;
      for (int i = 0; i < routesForLine.routesForLine.length; i += batchSize) {
        final batch = routesForLine.routesForLine
            .skip(i)
            .take(batchSize)
            .toList();
        
        final futures = batch.map((route) => webGetStops(route.routeCode!));
        final results = await Future.wait(futures);
        
        for (WebStops webStops in results) {
          uniqueStops.addAll(webStops.stops);
          processedRoutes++;
          
          // Update progress
          _updateProgress(processedRoutes, totalRoutes, startTime);
        }
      }
    }

    final stopsList = uniqueStops.toList();
    
    // Cache the results in a separate isolate to avoid blocking UI
    compute(_cacheStops, stopsList);
    
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

  // Isolate functions for heavy computation
  static List<Stop> _parseStopsFromJson(String jsonString) {
    return List<Stop>.from(
      (jsonDecode(jsonString) as List<dynamic>?)
              ?.map((o) => Stop.fromMap(o)) ??
          [],
    );
  }

  static Future<void> _cacheStops(List<Stop> stops) async {
    await SharedPreferencesHelper.clearStopsList();
    await SharedPreferencesHelper.setStopsList(jsonEncode(stops));
  }

  // Optimized API methods with caching and better error handling
  static Future<News> getNews(String lang) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getNews&lang=$lang';
        final response = await _httpGet(url, endpoint: 'getNews');
        final List<dynamic> data = json.decode(response.body);
        return News.fromJson(data);
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
      cacheKey: 'bus_location_$routeCode',
      cacheDuration: _busLocationCache,
    );
  }

  static Future<Lines> webGetLines() async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetLines';
        final response = await _httpPost(url, endpoint: 'webGetLines');
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

  static Future<RouteDetailAndStops> webGetRoutesDetailsAndStops(String routeCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetRoutesDetailsAndStops&p1=$routeCode';
        final response = await _httpGet(url, endpoint: 'webGetRoutesDetailsAndStops');
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

  // Remaining methods with improved error handling
  static Future<StopsNameXy> getStopNameAndXY(String stopId) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getStopNameAndXY&p1=$stopId';
        final response = await _httpPost(url, endpoint: 'getStopNameAndXY');
        final List<dynamic> data = json.decode(response.body);
        return StopsNameXy.fromMap(data);
      },
    );
  }

  static Future<WebStops> webGetStops(String routeCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webGetStops&p1=$routeCode';
        final response = await _httpPost(url, endpoint: 'webGetStops');
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
        final response = await _httpPost(url, endpoint: 'webGetRoutes');
        final List<dynamic> data = json.decode(response.body);
        return Routes.fromMap(data);
      },
    );
  }

  static Future<RoutesForStop> getRoutesForStop(String stopCode) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=webRoutesForStop&p1=$stopCode';
        final response = await _httpPost(url, endpoint: 'webRoutesForStop');
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

  static Future<LinesAndRoutesForMLandLCode> getLinesAndRoutesForMasterLineAndLineCode(
      String masterLineCode, String lineId) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getLinesAndRoutesForMlandLCode&p1=$masterLineCode&p2=$lineId';
        final response = await _httpGet(url, endpoint: 'getLinesAndRoutesForMlandLCode');
        final List<dynamic> data = json.decode(response.body);
        return LinesAndRoutesForMLandLCode.fromMap(data);
      },
      cacheKey: 'ml_routes_${masterLineCode}_$lineId',
      cacheDuration: _routeDetailsCache,
    );
  }

  static Future<ScheduleDaysMasterLine> getScheduleDaysMasterLine(int masterLineId) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getScheduleDaysMasterline&p1=$masterLineId';
        final response = await _httpGet(url, endpoint: 'getScheduleDaysMasterline');
        final List<dynamic> data = json.decode(response.body);
        return ScheduleDaysMasterLine.fromMap(data);
      },
    );
  }

  static Future<SchedLines> getSchedLines(int p1, int p2, int p3) async {
    return await _makeRequest(
      () async {
        final url = '${ApiConfig.baseUrl}/?act=getSchedLines&p1=$p1&p2=$p2&p3=$p3';
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

  // Utility method to dispose resources
  static void dispose() {
    _client.close();
    clearCache();
  }
}