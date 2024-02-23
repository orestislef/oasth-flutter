import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/screens/line_route_page.dart';
import 'package:oasth/screens/stop_page.dart';

class LinePage extends StatelessWidget {
  final LineData line;

  const LinePage({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(line.lineDescr),
        actions: [
          FutureBuilder<RouteDetailAndStops>(
            future: Api.webGetRoutesDetailsAndStops(line.lineCode),
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
          future: Api.webGetRoutesDetailsAndStops(line.lineCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else if (snapshot.data == null || snapshot.data!.stops.isEmpty) {
              return const Text('No stops found');
            } else {
              return Scrollbar(
                child: ListView.builder(
                  itemCount: snapshot.data!.stops.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data!.stops[index].stopDescription),
                      subtitle: Text(snapshot.data!.stops[index].stopDescriptionEng),
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
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
