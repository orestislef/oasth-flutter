class StopBySip {
  String? id;
  String? titleEl;
  String? titleEn;
  String? lat;
  String? lng;

  static StopBySip fromMap(Map<String, dynamic> map) {
    StopBySip stopBySip = StopBySip();
    stopBySip.id = map['id'];
    stopBySip.titleEl = map['titleel'];
    stopBySip.titleEn = map['titleen'];
    stopBySip.lat = map['lat'];
    stopBySip.lng = map['lng'];
    return stopBySip;
  }

  Map toJson() => {
        "id": id,
        "titleel": titleEl,
        "titleen": titleEn,
        "lat": lat,
        "lng": lng,
      };
}
