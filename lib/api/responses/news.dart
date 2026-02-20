class News {
  final List<NewsData> news;

  const News({required this.news});

  factory News.fromMap(List<dynamic> data) {
    return News(
      news: data.map((e) => NewsData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'news': news.map((e) => e.toMap()).toList(),
      };
}

class NewsData {
  final String id;
  final String title;
  final String summary;
  final String createdAt;

  const NewsData({
    required this.id,
    required this.title,
    required this.summary,
    required this.createdAt,
  });

  factory NewsData.fromMap(Map<String, dynamic> map) {
    return NewsData(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'summary': summary,
        'createdAt': createdAt,
      };
}
