import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oasth/line_route_page.dart';
import 'package:oasth/lines.dart';
import 'package:oasth/route_detail_and_stops.dart';
import 'package:oasth/stop_page.dart';

class LinePage extends StatelessWidget {
  final Line line;

  const LinePage({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(line.lineDescr),
        actions: [
          FutureBuilder<RouteDetailAndStops>(
            future: getRouteDetails(int.parse(line.lineCode)),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.map_rounded),
                onPressed: () {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final details = snapshot.data!.details;
                    final stops = snapshot.data!.stops;

                    if (details.isEmpty || stops.isEmpty) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutePage(
                          details: details,
                          stops: stops,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<RouteDetailAndStops>(
          future: getRouteDetails(int.parse(line.lineCode)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else if (snapshot.data == null || snapshot.data!.stops.isEmpty) {
              return const Text('No stops found');
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.stops.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data!.stops[index].stopDescr),
                    subtitle: Text(snapshot.data!.stops[index].stopDescrEng),
                    onTap: () {
                      final stop = snapshot.data!.stops[index];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StopPage(stop: stop),
                        ),
                      );
                    },
                    enableFeedback: true,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

Future<RouteDetailAndStops> getRouteDetails(int p1) async {
  final url = Uri.parse(
      'https://telematics.oasth.gr/api/?act=webGetRoutesDetailsAndStops&p1=$p1');
  final headers = {
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

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      RouteDetailAndStops routeDetailAndStops =
          RouteDetailAndStops.fromMap(data);
      return routeDetailAndStops;
    } else {
      throw Exception('Failed to get data');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}
