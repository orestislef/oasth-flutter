class LinesWithMasterLineInfo {
  final List<LineWithMasterLineInfo> linesWithMasterLineInfo;

  const LinesWithMasterLineInfo({required this.linesWithMasterLineInfo});

  factory LinesWithMasterLineInfo.fromMap(List<dynamic> data) {
    return LinesWithMasterLineInfo(
      linesWithMasterLineInfo:
          data.map((e) => LineWithMasterLineInfo.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'linesWithMasterLineInfo':
            linesWithMasterLineInfo.map((e) => e.toMap()).toList(),
      };
}

class LineWithMasterLineInfo {
  final String masterLineCode;
  final String scheduleCode;
  final String lineCode;
  final String lineId;
  final String lineDescription;
  final String lineDescriptionEng;
  final String masterLineDMaster;

  const LineWithMasterLineInfo({
    required this.masterLineCode,
    required this.scheduleCode,
    required this.lineCode,
    required this.lineId,
    required this.lineDescription,
    required this.lineDescriptionEng,
    required this.masterLineDMaster,
  });

  factory LineWithMasterLineInfo.fromMap(Map<String, dynamic> data) {
    return LineWithMasterLineInfo(
      masterLineCode: data['ml_code']?.toString() ?? '',
      scheduleCode: data['sdc_code']?.toString() ?? '',
      lineCode: data['line_code']?.toString() ?? '',
      lineId: data['line_id']?.toString() ?? '',
      lineDescription: data['line_descr']?.toString() ?? '',
      lineDescriptionEng: data['line_descr_eng']?.toString() ?? '',
      masterLineDMaster: data['mld_master']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'ml_code': masterLineCode,
        'sdc_code': scheduleCode,
        'line_code': lineCode,
        'line_id': lineId,
        'line_descr': lineDescription,
        'line_descr_eng': lineDescriptionEng,
        'mld_master': masterLineDMaster,
      };
}
