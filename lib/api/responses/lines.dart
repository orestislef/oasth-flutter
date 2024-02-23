class Line {
  late String lineCode;
  late String lineID;
  late String lineIDGR;
  late String lineDescr;
  late String lineDescrEng;

  static Line fromMap(Map<String, dynamic> map) {
    Line objBean = Line();
    objBean.lineCode = map['LineCode'];
    objBean.lineID = map['LineID'];
    objBean.lineIDGR = map['LineIDGR'];
    objBean.lineDescr = map['LineDescr'];
    objBean.lineDescrEng = map['LineDescrEng'];
    return objBean;
  }

  Map toJson() => {
    "LineCode": lineCode,
    "LineID": lineID,
    "LineIDGR": lineIDGR,
    "LineDescr": lineDescr,
    "LineDescrEng": lineDescrEng,
  };
}