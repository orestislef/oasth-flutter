import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/stop_details.dart';

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
  static Future<List<Line>> wegGetLines() async {
    final url = Uri.parse('$baseUrl/?act=webGetLines');

    try {
      final response = await http.post(url, headers: header);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Line> lines = [];
        for (int i = 0; i < data.length; i++) {
          Line line = Line.fromMap(data[i]);
          lines.add(line);
        }
        return lines;
      } else {
        throw Exception('Failed to web Get Lines');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<StopArrivals> getStopArrivals(String stopCode) async {
    final url = Uri.parse('$baseUrl/?act=getStopArrivals&p1=$stopCode');

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

  static Future<RouteDetailAndStops> webGetRoutesDetailsAndStops(int p1) async {
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
}
