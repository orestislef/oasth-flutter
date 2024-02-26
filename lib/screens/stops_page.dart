import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/api/responses/lines.dart';
import 'package:oasth/api/responses/routes_for_stop.dart';
import 'package:oasth/api/responses/stop_by_sip.dart';
import 'package:oasth/helpers/input_formatters_helper.dart';

class StopsPage extends StatefulWidget {
  const StopsPage({super.key});

  @override
  State<StopsPage> createState() => _StopsPageState();
}

class _StopsPageState extends State<StopsPage> {
  final TextEditingController _textFieldController = TextEditingController();
  bool _isButtonEnabled = false;

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Center(
              child: Text(
                  'Επιλέξτε την στάση για την οποία ενδιαφέρεστε να λάβετε πληροφορίες. Συμπεριλαμβάνονται αφίξεις λεωφορείων και πληροφορίες γραμμής.'),
            ),
            const SizedBox(
              height: 16.0,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: InputFormattersHelper.getPhoneInputFormatter(),
              textInputAction: TextInputAction.done,
              maxLength: 5,
              maxLines: 1,
              controller: _textFieldController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Κωδικός στάσης',
              ),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                      String stopCode = _textFieldController.text;
                      await _onPressedOnGetStopDetailsWithCode(
                        context: context,
                        stopCode: stopCode,
                      );
                    }
                  : null,
              child: const Text('Λάβετε πληροφορίες γραμμής'),
            ),
            const SizedBox(height: 20.0),
            const Text('ή Επιλέξτε γραμμή'),
            const SizedBox(height: 10.0),
            Expanded(
                child: FutureBuilder(
                    future: Api.webGetLines(), builder: _buildLines)),
          ],
        ),
      ),
    );
  }

  Future<void> _onPressedOnGetStopDetailsWithCode({
    required BuildContext context,
    required String stopCode,
  }) async {
    StopBySip stopBySip = await Api.getStopBySIP(stopCode);
    RoutesForStop routesForStop = await Api.getRoutesForStop(stopBySip.id!);

    //todo show dromologio
  }

  Widget _buildLines(BuildContext context, AsyncSnapshot<Line> snapshot) {
    if (snapshot.hasData) {
      Line line = snapshot.data!;
      List<LineData> lines = line.lines;

      return Expanded(
        child: Scrollbar(
          child: ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) {
              LineData line = lines[index];
              return ListTile(
                leading: Text(line.lineID),
                title: Text(line.lineDescription),
                subtitle: Text(line.lineDescriptionEng),
                onTap: () => _onPressedOnStop(context, line),
              );
            },
          ),
        ),
      );
    } else if (snapshot.hasError) {
      return Center(child: Text('${snapshot.error}'));
    } else {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
  }

  void _onPressedOnStop(BuildContext context, LineData line) {
    debugPrint('line: ${line.lineID}');
    //TODO:
  }
}
