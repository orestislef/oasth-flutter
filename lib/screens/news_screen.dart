import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/responses/news.dart';

class NewsScreen extends StatelessWidget {
  final News news;

  const NewsScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('latest_news'.tr()),
      ),
      body: Scrollbar(
        child: ListView.builder(
          itemCount: news.news.length,
          itemBuilder: (context, index) {
            String formattedDate = DateFormat('dd MMMM, yyyy').format(
                DateTime.fromMillisecondsSinceEpoch(
                    int.parse(news.news[index].createdAt) * 1000));
            return Card(
              elevation: 10.0,
              margin: const EdgeInsets.all(10.0),
              color: Colors.blue.shade900,
              shadowColor: Colors.blue.shade900,
              child: ListTile(
                title: Expanded(
                  child: Text(news.news[index].title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                subtitle: Expanded(
                  child: Column(
                    children: [
                      Text(news.news[index].summary,
                          style: const TextStyle(color: Colors.white)),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
