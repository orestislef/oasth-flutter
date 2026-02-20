class LinesAndRoutesForMLandLCode {
  final List<LinesAndRoutesForMLandLCodeData> linesAndRoutesForMlandLcodes;

  const LinesAndRoutesForMLandLCode(
      {required this.linesAndRoutesForMlandLcodes});

  factory LinesAndRoutesForMLandLCode.fromMap(List<dynamic> map) {
    return LinesAndRoutesForMLandLCode(
      linesAndRoutesForMlandLcodes:
          map.map((e) => LinesAndRoutesForMLandLCodeData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lines_and_routes_for_mland_lcodes':
            linesAndRoutesForMlandLcodes.map((e) => e.toMap()).toList(),
      };
}

class LinesAndRoutesForMLandLCodeData {
  final String lineCode;
  final String lineId;
  final String lineIdGr;
  final String lineDescr;
  final String lineDescrEng;

  const LinesAndRoutesForMLandLCodeData({
    required this.lineCode,
    required this.lineId,
    required this.lineIdGr,
    required this.lineDescr,
    required this.lineDescrEng,
  });

  factory LinesAndRoutesForMLandLCodeData.fromMap(Map<String, dynamic> map) {
    return LinesAndRoutesForMLandLCodeData(
      lineCode: map['line_code']?.toString() ?? '',
      lineId: map['line_id']?.toString() ?? '',
      lineIdGr: map['line_id_gr']?.toString() ?? '',
      lineDescr: map['line_descr']?.toString() ?? '',
      lineDescrEng: map['line_descr_eng']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'line_code': lineCode,
        'line_id': lineId,
        'line_id_gr': lineIdGr,
        'line_descr': lineDescr,
        'line_descr_eng': lineDescrEng,
      };
}
