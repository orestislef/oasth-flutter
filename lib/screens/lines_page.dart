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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
                'Επιλέξτε τη γραμμή που σας ενδιαφέρει, για να δείτε: το ωράριο λειτουργίας και τις στάσεις της.'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<LinesWithMasterLineInfo>(
              future: Api.webGetLinesWithMLInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                } else {
                  LinesWithMasterLineInfo linesWithMasterLineInfo =
                      snapshot.data!;
                  return Scrollbar(
                    child: ListView.builder(
                      itemCount: linesWithMasterLineInfo
                          .linesWithMasterLineInfo.length,
                      itemBuilder: (context, index) {
                        bool isOdd = index % 2 == 0;
                        return ListTile(
                          tileColor: isOdd ? Colors.grey[200] : null,
                          enableFeedback: true,
                          leading: Text(linesWithMasterLineInfo
                              .linesWithMasterLineInfo[index].lineId!),
                          title: Text(linesWithMasterLineInfo
                              .linesWithMasterLineInfo[index].lineDescription!),
                          subtitle: Text(linesWithMasterLineInfo
                              .linesWithMasterLineInfo[index]
                              .lineDescriptionEng!),
                          onTap: () {
                            _onTapOnLine(
                                context,
                                linesWithMasterLineInfo
                                    .linesWithMasterLineInfo[index]);
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTapOnLine(
    BuildContext context,
    LineWithMasterLineInfo linesWithMasterLineInfo,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LineInfoPage(
          linesWithMasterLineInfo: linesWithMasterLineInfo,
        ),
      ),
    );
  }
}
