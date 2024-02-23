class ScheduleDaysMasterLine {
  late List<MasterLineData> scheduleDaysMasterLine;

  static ScheduleDaysMasterLine fromMap(List<dynamic> map) {
    ScheduleDaysMasterLine scheduleDaysMasterLine = ScheduleDaysMasterLine();
    scheduleDaysMasterLine.scheduleDaysMasterLine = [];
    for (int i = 0; i < map.length; i++) {
      scheduleDaysMasterLine.scheduleDaysMasterLine
          .add(MasterLineData.fromMap(map[i]));
    }
    return scheduleDaysMasterLine;
  }

  Map toJson() => {"schedule_days_masterline": scheduleDaysMasterLine};
}

class MasterLineData {
  String? scheduleDescription;
  String? scheduleDescriptionEng;
  String? scheduleCode;
  String? computed3;
  String? computed4;

  static MasterLineData fromMap(Map<String, dynamic> map) {
    MasterLineData objBean = MasterLineData();
    objBean.scheduleDescription = map['sdc_descr'];
    objBean.scheduleDescriptionEng = map['sdc_descr_eng'];
    objBean.scheduleCode = map['sdc_code'];
    objBean.computed3 = map['computed3'];
    objBean.computed4 = map['computed4'];
    return objBean;
  }

  Map toJson() => {
        "sdc_descr": scheduleDescription,
        "sdc_descr_eng": scheduleDescriptionEng,
        "sdc_code": scheduleCode,
        "computed3": computed3,
        "computed4": computed4
      };
}
