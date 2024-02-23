import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/screens/line_page.dart';

class LinesPage extends StatefulWidget {
  const LinesPage({super.key});

  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ΟΑΣΘ γραμμές'),
      ),
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
                'Επιλέξτε τη γραμμή που σας ενδιαφέρει, για να δείτε: το ωράριο λειτουργίας και τις στάσεις της.'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<Lines>(
              future: Api.wegGetLines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                } else {
                  final lines = snapshot.data!;
                  return Scrollbar(
                    child: ListView.builder(
                      itemCount: lines.lines.length,
                      itemBuilder: (context, index) {
                        bool isOdd = index % 2 == 0;
                        return ListTile(

                          tileColor: isOdd ? Colors.grey[200] : null,
                          enableFeedback: true,
                          leading: Text(lines.lines[index].lineID),
                          title: Text(lines.lines[index].lineDescr),
                          subtitle: Text(lines.lines[index].lineDescrEng),
                          onTap: () {
                            _onTapOnLine(context, lines.lines[index]);
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

  void _onTapOnLine(BuildContext context, Line line) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinePage(line: line),
      ),
    );
  }
}
