class News {
  late final List<NewsData> news;

  News({
    required this.news,
  });

  News.fromJson(List<dynamic> json) {
    news = json.map((e) => NewsData.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['news'] = news.map((e) => e.toJson()).toList();
    return data;
  }
}

class NewsData {
  NewsData({
    required this.title,
    required this.id,
    required this.summary,
    required this.createdAt,
  });

  late final String id;
  late final String title;
  late final String summary;
  late final String createdAt;

  NewsData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    summary = json['summary'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['summary'] = summary;
    data['created_at'] = createdAt;
    return data;
  }
}
