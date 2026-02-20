import 'dart:async';

import 'package:oasth/api/api/api.dart';
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
import 'package:oasth/data/favorites_service.dart';

/// Single source of truth for all data in the app.
/// Wraps [Api] calls with clean return types and provides
/// access to [FavoritesService] for favorite line persistence.
class OasthRepository {
  static final OasthRepository _instance = OasthRepository._();
  factory OasthRepository() => _instance;
  OasthRepository._();

  final FavoritesService favorites = FavoritesService();

  Future<void> init() async {
    await favorites.init();
  }

  // --- Lines ---

  Future<List<LineData>> getLines() async {
    final result = await Api.webGetLines();
    return result.lines;
  }

  Future<List<LineWithMasterLineInfo>> getLinesWithMLInfo() async {
    final result = await Api.webGetLinesWithMLInfo();
    return result.linesWithMasterLineInfo;
  }

  Future<LineName> getLineName(String lineCode) {
    return Api.getLineName(lineCode);
  }

  Future<LinesAndRoutesForMLandLCode> getLinesAndRoutesForMLandLCode(
    String masterLineCode,
    String lineId,
  ) {
    return Api.getLinesAndRoutesForMasterLineAndLineCode(masterLineCode, lineId);
  }

  // --- Routes ---

  Future<List<LineRoute>> getRoutesForLine(String lineCode) async {
    final result = await Api.getRoutesForLine(lineCode);
    return result.routesForLine;
  }

  Future<RouteDetailAndStops> getRouteDetailsAndStops(String routeCode) {
    return Api.webGetRoutesDetailsAndStops(routeCode);
  }

  Future<List<RouteData>> getRoutes(String p1) async {
    final result = await Api.webGetRoutes(p1);
    return result.routes;
  }

  Future<List<RouteForStop>> getRoutesForStop(String stopCode) async {
    final result = await Api.getRoutesForStop(stopCode);
    return result.routesForStop;
  }

  // --- Stops ---

  Future<List<Stop>> getStopsForRoute(String routeCode) async {
    final result = await Api.webGetStops(routeCode);
    return result.stops;
  }

  Future<List<Stop>> getAllStops() {
    return Api.getAllStops2();
  }

  Future<StopBySip> getStopBySIP(String sip) {
    return Api.getStopBySIP(sip);
  }

  Future<List<StopNameXy>> getStopNameAndXY(String stopId) async {
    final result = await Api.getStopNameAndXY(stopId);
    return result.stopsNameXy;
  }

  Future<List<StopDetails>> getStopArrivals(String stopCode) async {
    final result = await Api.getStopArrivals(stopCode);
    return result.stopDetails;
  }

  // --- Bus Tracking ---

  Future<List<BusLocationData>> getBusLocations(String routeCode) async {
    final result = await Api.getBusLocations(routeCode);
    return result.busLocation;
  }

  // --- News ---

  Future<List<NewsData>> getNews(String lang) async {
    final result = await Api.getNews(lang);
    return result.news;
  }

  // --- Schedule ---

  Future<ScheduleDaysMasterLine> getScheduleDays(int masterLineId) {
    return Api.getScheduleDaysMasterLine(masterLineId);
  }

  Future<SchedLines> getScheduleLines(int p1, int p2, int p3) {
    return Api.getSchedLines(p1, p2, p3);
  }

  // --- Cache Management ---

  void clearCache() => Api.clearCache();

  void dispose() => Api.dispose();
}
