class LineName {
  List<LineNameData> lineNames;

  LineName({required this.lineNames});

  factory LineName.fromMap(List<dynamic> data) {
    List<LineNameData> lines = [];
    for (var i = 0; i < data.length; i++) {
      lines.add(LineNameData.fromMap(data[i]));
    }
    return LineName(lineNames: lines);
  }
}

class LineNameData {
  String? lineDescription;
  String? lineDescriptionEng;
  String? lineId;

  LineNameData(
      {required this.lineDescription,
      required this.lineDescriptionEng,
      required this.lineId});

  factory LineNameData.fromMap(Map<String, dynamic> data) {
    return LineNameData(
        lineDescription: data['line_descr'],
        lineDescriptionEng: data['line_descr_eng'],
        lineId: data['line_id']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['line_descr'] = lineDescription;
    data['line_descr_eng'] = lineDescriptionEng;
    data['line_id'] = lineId;
    return data;
  }
}
