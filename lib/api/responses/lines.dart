class Line {
  late List<LineData> lines;

  static Line fromMap(List<dynamic> map) {
    Line line = Line();
    line.lines = [];
    for (int i = 0; i < map.length; i++) {
      line.lines.add(LineData.fromMap(map[i]));
    }
    return line;
  }

  Map toJson() => {
        "lines": lines,
      };
}

class LineData {
  late String lineCode;
  late String lineID;
  late String lineIDGR;
  late String lineDescription;
  late String lineDescriptionEng;

  static LineData fromMap(Map<String, dynamic> map) {
    LineData objBean = LineData();
    objBean.lineCode = map['LineCode'];
    objBean.lineID = map['LineID'];
    objBean.lineIDGR = map['LineIDGR'];
    objBean.lineDescription = map['LineDescr'];
    objBean.lineDescriptionEng = map['LineDescrEng'];
    return objBean;
  }

  Map toJson() => {
        "LineCode": lineCode,
        "LineID": lineID,
        "LineIDGR": lineIDGR,
        "LineDescr": lineDescription,
        "LineDescrEng": lineDescriptionEng,
      };
}
