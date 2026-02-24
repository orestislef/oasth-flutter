import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/news.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/data/route_planner_models.dart';

class AppRoutes {
  static const String home = '/';
  static const String homeTab = '/home';
  static const String more = '/more';
  static const String mapFull = '/map-full';
  static const String lines = '/lines';
  static const String lineInfo = '/line-info';
  static const String stop = '/stop';
  static const String routeMap = '/route-map';
  static const String routeMapFull = '/route-map-full';
  static const String news = '/news';
  static const String newsDetail = '/news-detail';
}

class HomeArgs {
  final int currentIndex;

  const HomeArgs({required this.currentIndex});
}

class LineInfoArgs {
  final LineWithMasterLineInfo line;

  const LineInfoArgs(this.line);
}

class StopArgs {
  final Stop stop;

  const StopArgs(this.stop);
}

class RoutePageArgs {
  final List<Details> details;
  final List<Stop> stops;
  final String routeCode;
  final String? routeName;
  final String? lineId;

  const RoutePageArgs({
    required this.details,
    required this.stops,
    required this.routeCode,
    this.routeName,
    this.lineId,
  });
}

class NewsArgs {
  final List<NewsData> news;

  const NewsArgs(this.news);
}

class NewsDetailArgs {
  final NewsData newsItem;

  const NewsDetailArgs(this.newsItem);
}

class RouteMapFullArgs {
  final OfflineRouteResult route;
  final RouteResult result;

  const RouteMapFullArgs({
    required this.route,
    required this.result,
  });
}
