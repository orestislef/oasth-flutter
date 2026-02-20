import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oasth/screens/best_route_page.dart';
import 'package:oasth/screens/lines_page.dart';
import 'package:oasth/screens/stops_page.dart';

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
    
    _initializeNavigationItems();
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeNavigationItems() {
    _navigationItems.addAll([
      _NavigationItem(
        icon: Icons.route_outlined,
        activeIcon: Icons.route,
        label: 'lines'.tr(),
        page: const LinesPage(),
        color: Theme.of(context).primaryColor,
      ),
      _NavigationItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        label: 'stations'.tr(),
        page: const StopsPage(),
        color: const Color(0xFF2196F3), // Blue
      ),
      _NavigationItem(
        icon: Icons.directions_outlined,
        activeIcon: Icons.directions,
        label: 'best_route'.tr(),
        page: const BestRoutePage(),
        color: const Color(0xFF4CAF50), // Green
      ),
    ]);
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    
    // Haptic feedback
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
                color: isSelected
                    ? item.color.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey('${index}_$isSelected'),
                  color: isSelected
                      ? item.color
                      : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(153),
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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchTips(context);
    }
    return _buildSearchResults(context);
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

  Widget _buildSearchTip(BuildContext context, IconData icon, String title, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
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
                    color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // This is a placeholder - you would implement actual search functionality
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'search_functionality_placeholder'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'implement_search_logic'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}