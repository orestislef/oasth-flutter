class LinesWithMasterLineInfo {
  late List<LineWithMasterLineInfo> linesWithMasterLineInfo;

  LinesWithMasterLineInfo.fromMap(List<dynamic> data) {
    linesWithMasterLineInfo =
        data.map((e) => LineWithMasterLineInfo.fromMap(e)).toList();
  }

  //to map
  Map<String, dynamic> toMap() {
    return {
      'linesWithMasterLineInfo':
          linesWithMasterLineInfo.map((e) => e.toMap()).toList()
    };
  }
}

class LineWithMasterLineInfo {
  String? masterLineCode;
  String? scheduleCode;
  String? lineCode;
  String? lineId;
  String? lineDescription;
  String? masterLineDMaster;

  LineWithMasterLineInfo.fromMap(Map<String, dynamic> data) {
    masterLineCode = data['ml_code'];
    scheduleCode = data['sdc_code'];
    lineCode = data['line_code'];
    lineId = data['line_id'];
    lineDescription = data['line_descr'];
    masterLineDMaster = data['mld_master'];
  }

  Map<String, dynamic> toMap() {
    return {
      'ml_code': masterLineCode,
      'sdc_code': scheduleCode,
      'line_code': lineCode,
      'line_id': lineId,
      'line_descr': lineDescription,
      'mld_master': masterLineDMaster
    };
  }
}
