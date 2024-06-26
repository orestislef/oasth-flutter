import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:oasth/api/responses/bus_location.dart';
import 'package:oasth/api/responses/line_name.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/lines_and_routes_for_m_land_l_code.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes.dart';
import 'package:oasth/api/responses/routes_for_line.dart' as rfl;
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

const Map<String, String> header = {
  'Accept': 'application/json, text/javascript, */*; q=0.01',
  'Accept-Encoding': 'gzip, deflate, br',
  'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
  'Connection': 'keep-alive',
  'Content-Length': '0',
  'Cookie':
      'PHPSESSID=oj56ov5krms4v3e9ab8k6fn0b6; _ga=GA1.1.1207430914.1706778348; lineDetails=cl_61_73_12||01X; stops=c2_1649||%20%CE%9C%CE%97%CE%A7%CE%91%CE%9D%CE%9F%CE%A5%CE%A1%CE%93%CE%95%CE%99%CE%9F%20%CE%9F.%CE%A3.%CE%95.||40.652490100000001,22.9115067||13006; _ga_L492Z0RV7F=GS1.1.1706778348.1.1.1706778633.0.0.0',
  'Host': 'telematics.oasth.gr',
  'Origin': 'https://telematics.oasth.gr',
  'Referer': 'https://telematics.oasth.gr/',
  'Sec-Fetch-Dest': 'empty',
  'Sec-Fetch-Mode': 'cors',
  'Sec-Fetch-Site': 'same-origin',
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  'sec-ch-ua':
      '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
  'sec-ch-ua-mobile': '?1',
  'sec-ch-ua-platform': '"Android"',
};
const String baseUrl = 'https://telematics.oasth.gr/api';

class Api {
  static Future<List<Stop>> getAllStops2() async {
    List<Stop> stops = [];
    await SharedPreferencesHelper.init();
    bool exists = await SharedPreferencesHelper.stopsListExists();
    if (exists) {
      String? stopsList = await SharedPreferencesHelper.getStopsList();
      if (stopsList != null) {
        stops = List<Stop>.from(
          (jsonDecode(stopsList) as List<dynamic>?)
                  ?.map((o) => Stop.fromMap(o)) ??
              [],
        );
      }
    }

    if (stops.isNotEmpty) {
      return stops;
    }

    Lines lines = await Api.webGetLines();
    int loadedStops = 0;
    int totalStops = 16019; // Total number of stops
    int totalBytesDownloaded = 0;
    DateTime startTime = DateTime.now();

    for (LineData line in lines.lines) {
      RoutesForLine routesForLine = await Api.getRoutesForLine(line.lineCode!);
      for (rfl.Route route in routesForLine.routesForLine) {
        WebStops webStops = await Api.webGetStops(route.routeCode!);
        stops.addAll(webStops.stops);
        loadedStops += webStops.stops.length;
        totalBytesDownloaded += webStops.stops.fold<int>(0,
            (previous, stop) => previous + utf8.encode(stop.toString()).length);

        // Calculate and show progress
        DateTime currentTime = DateTime.now();
        Duration elapsedTime = currentTime.difference(startTime);
        double estimatedTimeRemainingSeconds =
            (elapsedTime.inSeconds / loadedStops) * (totalStops - loadedStops);
        double percentage = loadedStops / totalStops * 100;
        debugPrint('Progress: $percentage%');
        String progressMessage =
            '${percentage.toStringAsFixed(2)}% (${totalBytesDownloaded ~/ 1024} KB)'
            '\n${StringHelper.formatSeconds(estimatedTimeRemainingSeconds.toInt())}';
        if (kDebugMode) {
          progressMessage += '\n$loadedStops/$totalStops';
        }
        TextBroadcaster.addText(progressMessage);
      }
    }

    // Clear duplicates
    List<Stop> uniqueStops = stops.toSet().toList();

    await SharedPreferencesHelper.clearStopsList();
    await SharedPreferencesHelper.setStopsList(jsonEncode(uniqueStops));
    return uniqueStops;
  }

  static Future<List<Stop>> getAllStops() async {
    List<Stop> stops = [];
    await SharedPreferencesHelper.init();
    bool exists = await SharedPreferencesHelper.stopsListExists();
    if (exists) {
      String? stopsList = await SharedPreferencesHelper.getStopsList();
      if (stopsList != null) {
        stops = List<Stop>.from(
          (jsonDecode(stopsList) as List<dynamic>?)
                  ?.map((o) => Stop.fromMap(o)) ??
              [],
        );
        return stops;
      }
    }

    if (stops.isNotEmpty) {
      return stops;
    }

    Lines lines = await Api.webGetLines();
    for (LineData line in lines.lines) {
      RouteDetailAndStops routeDetailAndStops =
          await Api.webGetRoutesDetailsAndStops(line.lineCode!);
      stops.addAll(routeDetailAndStops.stops);
    }
    //clear from duplicate stops
    List<Stop> uniqueStops = [];
    for (var stop in stops) {
      if (!uniqueStops.any((element) => element.stopID == stop.stopID)) {
        uniqueStops.add(stop);
      }
    }

    await SharedPreferencesHelper.clearStopsList();
    await SharedPreferencesHelper.setStopsList(jsonEncode(uniqueStops));
    return uniqueStops;
  }

  static Future<News> getNews(String lang) async {
    final url = Uri.parse('$baseUrl/?act=getNews&lang=$lang');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        News news = News.fromJson(data);
        return news;
      } else {
        throw Exception('Failed to get News');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<StopsNameXy> getStopNameAndXY(String p1) async {
    final url = Uri.parse('$baseUrl/?act=getStopNameAndXY&p1=$p1');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        StopsNameXy stopsNameXy = StopsNameXy.fromMap(data);
        return stopsNameXy;
      } else {
        throw Exception('Failed to web Get Stop name and xy');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<WebStops> webGetStops(String p1) async {
    final url = Uri.parse('$baseUrl/?act=webGetStops&p1=$p1');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        WebStops webStops = WebStops.fromMap(data);
        return webStops;
      } else {
        throw Exception('Failed to web Get Stops');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<Routes> webGetRoutes(String p1) async {
    final url = Uri.parse('$baseUrl/?act=webGetRoutes&p1=$p1');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        Routes routes = Routes.fromMap(data);
        return routes;
      } else {
        throw Exception('Failed to web Get Routes');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<RoutesForStop> getRoutesForStop(String stopCode) async {
    final url = Uri.parse('$baseUrl/?act=webRoutesForStop&p1=$stopCode');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        RoutesForStop routesForStop = RoutesForStop.fromMap(data);
        return routesForStop;
      } else {
        throw Exception('Failed to get Routes For Stop');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<Lines> webGetLines() async {
    final url = Uri.parse('$baseUrl/?act=webGetLines');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        Lines lines = Lines.fromMap(data);
        return lines;
      } else {
        throw Exception('Failed to web Get Lines');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<StopArrivals> getStopArrivals(String p1) async {
    final url = Uri.parse('$baseUrl/?act=getStopArrivals&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        StopArrivals stopArrivals = StopArrivals.fromMap(data);
        return stopArrivals;
      } else {
        throw Exception('Failed to get Stop Arrivals');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<RouteDetailAndStops> webGetRoutesDetailsAndStops(
      String p1) async {
    final url = Uri.parse('$baseUrl/?act=webGetRoutesDetailsAndStops&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        RouteDetailAndStops routeDetailAndStops =
            RouteDetailAndStops.fromMap(data);
        return routeDetailAndStops;
      } else {
        throw Exception('Failed to web Get Routes Details And Stops');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<LineName> getLineName(String p1) async {
    final url = Uri.parse('$baseUrl/?act=getLineName&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        LineName lineNames = LineName.fromMap(data);
        return lineNames;
      } else {
        throw Exception('Failed to get Line Name');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<LinesAndRoutesForMLandLCode>
      getLinesAndRoutesForMasterLineAndLineCode(String p1, String p2) async {
    final url =
        Uri.parse('$baseUrl/?act=getLinesAndRoutesForMlandLCode&p1=$p1&p2=$p2');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        LinesAndRoutesForMLandLCode linesAndRoutesForMLandLCodes =
            LinesAndRoutesForMLandLCode.fromMap(data);
        return linesAndRoutesForMLandLCodes;
      } else {
        throw Exception(
            'Failed to get Lines And Routes For Master Line And Line Code');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<RoutesForLine> getRoutesForLine(String p1) async {
    final url = Uri.parse('$baseUrl/?act=getRoutesForLine&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        RoutesForLine routesFroLine = RoutesForLine.fromMap(data);
        return routesFroLine;
      } else {
        throw Exception('Failed to get Routes For Line');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<ScheduleDaysMasterLine> getScheduleDaysMasterLine(
      int p1) async {
    final url = Uri.parse('$baseUrl/?act=getScheduleDaysMasterline&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        ScheduleDaysMasterLine scheduleDaysMasterLine =
            ScheduleDaysMasterLine.fromMap(data);
        return scheduleDaysMasterLine;
      } else {
        throw Exception('Failed to get Schedule Days MasterLine');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<SchedLines> getSchedLines(int p1, int p2, int p3) async {
    final url = Uri.parse('$baseUrl/?act=getSchedLines&p1=$p1&p2=$p2&p3=$p3');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        SchedLines schedLines = SchedLines.fromMap(data);
        return schedLines;
      } else {
        throw Exception('Failed to get Sched Lines');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<BusLocation> getBusLocations(String p1) async {
    final url = Uri.parse('$baseUrl/?act=getBusLocation&p1=$p1');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        BusLocation busLocation = BusLocation.fromMap(data);
        return busLocation;
      } else {
        throw Exception('Failed to get Bus Location');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<LinesWithMasterLineInfo> webGetLinesWithMLInfo() async {
    final url = Uri.parse('$baseUrl/?act=webGetLinesWithMLInfo');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        LinesWithMasterLineInfo linesWithMasterLineInfo =
            LinesWithMasterLineInfo.fromMap(data);
        return linesWithMasterLineInfo;
      } else {
        throw Exception('Failed to get Lines With ML Info');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<StopBySip> getStopBySIP(String sip) async {
    final url = Uri.parse('$baseUrl/?act=getStopBySIP&sip=$sip');

    try {
      final response = await http.get(url, headers: header);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        StopBySip stopBySip = StopBySip.fromMap(data);
        return stopBySip;
      } else {
        throw Exception('Failed to get Stop By SIP');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
