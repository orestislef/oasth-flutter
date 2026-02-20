class Lines {
  final List<LineData> lines;

  const Lines({required this.lines});

  factory Lines.fromMap(List<dynamic> map) {
    return Lines(
      lines: map.map((e) => LineData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lines': lines.map((e) => e.toMap()).toList(),
      };
}

class LineData {
  final String lineCode;
  final String lineID;
  final String lineIDGR;
  final String lineDescription;
  final String lineDescriptionEng;

  const LineData({
    required this.lineCode,
    required this.lineID,
    required this.lineIDGR,
    required this.lineDescription,
    required this.lineDescriptionEng,
  });

  factory LineData.fromMap(Map<String, dynamic> map) {
    return LineData(
      lineCode: map['LineCode']?.toString() ?? '',
      lineID: map['LineID']?.toString() ?? '',
      lineIDGR: map['LineIDGR']?.toString() ?? '',
      lineDescription: map['LineDescr']?.toString() ?? '',
      lineDescriptionEng: map['LineDescrEng']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'LineCode': lineCode,
        'LineID': lineID,
        'LineIDGR': lineIDGR,
        'LineDescr': lineDescription,
        'LineDescrEng': lineDescriptionEng,
      };
}
