import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines_with_ml_info.dart';
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
      displayedLines = allLines.where((line) =>
      line.lineDescription!.toLowerCase().contains(query.toLowerCase()) ||
          line.lineId!.toLowerCase().contains(query.toLowerCase())).toList();
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
              decoration: const InputDecoration(
                labelText: 'Search by Line Description or Line ID',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterLines,
            ),
          ),
          Expanded(
            child: displayedLines.isEmpty
                ? const Center(
              child: Text('No lines found.'),
            )
                : ListView.builder(
              itemCount: displayedLines.length,
              itemBuilder: (context, index) {
                final line = displayedLines[index];
                bool isOdd = index % 2 == 0;
                return Card(
                  color: isOdd ? null : Colors.grey.shade300,
                  child: ListTile(
                    leading: Text(line.lineId!),
                    title: Text(line.lineDescription!),
                    subtitle: Text(line.lineDescriptionEng!),
                    onTap: () {
                      _onTapOnLine(context, line);
                    },
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
