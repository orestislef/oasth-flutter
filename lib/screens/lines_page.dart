import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
  late List<LineWithMasterLineInfo> allLines = [];
  late List<LineWithMasterLineInfo> displayedLines = [];

  @override
  void initState() {
    super.initState();
    _fetchLines();
  }

  Future<void> _fetchLines() async {
    try {
      final lines = await Api.webGetLinesWithMLInfo();
      setState(() {
        allLines = lines.linesWithMasterLineInfo;
        displayedLines = allLines;
      });
    } catch (error) {
      debugPrint('Error fetching lines: $error');
    }
  }

  void _filterLines(String query) {
    setState(() {
      displayedLines = allLines
          .where((line) =>
              line.lineDescription!
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              line.lineId!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: 'search_hint_for_lines'.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _filterLines,
            ),
          ),
          Expanded(
            child: displayedLines.isEmpty
                ? Center(
                    child: Text('no_lines_found'.tr()),
                  )
                : ListView.builder(
                    itemCount: displayedLines.length,
                    itemBuilder: (context, index) {
                      final line = displayedLines[index];
                      bool isOdd = index % 2 == 0;
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: () => _onTapOnLine(context, line),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOdd
                                ? Colors.blue.shade800
                                : Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            elevation: 10.0,
                            shadowColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(child: Text(line.lineId!)),
                              ),
                              Expanded(
                                child: Text(
                                  LanguageHelper.getLanguageUsedInApp(
                                              context) ==
                                          'en'
                                      ? line.lineDescriptionEng!
                                      : line.lineDescription!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onTapOnLine(
    BuildContext context,
    LineWithMasterLineInfo line,
  ) {
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
