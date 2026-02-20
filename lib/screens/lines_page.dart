import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/screens/line_info_page.dart';

class LinesPage extends StatefulWidget {
  const LinesPage({super.key});

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<LineWithMasterLineInfo> _allLines = [];
  List<LineWithMasterLineInfo> _displayedLines = [];
  final List<LineWithMasterLineInfo> _favoriteLines = []; // You can persist this
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  LinesSortType _sortType = LinesSortType.lineNumber;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchLines();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLines() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final lines = await Api.webGetLinesWithMLInfo();
      
      if (mounted) {
        setState(() {
          _allLines = lines.linesWithMasterLineInfo;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
      debugPrint('Error fetching lines: $error');
    }
  }

  void _applyFiltersAndSort() {
    List<LineWithMasterLineInfo> filteredLines = _allLines;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredLines = filteredLines.where((line) {
        final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
            ? line.lineDescriptionEng ?? line.lineDescription ?? ''
            : line.lineDescription ?? line.lineDescriptionEng ?? '';
        
        return description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               line.lineId!.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      filteredLines = filteredLines.where((line) => 
          _favoriteLines.any((fav) => fav.lineId == line.lineId)).toList();
    }

    // Apply sorting
    switch (_sortType) {
      case LinesSortType.lineNumber:
        filteredLines.sort((a, b) {
          final aNum = int.tryParse(a.lineId!) ?? 999;
          final bNum = int.tryParse(b.lineId!) ?? 999;
          return aNum.compareTo(bNum);
        });
        break;
      case LinesSortType.alphabetical:
        filteredLines.sort((a, b) {
          final aDesc = LanguageHelper.getLanguageUsedInApp(context) == 'en'
              ? a.lineDescriptionEng ?? a.lineDescription ?? ''
              : a.lineDescription ?? a.lineDescriptionEng ?? '';
          final bDesc = LanguageHelper.getLanguageUsedInApp(context) == 'en'
              ? b.lineDescriptionEng ?? b.lineDescription ?? ''
              : b.lineDescription ?? b.lineDescriptionEng ?? '';
          return aDesc.compareTo(bDesc);
        });
        break;
    }

    setState(() {
      _displayedLines = filteredLines;
    });
  }

  void _filterLines(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _toggleFavorite(LineWithMasterLineInfo line) {
    setState(() {
      final index = _favoriteLines.indexWhere((fav) => fav.lineId == line.lineId);
      if (index >= 0) {
        _favoriteLines.removeAt(index);
      } else {
        _favoriteLines.add(line);
      }
    });
    // Here you would typically save favorites to persistent storage
  }

  bool _isFavorite(LineWithMasterLineInfo line) {
    return _favoriteLines.any((fav) => fav.lineId == line.lineId);
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
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilters(context),
          _buildResultsInfo(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'bus_lines'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'browse_all_routes'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: 'search_hint_for_lines'.tr(),
              hintText: 'search_by_number_or_name'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterLines('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: _filterLines,
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: Text('favorites'.tr()),
            selected: _showFavoritesOnly,
            onSelected: (selected) {
              setState(() {
                _showFavoritesOnly = selected;
              });
              _applyFiltersAndSort();
            },
            avatar: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('by_number'.tr()),
            selected: _sortType == LinesSortType.lineNumber,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _sortType = LinesSortType.lineNumber;
                });
                _applyFiltersAndSort();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('alphabetical'.tr()),
            selected: _sortType == LinesSortType.alphabetical,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _sortType = LinesSortType.alphabetical;
                });
                _applyFiltersAndSort();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsInfo(BuildContext context) {
    if (_searchQuery.isEmpty && !_showFavoritesOnly) return const SizedBox.shrink();
    
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
            _showFavoritesOnly
                ? 'showing_favorites'.tr(namedArgs: {'count': _displayedLines.length.toString()})
                : 'showing_search_results'.tr(namedArgs: {
                    'count': _displayedLines.length.toString(),
                    'total': _allLines.length.toString(),
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

    if (_displayedLines.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildLinesList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 16),
          Text(
            'loading_lines'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'please_wait_loading_routes'.tr(),
           
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
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
              'failed_to_load_lines'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
     
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchLines,
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
              _showFavoritesOnly ? Icons.favorite_border : Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              _showFavoritesOnly 
                  ? 'no_favorite_lines'.tr()
                  : _searchQuery.isNotEmpty
                      ? 'no_lines_found'.tr()
                      : 'no_lines_available'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _showFavoritesOnly
                  ? 'add_favorites_explanation'.tr()
                  : _searchQuery.isNotEmpty
                      ? 'try_different_search_terms'.tr()
                      : 'check_connection_try_again'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _showFavoritesOnly) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_searchQuery.isNotEmpty) {
                    _searchController.clear();
                    _filterLines('');
                  }
                  if (_showFavoritesOnly) {
                    setState(() {
                      _showFavoritesOnly = false;
                    });
                    _applyFiltersAndSort();
                  }
                },
                icon: const Icon(Icons.clear),
                label: Text('clear_filters'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinesList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedLines.length,
      itemBuilder: (context, index) {
        final line = _displayedLines[index];
        return _buildLineCard(context, line, index);
      },
    );
  }

  Widget _buildLineCard(BuildContext context, LineWithMasterLineInfo line, int index) {
    final isFavorite = _isFavorite(line);
    final description = LanguageHelper.getLanguageUsedInApp(context) == 'en'
        ? line.lineDescriptionEng ?? line.lineDescription ?? 'no_description'.tr()
        : line.lineDescription ?? line.lineDescriptionEng ?? 'no_description'.tr();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTapOnLine(context, line),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: .3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    line.lineId!,
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
                    Text(
                      '${'line'.tr()} ${line.lineId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite 
                          ? Theme.of(context).colorScheme.error 
                          : Theme.of(context).disabledColor,
                    ),
                    onPressed: () => _toggleFavorite(line),
                    tooltip: isFavorite ? 'remove_from_favorites'.tr() : 'add_to_favorites'.tr(),
                  ),
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

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.small(
      onPressed: _scrollToTop,
      tooltip: 'scroll_to_top'.tr(),
      child: const Icon(Icons.keyboard_arrow_up),
    );
  }

  void _onTapOnLine(BuildContext context, LineWithMasterLineInfo line) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LineInfoPage(
          linesWithMasterLineInfo: line,
        ),
      ),
    );
  }
}

enum LinesSortType {
  lineNumber,
  alphabetical,
}