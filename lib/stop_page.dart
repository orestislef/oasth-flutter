import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:oasth/route_detail_and_stops.dart';
import 'package:oasth/stop_details.dart';

class StopPage extends StatelessWidget {
  const StopPage({super.key, required this.stop});

  final Stops stop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stop.stopDescr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show all information
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${stop.stopDescr}'),
                Text('English Description: ${stop.stopDescrEng}'),
                Text('Street: ${stop.stopStreet ?? "N/A"}'),
                Text('English Street: ${stop.stopStreetEng ?? "N/A"}'),
                Text('Heading: ${stop.stopHeading}'),
                Text('Latitude: ${stop.stopLat}'),
                Text('Longitude: ${stop.stopLng}'),
                Text('Route Stop Order: ${stop.routeStopOrder}'),
                Text('Stop Type: ${stop.stopType}'),
                Text('Stop Amea: ${stop.stopAmea}'),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.rectangle,
                    border: Border(
                      top: BorderSide(width: 2.0, color: Colors.grey),
                      left: BorderSide(width: 2.0, color: Colors.grey),
                      right: BorderSide(width: 2.0, color: Colors.grey),
                      bottom: BorderSide(width: 2.0, color: Colors.grey),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  height: MediaQuery.of(context).size.height * 0.20,
                  width: double.infinity,
                  child: FutureBuilder(
                      future: getStopArrivals(stop.stopCode),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          StopArrivals stopArrivals = snapshot.data!;
                          if (stopArrivals.stopDetails.isEmpty) {
                            return const Text('No stop details found');
                          } else {
                            return Scrollbar(
                              child: ListView.builder(
                                itemCount: stopArrivals.stopDetails.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    title: Text(
                                      'in: ${stopArrivals.stopDetails[index].btime2!}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    leading: Text(
                                      'Bus: ${stopArrivals.stopDetails[index].routeCode!}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          return const Text('Loading...');
                        }
                      }),
                ),
              ],
            ),
          ),
          // Map with a marker
          Expanded(
            child: FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                initialCenter: LatLng(
                    double.parse(stop.stopLat), double.parse(stop.stopLng)),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(double.parse(stop.stopLat),
                          double.parse(stop.stopLng)),
                      child: const Icon(Icons.location_on),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<StopArrivals> getStopArrivals(String stopCode) async {
  final url = Uri.parse(
      'https://telematics.oasth.gr/api/?act=getStopArrivals&p1=$stopCode');
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
      final List<dynamic> data = json.decode(response.body);
      StopArrivals stopArrivals = StopArrivals.fromMap(data);
      return stopArrivals;
    } else {
      throw Exception('Failed to get data');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}
