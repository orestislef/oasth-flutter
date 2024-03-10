import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:oasth/helpers/language_helper.dart';
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
            Center(child: Text('choose_station_hint'.tr())),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters:
                        InputFormattersHelper.getPhoneInputFormatter(),
                    textInputAction: TextInputAction.done,
                    maxLength: 5,
                    maxLines: 1,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    controller: _textFieldController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'station_code'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Center(
                  child: IconButton(
                      onPressed: () {
                        _showStopCodeInfoDialog();
                      },
                      icon: const Icon(Icons.info)),
                )
              ],
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
              child: Text('take_station_info'.tr()),
            ),
            const SizedBox(height: 20.0),
            Text('or_choose_line'.tr()),
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
                  return Center(child: Text('no_line_info'.tr()));
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 16),
                    Text(
                      'choose_route'.tr(),
                      style: const TextStyle(fontSize: 20.0),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: routesForStop.routesForStop!.length,
                          itemBuilder: (context, index) {
                            bool isOdd = index % 2 == 0;
                            return Card(
                              color: isOdd
                                  ? Colors.blue.shade800
                                  : Colors.blue.shade900,
                              child: ListTile(
                                leading: Icon(
                                  Icons.circle,
                                  color: ColorGenerator(index).generateColor(),
                                ),
                                title: Text(
                                    LanguageHelper.getLanguageUsedInApp(
                                                context) ==
                                            'en'
                                        ? '${routesForStop.routesForStop![index].lineDescriptionEng}'
                                        : '${routesForStop.routesForStop![index].lineDescription}',
                                    style:
                                        const TextStyle(color: Colors.white)),
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
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.rectangle,
                    border: Border(
                      top: BorderSide(width: 2.0, color: Colors.blue.shade900),
                      left: BorderSide(width: 2.0, color: Colors.blue.shade900),
                      right:
                          BorderSide(width: 2.0, color: Colors.blue.shade900),
                      bottom:
                          BorderSide(width: 2.0, color: Colors.blue.shade900),
                    ),
                    borderRadius: const BorderRadius.all(
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
                            return Center(
                              child: Text(
                                'no_stop_details'.tr(),
                                style: const TextStyle(
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
                                    title: Text(
                                      '${'bus'.tr()}: ${stopArrivals.stopDetails[index].routeCode!} ${'in'.tr()} ${stopArrivals.stopDetails[index].vehCode!} ${stopArrivals.stopDetails[index].btime2!} minutes',
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
                          return Center(
                              child: Text('loading'.tr(),
                                  style: const TextStyle(
                                      color: Colors.amberAccent)));
                        }
                      }),
                ),
              ],
            );
          });
    }
  }

  Widget _buildLines(BuildContext context, AsyncSnapshot<Lines> snapshot) {
    if (snapshot.hasData) {
      Lines line = snapshot.data!;
      List<LineData> lines = line.lines;

      return Scrollbar(
        child: ListView.builder(
          itemCount: lines.length,
          itemBuilder: (context, index) {
            LineData line = lines[index];
            bool isOdd = index % 2 == 0;
            return Card(
              color: isOdd ? Colors.blue.shade800 : Colors.blue.shade900,
              child: ListTile(
                leading: Text(line.lineID!,
                    style: const TextStyle(color: Colors.white)),
                title: Text(
                  LanguageHelper.getLanguageUsedInApp(context) == 'en'
                      ? line.lineDescriptionEng!
                      : line.lineDescription!,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => _onPressedOnStop(context, line),
              ),
            );
          },
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
    rfl.RoutesForLine routesForLine = await Api.getRoutesForLine(line.lineCode!);

    rfl.Route? route = await showModalBottomSheet(
        context: context,
        builder: (context) {
          return FutureBuilder(
              future: Api.getRoutesForLine(line.lineCode!),
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
                    Text(
                      'choose_line'.tr(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          itemCount: routesForLine.routesForLine.length,
                          itemBuilder: (context, index) {
                            bool isOdd = index % 2 == 0;
                            return Card(
                              color: isOdd
                                  ? Colors.blue.shade800
                                  : Colors.blue.shade900,
                              child: ListTile(
                                leading: Icon(Icons.circle,
                                    color:
                                        ColorGenerator(index).generateColor()),
                                title: Text(
                                    LanguageHelper.getLanguageUsedInApp(
                                                context) ==
                                            'en'
                                        ? routesForLine.routesForLine[index]
                                            .routeDescriptionEng!
                                        : routesForLine.routesForLine[index]
                                            .routeDescription!,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                onTap: () => Navigator.pop(context,
                                    routesForLine.routesForLine[index]),
                              ),
                            );
                          },
                        ),
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
                      Center(
                        child: Text(
                          'choose_station'.tr(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.builder(
                            itemCount: snapshot.data!.stops.length,
                            itemBuilder: (context, index) {
                              bool isOdd = index % 2 == 0;
                              return Card(
                                color: isOdd
                                    ? Colors.blue.shade800
                                    : Colors.blue.shade900,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(snapshot
                                        .data!.stops[index].routeStopOrder!),
                                  ),
                                  title: Text(
                                    LanguageHelper.getLanguageUsedInApp(
                                                context) ==
                                            'en'
                                        ? snapshot.data!.stops[index]
                                            .stopDescriptionEng!
                                        : snapshot.data!.stops[index]
                                            .stopDescriptionEng!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => Navigator.pop(
                                      context, snapshot.data!.stops[index]),
                                ),
                              );
                            },
                          ),
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

  void _showStopCodeInfoDialog() {
    showModalBottomSheet(
      context: context,
      builder: _buildStopCodeInfoDialog,
      isScrollControlled: true,
      useSafeArea: true,
    );
  }

  Widget _buildStopCodeInfoDialog(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(
              'stop_code_info'.tr(),
              style: const TextStyle(fontSize: 20),
            ),
            Image.asset('assets/icons/stop_code_info1.png', width: 200),
            Image.asset('assets/icons/stop_code_info2.png', width: 200),
          ]),
        ),
      ),
    );
  }
}
