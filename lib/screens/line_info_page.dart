import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/line_name.dart';
import 'package:oasth/api/responses/lines_and_routes_for_m_land_l_code.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/api/responses/routes_for_line.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/screens/stop_page.dart';

import 'line_route_page.dart';

class LineInfoPage extends StatefulWidget {
  const LineInfoPage({super.key, required this.linesWithMasterLineInfo});

  final LineWithMasterLineInfo linesWithMasterLineInfo;

  @override
  State<LineInfoPage> createState() => _LineInfoPageState();
}

class _LineInfoPageState extends State<LineInfoPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  
  int _selectedDirectionIndex = 0;
  LineWithMasterLineInfo? _currentLineInfo;
  bool _isFavorite = false;
  String _searchQuery = '';
  List<Stop> _filteredStops = [];
  RouteDetailAndStops? _currentRouteData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentLineInfo = widget.linesWithMasterLineInfo;
    _selectedDirectionIndex = 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _filterStops(String query) {
    if (_currentRouteData == null) return;
    
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStops = _currentRouteData!.stops;
      } else {
        _filteredStops = _currentRouteData!.stops.where((stop) {
          final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
              ? stop.stopDescriptionEng ?? stop.stopDescription ?? ''
              : stop.stopDescription ?? stop.stopDescriptionEng ?? '';
          
          return description.toLowerCase().contains(query.toLowerCase()) ||
                 stop.stopCode?.toLowerCase().contains(query.toLowerCase()) == true ||
                 stop.routeStopOrder?.contains(query) == true;
        }).toList();
      }
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'added_to_favorites'.tr() : 'removed_from_favorites'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToMap() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(context),
            _buildTabBar(context),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStopsTab(context),
            _buildMapTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Theme.of(context).colorScheme.error : null,
          ),
          onPressed: _toggleFavorite,
          tooltip: _isFavorite ? 'remove_from_favorites'.tr() : 'add_to_favorites'.tr(),
        ),
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: _scrollToMap,
          tooltip: 'view_map'.tr(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
        title: FutureBuilder<LineName>(
          future: Api.getLineName(_currentLineInfo!.lineCode!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('loading'.tr());
            }
            
            if (snapshot.hasError) {
              return Text('line_info'.tr());
            }
            
            final lineName = snapshot.data!;
            return Text(
              '${lineName.lineNames.first.lineId} ${lineName.lineNames.first.lineDescription!}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withAlpha(51),
                Theme.of(context).primaryColor.withAlpha(25),
              ],
            ),
          ),
          child: _buildHeaderInfo(context),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentLineInfo!.lineId!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'line_information'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'explore_routes_stops'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return SliverPersistentHeader(
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: 'stops'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.map),
              text: 'map'.tr(),
            ),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildStopsTab(BuildContext context) {
    return Column(
      children: [
        _buildLineVariantsSection(context),
        _buildDirectionSection(context),
        _buildSearchBar(context),
        Expanded(
          child: _buildStopsList(context),
        ),
      ],
    );
  }

  Widget _buildLineVariantsSection(BuildContext context) {
    return FutureBuilder<LinesAndRoutesForMLandLCode>(
      future: Api.getLinesAndRoutesForMasterLineAndLineCode(
        _currentLineInfo!.masterLineCode!,
        _currentLineInfo!.lineId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(context, 'failed_to_load_variants'.tr());
        }
        
        final variants = snapshot.data!;
        if (variants.linesAndRoutesForMlandLcodes.length <= 1) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'line_variants'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...variants.linesAndRoutesForMlandLcodes.map((variant) {
                  final isSelected = variant.lineCode == _currentLineInfo!.lineCode;
                  final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
                      ? variant.lineDescrEng ?? variant.lineDescr ?? ''
                      : variant.lineDescr ?? variant.lineDescrEng ?? '';

                  return InkWell(
                    onTap: isSelected ? null : () {
                      setState(() {
                        _currentLineInfo!.lineCode = variant.lineCode!;
                        _selectedDirectionIndex = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withAlpha(25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                variant.lineIdGr!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : null,
                                color: isSelected ? Theme.of(context).primaryColor : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectionSection(BuildContext context) {
    return FutureBuilder<RoutesForLine>(
      future: Api.getRoutesForLine(_currentLineInfo!.lineCode!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(context, 'failed_to_load_directions'.tr());
        }
        
        final routes = snapshot.data!;
        if (routes.routesForLine.isEmpty) {
          return _buildErrorCard(context, 'no_routes_available'.tr());
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'direction'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...routes.routesForLine.asMap().entries.map((entry) {
                  final index = entry.key;
                  final route = entry.value;
                  final isSelected = _selectedDirectionIndex == index;
                  final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
                      ? route.routeDescriptionEng ?? route.routeDescription ?? ''
                      : route.routeDescription ?? route.routeDescriptionEng ?? '';

                  return InkWell(
                    onTap: routes.routesForLine.length > 1 ? () {
                      setState(() {
                        _selectedDirectionIndex = index;
                        _searchQuery = '';
                      });
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withAlpha(25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.route,
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : null,
                                color: isSelected ? Theme.of(context).primaryColor : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: _filterStops,
        decoration: InputDecoration(
          hintText: 'search_stops_on_route'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _filterStops(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  Widget _buildStopsList(BuildContext context) {
    return FutureBuilder<RoutesForLine>(
      future: Api.getRoutesForLine(_currentLineInfo!.lineCode!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        
        if (snapshot.hasError || snapshot.data!.routesForLine.isEmpty) {
          return _buildErrorCard(context, 'failed_to_load_route_data'.tr());
        }

        return FutureBuilder<RouteDetailAndStops>(
          future: Api.webGetRoutesDetailsAndStops(
            snapshot.data!.routesForLine[_selectedDirectionIndex].routeCode!,
          ),
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            
            if (routeSnapshot.hasError) {
              return _buildErrorCard(context, 'failed_to_load_stops'.tr());
            }

            _currentRouteData = routeSnapshot.data!;
            final stops = _searchQuery.isEmpty 
                ? _currentRouteData!.stops 
                : _filteredStops;

            if (stops.isEmpty && _searchQuery.isNotEmpty) {
              return _buildEmptySearchState(context);
            }

            return Column(
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'showing_stops_results'.tr(namedArgs: {
                            'count': stops.length.toString(),
                            'total': _currentRouteData!.stops.length.toString(),
                          }),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      return _buildStopCard(context, stop);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStopCard(BuildContext context, Stop stop) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? stop.stopDescriptionEng ?? stop.stopDescription ?? 'unknown_stop'.tr()
        : stop.stopDescription ?? stop.stopDescriptionEng ?? 'unknown_stop'.tr();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToStop(stop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    stop.routeStopOrder ?? '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stop.stopStreet != null && stop.stopStreet!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.stopStreet!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(178),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stop.stopAmea == '1')
                    Icon(
                      Icons.accessible,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTab(BuildContext context) {
    return FutureBuilder<RoutesForLine>(
      future: Api.getRoutesForLine(_currentLineInfo!.lineCode!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        
        if (snapshot.hasError || snapshot.data!.routesForLine.isEmpty) {
          return _buildErrorCard(context, 'failed_to_load_route_data'.tr());
        }

        return FutureBuilder<RouteDetailAndStops>(
          future: Api.webGetRoutesDetailsAndStops(
            snapshot.data!.routesForLine[_selectedDirectionIndex].routeCode!,
          ),
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            
            if (routeSnapshot.hasError) {
              return _buildErrorCard(context, 'failed_to_load_map_data'.tr());
            }

            final routeData = routeSnapshot.data!;
            return RoutePage(
              details: routeData.details,
              stops: routeData.stops,
              hasAppBar: false,
              routeCode: snapshot.data!.routesForLine[_selectedDirectionIndex].routeCode!,
              routeName: LanguageHelper.getLanguageUsedInApp(context) == 'en'
                  ? snapshot.data!.routesForLine[_selectedDirectionIndex].routeDescriptionEng
                  : snapshot.data!.routesForLine[_selectedDirectionIndex].routeDescription,
              lineId: _currentLineInfo!.lineId,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'no_stops_match_search'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _filterStops(''),
              icon: const Icon(Icons.clear),
              label: Text('clear_search'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStop(Stop stop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopPage(stop: stop),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}