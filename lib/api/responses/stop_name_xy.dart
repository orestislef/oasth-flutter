class StopsNameXy {
  late List<StopNameXy> stopsNameXy;

  static StopsNameXy fromMap(List<dynamic> map) {
    StopsNameXy stopsNameXy = StopsNameXy();
    stopsNameXy.stopsNameXy = [];
    for (int i = 0; i < map.length; i++) {
      stopsNameXy.stopsNameXy.add(StopNameXy.fromMap(map[i]));
    }
    return stopsNameXy;
  }

  Map toJson() => {
        "stopsNameXy": stopsNameXy,
      };
}

class StopNameXy {
  String? stopDescr;
  String? stopDescrMatrixEng;
  String? stopLat;
  String? stopLng;
  String? stopHeading;
  String? stopId;
  String? isTerminal;

  static StopNameXy fromMap(Map<String, dynamic> map) {
    StopNameXy stopNameXyBean = StopNameXy();
    stopNameXyBean.stopDescr = map['stop_descr'];
    stopNameXyBean.stopDescrMatrixEng = map['stop_descr_matrix_eng'];
    stopNameXyBean.stopLat = map['stop_lat'];
    stopNameXyBean.stopLng = map['stop_lng'];
    stopNameXyBean.stopHeading = map['stop_heading'];
    stopNameXyBean.stopId = map['stop_id'];
    stopNameXyBean.isTerminal = map['isTerminal'];
    return stopNameXyBean;
  }

  Map toJson() => {
        "stop_descr": stopDescr,
        "stop_descr_matrix_eng": stopDescrMatrixEng,
        "stop_lat": stopLat,
        "stop_lng": stopLng,
        "stop_heading": stopHeading,
        "stop_id": stopId,
        "isTerminal": isTerminal,
      };
}
