import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../widgets/language_toggle.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String details;
  final IconData? icon;
  final bool isImportant;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.details,
    this.icon,
    this.isImportant = false,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isImportant
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
                              : Theme.of(context).primaryColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: widget.isImportant
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isImportant
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            axisAlignment: -1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.details,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  if (widget.title.contains('contact') || widget.title.contains('επικοινωνία'))
                    _buildContactActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(context, widget.details),
            icon: const Icon(Icons.copy, size: 16),
            label: Text('copy_info'.tr()),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('copied_to_clipboard'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<_SectionItem> _filteredItems = [];
  final List<_SectionItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
    _filteredItems = _allItems;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeItems() {
    _allItems.addAll([
      // App Info Section
      _SectionItem(
        title: 'about_app'.tr(),
        details: 'about_app_details'.tr(),
        icon: Icons.info_outline,
        category: 'app_info'.tr(),
        isImportant: true,
      ),
      _SectionItem(
        title: 'contact_us'.tr(),
        details: 'contact_us_details'.tr(),
        icon: Icons.contact_support_outlined,
        category: 'app_info'.tr(),
        isImportant: true,
      ),
      _SectionItem(
        title: 'privacy_policy'.tr(),
        details: 'privacy_policy_details'.tr(),
        icon: Icons.privacy_tip_outlined,
        category: 'legal'.tr(),
      ),
      _SectionItem(
        title: 'terms_and_conditions'.tr(),
        details: 'terms_and_conditions_details'.tr(),
        icon: Icons.description_outlined,
        category: 'legal'.tr(),
      ),
      // FAQ Section
      ..._buildFAQItems(),
    ]);
  }

  List<_SectionItem> _buildFAQItems() {
    final faqIcons = [
      Icons.help_outline,
      Icons.schedule,
      Icons.payment,
      Icons.location_on_outlined,
      Icons.directions_bus,
      Icons.accessibility,
      Icons.smartphone,
      Icons.wifi,
      Icons.security,
      Icons.support,
      Icons.update,
      Icons.bug_report,
      Icons.feedback,
      Icons.star_outline,
      Icons.question_mark,
    ];

    return List.generate(15, (index) {
      return _SectionItem(
        title: 'faq${index + 1}'.tr(),
        details: 'faq${index + 1}_details'.tr(),
        icon: faqIcons[index % faqIcons.length],
        category: 'faq'.tr(),
      );
    });
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(query.toLowerCase()) ||
                 item.details.toLowerCase().contains(query.toLowerCase()) ||
                 item.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          if (_searchQuery.isNotEmpty) _buildSearchResults(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      floatingActionButton: _buildScrollToTopButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('more_options'.tr()),
      elevation: 0,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'app_settings_help'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'find_answers_settings'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: _filterItems,
        decoration: InputDecoration(
          hintText: 'search_help_settings'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _filterItems(''),
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

  Widget _buildSearchResults(BuildContext context) {
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
            'showing_results_count'.tr(namedArgs: {
              'count': _filteredItems.length.toString(),
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
    if (_filteredItems.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState(context);
    }

    return ListView(
      controller: _scrollController,
      children: [
        const LanguageToggleWidget(),
        const SizedBox(height: 16),
        if (_searchQuery.isEmpty) ..._buildCategorizedSections(context)
        else ..._buildFilteredResults(context),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  List<Widget> _buildCategorizedSections(BuildContext context) {
    final sections = <String, List<_SectionItem>>{};
    
    for (final item in _allItems) {
      sections.putIfAbsent(item.category, () => []).add(item);
    }

    final widgets = <Widget>[];
    
    sections.forEach((category, items) {
      widgets.add(_buildSectionHeader(context, category));
      widgets.addAll(
        items.map((item) => CustomExpansionTile(
          title: item.title,
          details: item.details,
          icon: item.icon,
          isImportant: item.isImportant,
        )),
      );
      widgets.add(const SizedBox(height: 16));
    });

    return widgets;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildFilteredResults(BuildContext context) {
    return _filteredItems.map((item) => CustomExpansionTile(
      title: item.title,
      details: item.details,
      icon: item.icon,
      isImportant: item.isImportant,
    )).toList();
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
              'no_help_results'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'try_different_search'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _filterItems(''),
              icon: const Icon(Icons.clear),
              label: Text('clear_search'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildScrollToTopButton() {
    return FloatingActionButton.small(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      tooltip: 'scroll_to_top'.tr(),
      child: const Icon(Icons.keyboard_arrow_up),
    );
  }
}

class _SectionItem {
  final String title;
  final String details;
  final IconData icon;
  final String category;
  final bool isImportant;

  _SectionItem({
    required this.title,
    required this.details,
    required this.icon,
    required this.category,
    this.isImportant = false,
  });
}