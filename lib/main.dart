import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oasth/line_page.dart';
import 'package:oasth/line_route_page.dart';
import 'package:oasth/lines.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ΟΑΣΘ γραμμές'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Line>>(
        future: getLines(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Text('No lines found');
            }
            return Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    enableFeedback: true,
                    leading: Text(snapshot.data![index].lineIDGR),
                    title: Text(snapshot.data![index].lineDescr),
                    subtitle: Text(snapshot.data![index].lineDescrEng),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LinePage(line: snapshot.data![index]),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

Future<List<Line>> getLines() async {
  final url = Uri.parse('https://telematics.oasth.gr/api/?act=webGetLines');
  final headers = {
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
    'Connection': 'keep-alive',
    'Content-Length': '0',
    'Cookie':
        'PHPSESSID=oj56ov5krms4v3e9ab8k6fn0b6; _ga=GA1.1.1207430914.1706778348; lineDetails=cl_61_73_12||01X; stops=c2_1649||%20%CE%9C%CE%97%CE%A7%CE%91%CE%9D%CE%9F%CE%A5%CE%A1%CE%93%CE%95%CE%99%CE%9F%20%CE%9F.%CE%A3.%CE%95.||40.652490100000001,22.9115067||13006; _ga_L492Z0RV7F=GS1.1.1706778348.1.1.1706778633.0.0.0',
    'Host': 'telematics.oasth.gr',
    'Origin': 'https://telematics.oasth.gr',
    'Referer': 'https://telematics.oasth.gr/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'sec-ch-ua':
        '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
    'sec-ch-ua-mobile': '?1',
    'sec-ch-ua-platform': '"Android"',
  };

  try {
    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Line> lines = [];
      for (int i = 0; i < data.length; i++) {
        Line line = Line.fromMap(data[i]);
        lines.add(line);
      }
      return lines;
    } else {
      throw Exception('Failed to get data');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}
