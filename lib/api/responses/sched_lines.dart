class SchedLines {
  late List<Come> come;
  late List<Go> go;

  SchedLines({required this.come, required this.go});

  factory SchedLines.fromMap(Map<String, dynamic> map) {
    return SchedLines(
      come: (map['come'] as List? ?? []).map((o) => Come.fromMap(o)).toList(),
      go: (map['go'] as List? ?? []).map((o) => Go.fromMap(o)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "come": come.map((come) => come.toJson()).toList(),
    "go": go.map((go) => go.toJson()).toList(),
  };
}


class Go {
  String? sdeCode;
  String? sdcCode;
  String? sdsCode;
  String? sdeAa;
  String? sdeLine1;
  String? sdeKp1;
  String? sdeStart1;
  String? sdeEnd1;
  String? sdeLine2;
  String? sdeKp2;
  String? sdeStart2;
  String? sdeEnd2;
  String? sdeSort;
  String? lineId;
  String? lineCircle;
  String? lineDescr;
  String? lineDescrEng;

  static Go fromMap(Map<String, dynamic> map) {
    Go go = Go();
    go.sdeCode = map['sde_code'];
    go.sdcCode = map['sdc_code'];
    go.sdsCode = map['sds_code'];
    go.sdeAa = map['sde_aa'];
    go.sdeLine1 = map['sde_line1'];
    go.sdeKp1 = map['sde_kp1'];
    go.sdeStart1 = map['sde_start1'];
    go.sdeEnd1 = map['sde_end1'];
    go.sdeLine2 = map['sde_line2'];
    go.sdeKp2 = map['sde_kp2'];
    go.sdeStart2 = map['sde_start2'];
    go.sdeEnd2 = map['sde_end2'];
    go.sdeSort = map['sde_sort'];
    go.lineId = map['line_id'];
    go.lineCircle = map['line_circle'];
    go.lineDescr = map['line_descr'];
    go.lineDescrEng = map['line_descr_eng'];
    return go;
  }

  Map toJson() => {
        "sde_code": sdeCode,
        "sdc_code": sdcCode,
        "sds_code": sdsCode,
        "sde_aa": sdeAa,
        "sde_line1": sdeLine1,
        "sde_kp1": sdeKp1,
        "sde_start1": sdeStart1,
        "sde_end1": sdeEnd1,
        "sde_line2": sdeLine2,
        "sde_kp2": sdeKp2,
        "sde_start2": sdeStart2,
        "sde_end2": sdeEnd2,
        "sde_sort": sdeSort,
        "line_id": lineId,
        "line_circle": lineCircle,
        "line_descr": lineDescr,
        "line_descr_eng": lineDescrEng,
      };
}

class Come {
  String? sdeCode;
  String? sdcCode;
  String? sdsCode;
  String? sdeAa;
  String? sdeLine1;
  String? sdeKp1;
  dynamic sdeStart1;
  dynamic sdeEnd1;
  String? sdeLine2;
  String? sdeKp2;
  String? sdeStart2;
  String? sdeEnd2;
  String? sdeSort;
  String? lineId;
  String? lineCircle;
  String? lineDescr;
  String? lineDescrEng;

  static Come fromMap(Map<String, dynamic> map) {
    Come come = Come();
    come.sdeCode = map['sde_code'];
    come.sdcCode = map['sdc_code'];
    come.sdsCode = map['sds_code'];
    come.sdeAa = map['sde_aa'];
    come.sdeLine1 = map['sde_line1'];
    come.sdeKp1 = map['sde_kp1'];
    come.sdeStart1 = map['sde_start1'];
    come.sdeEnd1 = map['sde_end1'];
    come.sdeLine2 = map['sde_line2'];
    come.sdeKp2 = map['sde_kp2'];
    come.sdeStart2 = map['sde_start2'];
    come.sdeEnd2 = map['sde_end2'];
    come.sdeSort = map['sde_sort'];
    come.lineId = map['line_id'];
    come.lineCircle = map['line_circle'];
    come.lineDescr = map['line_descr'];
    come.lineDescrEng = map['line_descr_eng'];
    return come;
  }

  Map toJson() => {
        "sde_code": sdeCode,
        "sdc_code": sdcCode,
        "sds_code": sdsCode,
        "sde_aa": sdeAa,
        "sde_line1": sdeLine1,
        "sde_kp1": sdeKp1,
        "sde_start1": sdeStart1,
        "sde_end1": sdeEnd1,
        "sde_line2": sdeLine2,
        "sde_kp2": sdeKp2,
        "sde_start2": sdeStart2,
        "sde_end2": sdeEnd2,
        "sde_sort": sdeSort,
        "line_id": lineId,
        "line_circle": lineCircle,
        "line_descr": lineDescr,
        "line_descr_eng": lineDescrEng,
      };
}
