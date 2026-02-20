class LineName {
  final List<LineNameData> lineNames;

  const LineName({required this.lineNames});

  factory LineName.fromMap(List<dynamic> data) {
    return LineName(
      lineNames: data.map((e) => LineNameData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lineNames': lineNames.map((e) => e.toMap()).toList(),
      };
}

class LineNameData {
  final String lineDescription;
  final String lineDescriptionEng;
  final String lineId;

  const LineNameData({
    required this.lineDescription,
    required this.lineDescriptionEng,
    required this.lineId,
  });

  factory LineNameData.fromMap(Map<String, dynamic> data) {
    return LineNameData(
      lineDescription: data['line_descr']?.toString() ?? '',
      lineDescriptionEng: data['line_descr_eng']?.toString() ?? '',
      lineId: data['line_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'line_descr': lineDescription,
        'line_descr_eng': lineDescriptionEng,
        'line_id': lineId,
      };
}
