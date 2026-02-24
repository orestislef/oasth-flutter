import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
import 'package:oasth/api/responses/routes_for_stop.dart';
import 'package:oasth/api/responses/stop_details.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/helpers/input_formatters_helper.dart';
import 'package:oasth/helpers/language_helper.dart';
import 'package:oasth/screens/line_info_page.dart';

class StopsPage extends StatefulWidget {
  const StopsPage({super.key});

  @override
  State<StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<StopsPage> {
  final _repo = OasthRepository();
  final TextEditingController _textFieldController = TextEditingController();
  bool _isButtonEnabled = false;
  String _lineSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _textFieldController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _textFieldController.text.length >= 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStopCodeSection(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or_choose_line'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ),
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildLineSearchBar(context),
        Expanded(child: _buildLinesList(context)),
      ],
    );
  }

  Widget _buildStopCodeSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'station_code'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'choose_station_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withAlpha(153),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters:
                        InputFormattersHelper.getPhoneInputFormatter(),
                    textInputAction: TextInputAction.done,
                    maxLength: 5,
                    maxLines: 1,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    controller: _textFieldController,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '12345',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showStopCodeInfoDialog,
                  icon: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  tooltip: 'stop_code_info'.tr(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isButtonEnabled
                    ? () => _lookupStopByCode(context)
                    : null,
                icon: const Icon(Icons.search),
                label: Text('take_station_info'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => setState(() => _lineSearchQuery = value),
        decoration: InputDecoration(
          hintText: 'search_hint_for_lines'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _lineSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () =>
                      setState(() => _lineSearchQuery = ''),
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

  Widget _buildLinesList(BuildContext context) {
    return FutureBuilder<List<LineWithMasterLineInfo>>(
      future: _repo.getLinesWithMLInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
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

        final lines = snapshot.data!;
        final filtered = _lineSearchQuery.isEmpty
            ? lines
            : lines.where((line) {
                final q = _lineSearchQuery.toLowerCase();
                return line.lineId.toLowerCase().contains(q) ||
                    line.lineDescription.toLowerCase().contains(q) ||
                    line.lineDescriptionEng.toLowerCase().contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text('no_lines_found'.tr(),
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final line = filtered[index];
            return _buildLineCard(context, line);
          },
        );
      },
    );
  }

  Widget _buildLineCard(BuildContext context, LineWithMasterLineInfo line) {
    final description =
        LanguageHelper.getLanguageUsedInApp(context) == 'en'
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LineInfoPage(linesWithMasterLineInfo: line),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
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

  Future<void> _lookupStopByCode(BuildContext context) async {
    final stopCode = _textFieldController.text;
    try {
      final stopBySip = await _repo.getStopBySIP(stopCode);
      if (!context.mounted) return;

      // Show routes for this stop in a bottom sheet
      final RouteForStop? selected = await showModalBottomSheet<RouteForStop>(
        context: context,
        builder: (context) {
          return FutureBuilder<List<RouteForStop>>(
            future: _repo.getRoutesForStop(stopBySip.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(child: Text('error'.tr())),
                );
              }
              final routes = snapshot.data!;
              if (routes.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(child: Text('no_line_info'.tr())),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'choose_route'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final desc =
                            LanguageHelper.getLanguageUsedInApp(context) == 'en'
                                ? route.lineDescriptionEng
                                : route.lineDescription;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, route),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        route.lineID,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(desc)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      );

      if (selected != null && context.mounted) {
        // Get stop arrivals and show
        _showStopArrivals(context, stopBySip.id, stopCode, selected);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showStopArrivals(BuildContext context, String stopId, String stopCode,
      RouteForStop route) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${route.lineID} - ${LanguageHelper.getLanguageUsedInApp(context) == 'en' ? route.lineDescriptionEng : route.lineDescription}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'station_code'.tr()}: $stopCode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<StopDetails>>(
                  future: _repo.getStopArrivals(stopId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                            child: CircularProgressIndicator.adaptive()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('error'.tr()));
                    }
                    final arrivals = snapshot.data!;
                    if (arrivals.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'no_stop_details'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: arrivals.length,
                      itemBuilder: (context, index) {
                        final arrival = arrivals[index];
                        final minutes =
                            int.tryParse(arrival.btime2) ?? 999;
                        final color = minutes <= 2
                            ? Theme.of(context).colorScheme.error
                            : minutes <= 5
                                ? Theme.of(context).primaryColor
                                : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.directions_bus,
                                    color: color, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    arrival.routeCode,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${arrival.btime2} ${minutes == 1 ? 'min' : 'mins'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showStopCodeInfoDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'stop_code_info'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      Image.asset('assets/icons/stop_code_info1.png', width: 200),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      Image.asset('assets/icons/stop_code_info2.png', width: 200),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      isScrollControlled: true,
      useSafeArea: true,
    );
  }
}
