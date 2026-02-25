import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/screens/home_page.dart';
import 'package:oasth/screens/line_info_page.dart';
import 'package:oasth/screens/line_route_page.dart';
import 'package:oasth/screens/lines_page.dart';
import 'package:oasth/screens/map_with_nearby_stations_widget.dart';
import 'package:oasth/screens/more_screen.dart';
import 'package:oasth/screens/news_screen.dart';
import 'package:oasth/screens/stop_page.dart';
import 'package:oasth/screens/nearby_departures_page.dart';
import 'package:oasth/screens/favorites_live_map_page.dart';
import 'package:oasth/screens/best_route/route_map.dart';
import 'package:oasth/screens/location_picker_page.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'helpers/app_routes.dart';
import 'helpers/language_helper.dart';
import 'helpers/notification_helper.dart';
import 'helpers/package_info_plus_helper.dart';
import 'helpers/shared_preferences_helper.dart';
import 'helpers/theme_mode_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SharedPreferencesHelper.init();
  await OasthRepository().init();
  await ThemeModeController.init();
  await PackageInfoPlusHelper.ensureInitialized();
  await NotificationHelper().init();

  // Start background data download (non-blocking)
  Api.downloadAllData().then((_) {
    debugPrint('[App] Background data download complete');
  }).catchError((e) {
    debugPrint('[App] Background data download failed: $e');
  });

  runApp(
    EasyLocalization(
      supportedLocales: LanguageHelper.getAvailableLocales(),
      path: LanguageHelper.getAssetsPath(),
      fallbackLocale: LanguageHelper.getAvailableLocales().first,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.mode,
      builder: (context, themeMode, _) {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: AppRoutes.homeTab,
              builder: (context, state) {
                final args = state.extra as HomeArgs?;
                return HomePage(currentIndex: args?.currentIndex ?? 0);
              },
            ),
            GoRoute(
              path: AppRoutes.lines,
              builder: (context, state) => const LinesPage(),
            ),
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => const MorePage(),
            ),
            GoRoute(
              path: AppRoutes.mapFull,
              builder: (context, state) => const MapWithNearbyStations(
                hasBackButton: true,
              ),
            ),
            GoRoute(
              path: AppRoutes.lineInfo,
              builder: (context, state) {
                final args = state.extra as LineInfoArgs?;
                if (args == null) return const HomePage();
                return LineInfoPage(linesWithMasterLineInfo: args.line);
              },
            ),
            GoRoute(
              path: AppRoutes.stop,
              builder: (context, state) {
                final args = state.extra as StopArgs?;
                if (args == null) return const HomePage();
                return StopPage(stop: args.stop);
              },
            ),
            GoRoute(
              path: AppRoutes.routeMap,
              builder: (context, state) {
                final args = state.extra as RoutePageArgs?;
                if (args == null) return const HomePage();
                return RoutePage(
                  details: args.details,
                  stops: args.stops,
                  routeCode: args.routeCode,
                  routeName: args.routeName,
                  lineId: args.lineId,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.routeMapFull,
              builder: (context, state) {
                final args = state.extra as RouteMapFullArgs?;
                if (args == null) return const HomePage();
                return FullScreenRouteMap(
                    route: args.route, result: args.result);
              },
            ),
            GoRoute(
              path: AppRoutes.news,
              builder: (context, state) {
                final args = state.extra as NewsArgs?;
                if (args == null) return const HomePage();
                return NewsScreen(news: args.news);
              },
            ),
            GoRoute(
              path: AppRoutes.newsDetail,
              builder: (context, state) {
                final args = state.extra as NewsDetailArgs?;
                if (args == null) return const HomePage();
                return NewsDetailPage(newsItem: args.newsItem);
              },
            ),
            GoRoute(
              path: AppRoutes.nearbyDepartures,
              builder: (context, state) => const NearbyDeparturesPage(),
            ),
            GoRoute(
              path: AppRoutes.favoritesLiveMap,
              builder: (context, state) => const FavoritesLiveMapPage(),
            ),
            GoRoute(
              path: AppRoutes.locationPicker,
              builder: (context, state) {
                final initialLocation = state.extra as LatLng?;
                return LocationPickerPage(initialLocation: initialLocation);
              },
            ),
          ],
        );

        return MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
            useMaterial3: true,
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: ColorScheme.fromSeed(seedColor: Colors.lightBlue).primary,
              unselectedItemColor: ColorScheme.fromSeed(seedColor: Colors.lightBlue).onSurfaceVariant,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlue,
              brightness: Brightness.dark,
            ).copyWith(
              primary: Colors.lightBlueAccent,
              onPrimary: Colors.white,
            ),
            tabBarTheme: const TabBarThemeData(
              labelColor: Colors.lightBlueAccent,
              unselectedLabelColor: Colors.white70,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: Colors.lightBlueAccent,
              unselectedItemColor: Colors.white70,
            ),
            iconTheme: const IconThemeData(
              color: Colors.white70,
            ),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          title: 'OASTH',
        );
      },
    );
  }
}
