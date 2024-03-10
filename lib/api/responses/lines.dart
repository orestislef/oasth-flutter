class Lines {
  late List<LineData> lines;

  static Lines fromMap(List<dynamic> map) {
    Lines line = Lines();
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
    LineData lineData = LineData();
    lineData.lineCode = map['LineCode'];
    lineData.lineID = map['LineID'];
    lineData.lineIDGR = map['LineIDGR'];
    lineData.lineDescription = map['LineDescr'];
    lineData.lineDescriptionEng = map['LineDescrEng'];
    return lineData;
  }

  Map toJson() => {
        "LineCode": lineCode,
        "LineID": lineID,
        "LineIDGR": lineIDGR,
        "LineDescr": lineDescription,
        "LineDescrEng": lineDescriptionEng,
      };
}
