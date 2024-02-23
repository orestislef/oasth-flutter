class LinesAndRoutesForMLandLCodes {
  late List<LinesAndRoutesForMLandLCode> linesAndRoutesForMlandLcodes;

  static LinesAndRoutesForMLandLCodes fromMap(List<dynamic> map) {
    LinesAndRoutesForMLandLCodes obj = LinesAndRoutesForMLandLCodes();
    obj.linesAndRoutesForMlandLcodes = [];
    for (int i = 0; i < map.length; i++) {
      obj.linesAndRoutesForMlandLcodes
          .add(LinesAndRoutesForMLandLCode.fromMap(map[i]));
    }
    return obj;
  }

  Map toJson() => {
        "lines_and_routes_for_mland_lcodes": linesAndRoutesForMlandLcodes,
      };
}

class LinesAndRoutesForMLandLCode {
  String? lineCode;
  String? lineId;
  String? lineIdGr;
  String? lineDescr;
  String? lineDescrEng;

  static LinesAndRoutesForMLandLCode fromMap(Map<String, dynamic> map) {
    LinesAndRoutesForMLandLCode linesAndRoutesForMLandLCodeBean =
        LinesAndRoutesForMLandLCode();
    linesAndRoutesForMLandLCodeBean.lineCode = map['line_code'];
    linesAndRoutesForMLandLCodeBean.lineId = map['line_id'];
    linesAndRoutesForMLandLCodeBean.lineIdGr = map['line_id_gr'];
    linesAndRoutesForMLandLCodeBean.lineDescr = map['line_descr'];
    linesAndRoutesForMLandLCodeBean.lineDescrEng = map['line_descr_eng'];
    return linesAndRoutesForMLandLCodeBean;
  }

  Map toJson() => {
        "line_code": lineCode,
        "line_id": lineId,
        "line_id_gr": lineIdGr,
        "line_descr": lineDescr,
        "line_descr_eng": lineDescrEng,
      };
}
