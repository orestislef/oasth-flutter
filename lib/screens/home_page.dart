import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/route_detail_and_stops.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/data/route_planner.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/helpers/app_routes.dart';
import 'package:oasth/screens/best_route_page.dart';
import 'package:oasth/screens/lines_page.dart';
import 'package:oasth/screens/more_screen.dart';
import 'package:oasth/screens/stops_page.dart';
import 'package:oasth/widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.currentIndex = 0});

  final int currentIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_NavigationItem> _navigationItems = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeNavigationItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeNavigationItems() {
    _navigationItems.clear();
    _navigationItems.addAll([
      _NavigationItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        label: 'stations'.tr(),
        page: const StopsPage(),
        color: Theme.of(context).colorScheme.primary,
      ),
      _NavigationItem(
        icon: Icons.route_outlined,
        activeIcon: Icons.route,
        label: 'lines'.tr(),
        page: const LinesPage(),
        color: Theme.of(context).primaryColor,
      ),
      _NavigationItem(
        icon: Icons.directions_outlined,
        activeIcon: Icons.directions,
        label: 'best_route'.tr(),
        page: const BestRoutePage(),
        color: Theme.of(context).colorScheme.tertiary,
      ),
      _NavigationItem(
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz,
        label: 'more'.tr(),
        page: const MorePage(),
        color: Theme.of(context).colorScheme.secondary,
      ),
    ]);
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _navigationItems.map((item) => item.page).toList(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final currentItem = _navigationItems[_currentIndex];

    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Row(
          key: ValueKey(_currentIndex),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentItem.color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentItem.activeIcon,
                size: 20,
                color: currentItem.color,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentItem.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showGlobalSearch,
          tooltip: 'search_across_app'.tr(),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: _navigationItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _currentIndex == index;

          return BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? item.color.withAlpha(25) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey('${index}_$isSelected'),
                  color: isSelected
                      ? item.color
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(153),
                  size: 24,
                ),
              ),
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  void _showGlobalSearch() {
    showSearch(
      context: context,
      delegate: _GlobalSearchDelegate(),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  final Color color;

  _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    required this.color,
  });
}

class _GlobalSearchDelegate extends SearchDelegate<String> {
  final _repo = OasthRepository();
  final _planner = RoutePlanner();

  @override
  String get searchFieldLabel => 'search_lines_stops_routes'.tr();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchTips(context);
    }
    return _buildSearchContent(context);
  }

  Widget _buildSearchTips(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'search_tips'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSearchTip(
                  context,
                  Icons.route,
                  'search_lines'.tr(),
                  'search_lines_example'.tr(),
                ),
                _buildSearchTip(
                  context,
                  Icons.location_on,
                  'search_stops'.tr(),
                  'search_stops_example'.tr(),
                ),
                _buildSearchTip(
                  context,
                  Icons.qr_code,
                  'search_stop_codes'.tr(),
                  'search_stop_codes_example'.tr(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTip(
      BuildContext context, IconData icon, String title, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  example,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withAlpha(153),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    if (query.length < 2) {
      return Center(
        child: Text(
          'type_to_search'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return FutureBuilder<_SearchResults>(
      future: _performSearch(query, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerContainer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...List.generate(4, (_) => const ShimmerLineCard()),
                const SizedBox(height: 16),
                ...List.generate(4, (_) => const ShimmerListTile()),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('error'.tr(),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        final results = snapshot.data!;
        if (results.lines.isEmpty && results.stops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text('no_results_found'.tr(),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (results.lines.isNotEmpty) ...[
              _buildResultSectionHeader(context, 'lines'.tr(), Icons.route),
              ...results.lines.map((line) => _buildLineResult(context, line)),
              const SizedBox(height: 16),
            ],
            if (results.stops.isNotEmpty) ...[
              _buildResultSectionHeader(
                  context, 'stations'.tr(), Icons.location_on),
              ...results.stops.map((stop) => _buildStopResult(context, stop)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildResultSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineResult(BuildContext context, LineWithMasterLineInfo line) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? line.lineDescriptionEng.isNotEmpty
            ? line.lineDescriptionEng
            : line.lineDescription
        : line.lineDescription.isNotEmpty
            ? line.lineDescription
            : line.lineDescriptionEng;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          close(context, '');
          context.push(AppRoutes.lineInfo, extra: LineInfoArgs(line));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'line_badge_${line.lineId}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        line.lineId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildStopResult(BuildContext context, Stop stop) {
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? stop.stopDescriptionEng.isNotEmpty
            ? stop.stopDescriptionEng
            : stop.stopDescription
        : stop.stopDescription.isNotEmpty
            ? stop.stopDescription
            : stop.stopDescriptionEng;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          close(context, '');
          context.push(AppRoutes.stop, extra: StopArgs(stop));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'stop_icon_${stop.stopCode}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(76),
                      ),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'stop_name_${stop.stopCode}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          description,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.stopCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withAlpha(153),
                          ),
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

  Future<_SearchResults> _performSearch(
      String query, BuildContext context) async {
    final q = query.toLowerCase();
    final lines = <LineWithMasterLineInfo>[];
    final stops = <Stop>[];

    // Search lines
    try {
      final allLines = await _repo.getLinesWithMLInfo();
      lines.addAll(allLines.where((line) {
        return line.lineId.toLowerCase().contains(q) ||
            line.lineDescription.toLowerCase().contains(q) ||
            line.lineDescriptionEng.toLowerCase().contains(q);
      }).take(10));
    } catch (_) {}

    // Search stops using route planner (if graph is ready)
    if (_planner.isReady) {
      stops.addAll(_planner.searchStopsByName(query, limit: 10));
    }

    return _SearchResults(lines: lines, stops: stops);
  }
}

class _SearchResults {
  final List<LineWithMasterLineInfo> lines;
  final List<Stop> stops;

  _SearchResults({required this.lines, required this.stops});
}
