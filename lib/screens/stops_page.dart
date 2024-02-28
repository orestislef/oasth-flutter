import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes_for_line.dart' as rfl;
import 'package:oasth/api/responses/routes_for_stop.dart';
import 'package:oasth/api/responses/stop_by_sip.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/api/responses/stop_name_xy.dart';
import 'package:oasth/helpers/color_generator_helper.dart';
import 'package:oasth/helpers/input_formatters_helper.dart';
import 'package:oasth/screens/stop_page.dart';

class StopsPage extends StatefulWidget {
  const StopsPage({super.key});

  @override
  State<StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<StopsPage> {
  final TextEditingController _textFieldController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _textFieldController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _textFieldController.text.length >= 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Center(
              child: Text(
                  'Επιλέξτε την στάση για την οποία ενδιαφέρεστε να λάβετε πληροφορίες. Συμπεριλαμβάνονται αφίξεις λεωφορείων και πληροφορίες γραμμής.'),
            ),
            const SizedBox(
              height: 16.0,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: InputFormattersHelper.getPhoneInputFormatter(),
              textInputAction: TextInputAction.done,
              maxLength: 5,
              maxLines: 1,
              controller: _textFieldController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Κωδικός στάσης',
              ),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                      String stopCode = _textFieldController.text;
                      await _onPressedOnGetStopDetailsWithCode(
                        context: context,
                        stopCode: stopCode,
                      );
                    }
                  : null,
              child: const Text('Λάβετε πληροφορίες γραμμής'),
            ),
            const SizedBox(height: 20.0),
            const Text('ή Επιλέξτε γραμμή'),
            const SizedBox(height: 10.0),
            Expanded(
                child: FutureBuilder(
                    future: Api.webGetLines(), builder: _buildLines)),
          ],
        ),
      ),
    );
  }

  Future<void> _onPressedOnGetStopDetailsWithCode({
    required BuildContext context,
    required String stopCode,
  }) async {
    StopBySip stopBySip = await Api.getStopBySIP(stopCode);
    RouteForStop? routeForStop = await showModalBottomSheet(
        context: context,
        builder: (context) {
          return FutureBuilder(
              future: Api.getRoutesForStop(stopBySip.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                } else if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                RoutesForStop routesForStop = snapshot.data!;
                if (routesForStop.routesForStop!.isEmpty) {
                  return const Center(
                      child: Text('Δεν υπάρχουν πληροφορίες γραμμής'));
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 16),
                    const Text(
                      'Choose route',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: routesForStop.routesForStop!.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.circle,
                                  color: ColorGenerator(index).generateColor(),
                                ),
                                title: Text(
                                    '${routesForStop.routesForStop![index].lineDescription}'),
                                subtitle: Text(
                                    '${routesForStop.routesForStop![index].lineDescriptionEng}'),
                                trailing: Text(routesForStop
                                    .routesForStop![index].lineID!),
                                onTap: () {
                                  Navigator.pop(context,
                                      routesForStop.routesForStop![index]);
                                },
                              ),
                            );
                          }),
                    ),
                  ],
                );
              });
        });

    if (routeForStop != null) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                FutureBuilder(
                    future: Api.getStopNameAndXY(stopBySip.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('${snapshot.error}'));
                      }
                      StopsNameXy stopsNameXy = snapshot.data!;
                      return Text(
                        '${stopsNameXy.stopsNameXy.first.stopDescr!} - ($stopCode)',
                        style: const TextStyle(fontSize: 20.0),
                      );
                    }),
                const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.all(
                      Radius.circular(15.0),
                    ),
                  ),
                  height: MediaQuery.of(context).size.height * 0.20,
                  width: double.infinity,
                  child: FutureBuilder(
                      future: Api.getStopArrivals(stopBySip.id!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          StopArrivals stopArrivals = snapshot.data!;
                          if (stopArrivals.stopDetails.isEmpty) {
                            return const Center(
                              child: Text(
                                'No stop details found',
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                ),
                              ),
                            );
                          } else {
                            return Scrollbar(
                              child: ListView.builder(
                                itemCount: stopArrivals.stopDetails.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    leading: Text(
                                      '| Bus: ${stopArrivals.stopDetails[index].routeCode!} |',
                                      style: const TextStyle(
                                          color: Colors.amberAccent),
                                    ),
                                    title: Text(
                                      'in ${stopArrivals.stopDetails[index].btime2!} minutes',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    trailing: Text(
                                      'veh code: ${stopArrivals.stopDetails[index].vehCode!}',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          return const Center(
                              child: Text('Loading...',
                                  style: TextStyle(color: Colors.amberAccent)));
                        }
                      }),
                ),
              ],
            );
          });
    }
  }

  Widget _buildLines(BuildContext context, AsyncSnapshot<Line> snapshot) {
    if (snapshot.hasData) {
      Line line = snapshot.data!;
      List<LineData> lines = line.lines;

      return Expanded(
        child: Scrollbar(
          child: ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) {
              LineData line = lines[index];
              return Card(
                child: ListTile(
                  leading: Text(line.lineID),
                  title: Text(line.lineDescription),
                  subtitle: Text(line.lineDescriptionEng),
                  onTap: () => _onPressedOnStop(context, line),
                ),
              );
            },
          ),
        ),
      );
    } else if (snapshot.hasError) {
      return Center(child: Text('${snapshot.error}'));
    } else {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
  }

  void _onPressedOnStop(BuildContext context, LineData line) async {
    debugPrint('line: ${line.lineID}');
    rfl.RoutesForLine routesForLine = await Api.getRoutesForLine(line.lineCode);

    rfl.Route? route = await showModalBottomSheet(
        context: context,
        builder: (context) {
          return FutureBuilder(
              future: Api.getRoutesForLine(line.lineCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 16),
                    const Text(
                      'Επιλέξτε την γραμμή',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: routesForLine.routesForLine.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.circle,
                                  color: ColorGenerator(index).generateColor()),
                              title: Text(routesForLine
                                  .routesForLine[index].routeDescription!),
                              subtitle: Text(routesForLine
                                  .routesForLine[index].routeDescriptionEng!),
                              onTap: () => Navigator.pop(
                                  context, routesForLine.routesForLine[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              });
        });
    if (route != null) {
      Stop? stop = await showModalBottomSheet(
          context: context,
          builder: (context) {
            return FutureBuilder(
                future: Api.webGetStops(route.routeCode!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  return Column(
                    children: <Widget>[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Επιλέξτε την στάση',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.stops.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(snapshot
                                      .data!.stops[index].routeStopOrder),
                                ),
                                title: Text(snapshot
                                    .data!.stops[index].stopDescription),
                                subtitle: Text(snapshot
                                    .data!.stops[index].stopDescriptionEng),
                                onTap: () => Navigator.pop(
                                    context, snapshot.data!.stops[index]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                });
          });
      if (stop != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StopPage(
              stop: stop,
            ),
          ),
        );
      }
    }
  }
}
