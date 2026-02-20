import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/screens/line_route_page.dart';
import 'package:oasth/screens/stop_page.dart';

import '../helpers/language_helper.dart';

class LinePage extends StatefulWidget {
  final LineData line;

  const LinePage({super.key, required this.line});

  @override
  State<LinePage> createState() => _LinePageState();
}

class _LinePageState extends State<LinePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  RouteDetailAndStops? _routeData;
  List<Stop> _filteredStops = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFavorite = false; // You can persist this

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final data = await Api.webGetRoutesDetailsAndStops(widget.line.lineCode!);
      
      if (mounted) {
        setState(() {
          _routeData = data;
          _filteredStops = data.stops;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _filterStops(String query) {
    if (_routeData == null) return;
    
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStops = _routeData!.stops;
      } else {
        _filteredStops = _routeData!.stops.where((stop) {
          final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
              ? stop.stopDescriptionEng ?? stop.stopDescription ?? ''
              : stop.stopDescription ?? stop.stopDescriptionEng ?? '';
          
          return description.toLowerCase().contains(query.toLowerCase()) ||
                 stop.stopCode?.toLowerCase().contains(query.toLowerCase()) == true;
        }).toList();
      }
    });
  }

  void _navigateToRoute() {
    if (_routeData == null || _routeData!.details.isEmpty || _routeData!.stops.isEmpty) {
      _showInfoSnackBar('route_data_not_available'.tr());
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutePage(
          details: _routeData!.details,
          stops: _routeData!.stops,
          routeCode: widget.line.lineCode!,
          routeName: widget.line.lineDescription,
          lineId: widget.line.lineID,
        ),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // Here you would typically save to persistent storage
    _showInfoSnackBar(_isFavorite ? 'added_to_favorites'.tr() : 'removed_from_favorites'.tr());
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          _buildResultsInfo(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? widget.line.lineDescriptionEng ?? widget.line.lineDescription ?? 'line_details'.tr()
        : widget.line.lineDescription ?? widget.line.lineDescriptionEng ?? 'line_details'.tr();

    return AppBar(
      title: Text(
        description,
        overflow: TextOverflow.ellipsis,
      ),
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
          icon: const Icon(Icons.map_rounded),
          onPressed: _isLoading ? null : _navigateToRoute,
          tooltip: 'view_route_map'.tr(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withAlpha(76),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.line.lineID!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                  'line_number'.tr(namedArgs: {'number': widget.line.lineID!}),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_routeData != null)
                  Text(
                    'total_stops_count'.tr(namedArgs: {
                      'count': _routeData!.stops.length.toString(),
                    }),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'search_stops_on_line'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStops('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onChanged: _filterStops,
      ),
    );
  }

  Widget _buildResultsInfo(BuildContext context) {
    if (_searchQuery.isEmpty || _routeData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              'count': _filteredStops.length.toString(),
              'total': _routeData!.stops.length.toString(),
            }),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_hasError) {
      return _buildErrorState(context);
    }

    if (_routeData == null || _routeData!.stops.isEmpty) {
      return _buildEmptyState(context);
    }

    if (_filteredStops.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState(context);
    }

    return _buildStopsList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 16),
          Text(
            'loading_line_stops'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'please_wait_loading_stops'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(178),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'failed_to_load_stops'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(178),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRouteData,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'no_stops_found'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'line_has_no_stops'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(178),
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
            const SizedBox(height: 24),
            Text(
              'no_stops_match_search'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'try_different_search_terms'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterStops('');
              },
              icon: const Icon(Icons.clear),
              label: Text('clear_search'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStops.length,
      itemBuilder: (context, index) {
        final stop = _filteredStops[index];
        return _buildStopCard(context, stop, index);
      },
    );
  }

  Widget _buildStopCard(BuildContext context, Stop stop, int index) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? stop.stopDescriptionEng ?? stop.stopDescription ?? 'unknown_stop'.tr()
        : stop.stopDescription ?? stop.stopDescriptionEng ?? 'unknown_stop'.tr();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToStop(stop),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    stop.routeStopOrder ?? '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (stop.stopCode != null) ...[
                          Icon(
                            Icons.qr_code,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(178),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stop.stopCode!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(178),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.accessible,
                          size: 14,
                          color: stop.stopAmea == '0' 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stop.stopAmea == '0' ? 'not_accessible'.tr() : 'accessible'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: stop.stopAmea == '0' 
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.small(
      onPressed: _scrollToTop,
      tooltip: 'scroll_to_top'.tr(),
      child: const Icon(Icons.keyboard_arrow_up),
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

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}