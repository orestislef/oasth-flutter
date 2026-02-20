class SchedLines {
  final List<ScheduleEntry> come;
  final List<ScheduleEntry> go;

  const SchedLines({required this.come, required this.go});

  factory SchedLines.fromMap(Map<String, dynamic> map) {
    return SchedLines(
      come: (map['come'] as List? ?? [])
          .map((o) => ScheduleEntry.fromMap(o))
          .toList(),
      go: (map['go'] as List? ?? [])
          .map((o) => ScheduleEntry.fromMap(o))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'come': come.map((e) => e.toMap()).toList(),
        'go': go.map((e) => e.toMap()).toList(),
      };
}

class ScheduleEntry {
  final String sdeCode;
  final String sdcCode;
  final String sdsCode;
  final String sdeAa;
  final String sdeLine1;
  final String sdeKp1;
  final String sdeStart1;
  final String sdeEnd1;
  final String sdeLine2;
  final String sdeKp2;
  final String sdeStart2;
  final String sdeEnd2;
  final String sdeSort;
  final String lineId;
  final String lineCircle;
  final String lineDescr;
  final String lineDescrEng;

  const ScheduleEntry({
    required this.sdeCode,
    required this.sdcCode,
    required this.sdsCode,
    required this.sdeAa,
    required this.sdeLine1,
    required this.sdeKp1,
    required this.sdeStart1,
    required this.sdeEnd1,
    required this.sdeLine2,
    required this.sdeKp2,
    required this.sdeStart2,
    required this.sdeEnd2,
    required this.sdeSort,
    required this.lineId,
    required this.lineCircle,
    required this.lineDescr,
    required this.lineDescrEng,
  });

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) {
    return ScheduleEntry(
      sdeCode: map['sde_code']?.toString() ?? '',
      sdcCode: map['sdc_code']?.toString() ?? '',
      sdsCode: map['sds_code']?.toString() ?? '',
      sdeAa: map['sde_aa']?.toString() ?? '',
      sdeLine1: map['sde_line1']?.toString() ?? '',
      sdeKp1: map['sde_kp1']?.toString() ?? '',
      sdeStart1: map['sde_start1']?.toString() ?? '',
      sdeEnd1: map['sde_end1']?.toString() ?? '',
      sdeLine2: map['sde_line2']?.toString() ?? '',
      sdeKp2: map['sde_kp2']?.toString() ?? '',
      sdeStart2: map['sde_start2']?.toString() ?? '',
      sdeEnd2: map['sde_end2']?.toString() ?? '',
      sdeSort: map['sde_sort']?.toString() ?? '',
      lineId: map['line_id']?.toString() ?? '',
      lineCircle: map['line_circle']?.toString() ?? '',
      lineDescr: map['line_descr']?.toString() ?? '',
      lineDescrEng: map['line_descr_eng']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'sde_code': sdeCode,
        'sdc_code': sdcCode,
        'sds_code': sdsCode,
        'sde_aa': sdeAa,
        'sde_line1': sdeLine1,
        'sde_kp1': sdeKp1,
        'sde_start1': sdeStart1,
        'sde_end1': sdeEnd1,
        'sde_line2': sdeLine2,
        'sde_kp2': sdeKp2,
        'sde_start2': sdeStart2,
        'sde_end2': sdeEnd2,
        'sde_sort': sdeSort,
        'line_id': lineId,
        'line_circle': lineCircle,
        'line_descr': lineDescr,
        'line_descr_eng': lineDescrEng,
      };
}
