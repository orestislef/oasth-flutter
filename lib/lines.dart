class Line {
  late String lineCode;
  late String lineID;
  late String lineIDGR;
  late String lineDescr;
  late String lineDescrEng;

  static Line fromMap(Map<String, dynamic> map) {
    Line obj = Line();
    obj.lineCode = map['LineCode'];
    obj.lineID = map['LineID'];
    obj.lineIDGR = map['LineIDGR'];
    obj.lineDescr = map['LineDescr'];
    obj.lineDescrEng = map['LineDescrEng'];
    return obj;
  }

  Map toJson() => {
    "LineCode": lineCode,
    "LineID": lineID,
    "LineIDGR": lineIDGR,
    "LineDescr": lineDescr,
    "LineDescrEng": lineDescrEng,
  };
}