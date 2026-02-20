class ScheduleDaysMasterLine {
  final List<MasterLineData> scheduleDaysMasterLine;

  const ScheduleDaysMasterLine({required this.scheduleDaysMasterLine});

  factory ScheduleDaysMasterLine.fromMap(List<dynamic> map) {
    return ScheduleDaysMasterLine(
      scheduleDaysMasterLine:
          map.map((e) => MasterLineData.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schedule_days_masterline':
            scheduleDaysMasterLine.map((e) => e.toMap()).toList(),
      };
}

class MasterLineData {
  final String scheduleDescription;
  final String scheduleDescriptionEng;
  final String scheduleCode;
  final String computed3;
  final String computed4;

  const MasterLineData({
    required this.scheduleDescription,
    required this.scheduleDescriptionEng,
    required this.scheduleCode,
    required this.computed3,
    required this.computed4,
  });

  factory MasterLineData.fromMap(Map<String, dynamic> map) {
    return MasterLineData(
      scheduleDescription: map['sdc_descr']?.toString() ?? '',
      scheduleDescriptionEng: map['sdc_descr_eng']?.toString() ?? '',
      scheduleCode: map['sdc_code']?.toString() ?? '',
      computed3: map['computed3']?.toString() ?? '',
      computed4: map['computed4']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'sdc_descr': scheduleDescription,
        'sdc_descr_eng': scheduleDescriptionEng,
        'sdc_code': scheduleCode,
        'computed3': computed3,
        'computed4': computed4,
      };
}
