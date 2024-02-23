class ScheduleDaysMasterline {
  late List<ScheduleDayMasterline> scheduleDaysMasterline;

  static ScheduleDaysMasterline fromMap(List<dynamic> map) {
    ScheduleDaysMasterline obj = ScheduleDaysMasterline();
    obj.scheduleDaysMasterline = [];
    for (int i = 0; i < map.length; i++) {
      obj.scheduleDaysMasterline.add(ScheduleDayMasterline.fromMap(map[i]));
    }
    return obj;
  }

  Map toJson() => {"schedule_days_masterline": scheduleDaysMasterline};
}

class ScheduleDayMasterline {
  String? scheduleDescription;
  String? scheduleDescriptionEng;
  String? scheduleCode;
  String? computed3;
  String? computed4;

  static ScheduleDayMasterline fromMap(Map<String, dynamic> map) {
    ScheduleDayMasterline objBean = ScheduleDayMasterline();
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
