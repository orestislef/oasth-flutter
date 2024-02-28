import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/line_name.dart';
import 'package:oasth/api/responses/lines_and_routes_for_m_land_l_code.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes_for_line.dart';
import 'package:oasth/screens/stop_page.dart';

import 'line_route_page.dart';

class LineInfoPage extends StatefulWidget {
  LineInfoPage({super.key, required this.linesWithMasterLineInfo});

  final LineWithMasterLineInfo linesWithMasterLineInfo;
  int selectedDirectionIndex = 0;

  @override
  State<LineInfoPage> createState() => _LineInfoPageState();
}

class _LineInfoPageState extends State<LineInfoPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            surfaceTintColor: Colors.white,
            shadowColor: Colors.blue,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.map,
                  color: Colors.blueAccent,
                ),
                onPressed: () => _scrollToBottom(),
              ),
            ],
            collapsedHeight: 64.0,
            expandedHeight: 224.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(48.0, 0.0, 48.0, 0.0),
              title: FutureBuilder<LineName>(
                future:
                    Api.getLineName(widget.linesWithMasterLineInfo.lineCode!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else {
                    LineName lineName = snapshot.data!;
                    return Text(
                      '${lineName.lineNames.first.lineId} ${lineName.lineNames.first.lineDescription!}',
                      style: const TextStyle(color: Colors.black),
                    );
                  }
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        FutureBuilder(
            future: Api.getLinesAndRoutesForMasterLineAndLineCode(
                widget.linesWithMasterLineInfo.masterLineCode!,
                widget.linesWithMasterLineInfo.lineId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 10),
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 10),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              } else {
                LinesAndRoutesForMLandLCode linesAndRoutesForMLandLCode =
                    snapshot.data!;
                return Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Εναλλακτική Διαδρομή',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListView.builder(
                        itemCount: linesAndRoutesForMLandLCode
                            .linesAndRoutesForMlandLcodes.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          bool isTheSelected = linesAndRoutesForMLandLCode
                                  .linesAndRoutesForMlandLcodes[index]
                                  .lineCode ==
                              widget.linesWithMasterLineInfo.lineCode;
                          return Card(
                            child: ListTile(
                              selected: isTheSelected,
                              trailing: isTheSelected
                                  ? const Icon(Icons.check)
                                  : null,
                              leading: Text(
                                  '${linesAndRoutesForMLandLCode.linesAndRoutesForMlandLcodes[index].lineIdGr}'),
                              title: Text(
                                  '${linesAndRoutesForMLandLCode.linesAndRoutesForMlandLcodes[index].lineDescr}'),
                              subtitle: Text(
                                  '${linesAndRoutesForMLandLCode.linesAndRoutesForMlandLcodes[index].lineDescrEng}'),
                              enableFeedback: true,
                              onTap: linesAndRoutesForMLandLCode
                                          .linesAndRoutesForMlandLcodes.length >
                                      1
                                  ? () {
                                      setState(() {
                                        widget.linesWithMasterLineInfo
                                                .lineCode =
                                            linesAndRoutesForMLandLCode
                                                .linesAndRoutesForMlandLcodes[
                                                    index]
                                                .lineCode!;
                                      });
                                    }
                                  : null,
                            ),
                          );
                        }),
                  ],
                );
              }
            }),
        FutureBuilder<RoutesForLine>(
          future:
              Api.getRoutesForLine(widget.linesWithMasterLineInfo.lineCode!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    CircularProgressIndicator.adaptive(),
                    SizedBox(height: 10),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else {
              RoutesForLine routesForLine = snapshot.data!;
              return Column(
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Κατεύθυνση',
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ListView.builder(
                      itemCount: routesForLine.routesForLine.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        bool isTheSelected =
                            widget.selectedDirectionIndex == index;
                        return Column(
                          children: <Widget>[
                            Card(
                              child: ListTile(
                                selected: isTheSelected,
                                trailing: isTheSelected
                                    ? const Icon(Icons.check)
                                    : null,
                                title: Text(
                                    '${routesForLine.routesForLine[index].routeDescription}'),
                                subtitle: Text(
                                    '${routesForLine.routesForLine[index].routeDescriptionEng}'),
                                enableFeedback: true,
                                onTap: routesForLine.routesForLine.length > 1
                                    ? () {
                                        setState(() {
                                          widget.selectedDirectionIndex = index;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }),
                  Column(
                    children: <Widget>[
                      const SizedBox(height: 10.0),
                      FutureBuilder(
                          future: Api.webGetRoutesDetailsAndStops(routesForLine
                              .routesForLine[widget.selectedDirectionIndex]
                              .routeCode!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator.adaptive());
                            } else if (snapshot.hasError) {
                              return Text('${snapshot.error}');
                            } else {
                              RouteDetailAndStops routeDetailAndStops =
                                  snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  const Text('Πίνακας Στασεων',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(height: 10.0),
                                  ListView.builder(
                                      itemCount:
                                          routeDetailAndStops.stops.length,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        bool hasStopStreet = routeDetailAndStops
                                                    .stops[index].stopStreet !=
                                                null &&
                                            routeDetailAndStops.stops[index]
                                                .stopStreet!.isNotEmpty;
                                        return Card(
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              child: Text(routeDetailAndStops
                                                  .stops[index].routeStopOrder),
                                            ),
                                            title: Text(routeDetailAndStops
                                                .stops[index].stopDescription),
                                            subtitle: hasStopStreet
                                                ? Text(routeDetailAndStops
                                                    .stops[index].stopStreet!)
                                                : null,
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                routeDetailAndStops.stops[index]
                                                            .stopAmea ==
                                                        '1'
                                                    ? const Icon(
                                                        Icons.accessible)
                                                    : const SizedBox(),
                                                const Icon(Icons.arrow_right,
                                                    size: 20),
                                              ],
                                            ),
                                            enableFeedback: true,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => StopPage(
                                                      stop: routeDetailAndStops
                                                          .stops[index]),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                  const SizedBox(height: 10.0),
                                  const Text('Map',
                                      style: TextStyle(fontSize: 20)),
                                  SizedBox(
                                    height: 500.0,
                                    width: double.infinity,
                                    child: RoutePage(
                                      details: routeDetailAndStops.details,
                                      stops: routeDetailAndStops.stops,
                                      hasAppBar: false,
                                      routeCode: routesForLine
                                          .routesForLine[
                                              widget.selectedDirectionIndex]
                                          .routeCode!,
                                    ),
                                  )
                                ],
                              );
                            }
                          }),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}
