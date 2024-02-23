class LineNames {
  List<LineName> lines;

  LineNames({required this.lines});

  factory LineNames.fromMap(List<dynamic> data) {
    List<LineName> lines = [];
    for (var i = 0; i < data.length; i++) {
      lines.add(LineName.fromMap(data[i]));
    }
    return LineNames(lines: lines);
  }
}

class LineName {
  String? lineDescription;
  String? lineDescriptionEng;
  String? lineId;

  LineName(
      {required this.lineDescription,
      required this.lineDescriptionEng,
      required this.lineId});

  factory LineName.fromMap(Map<String, dynamic> data) {
    return LineName(
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
