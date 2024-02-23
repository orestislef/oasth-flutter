class StopArrivals {
  List<StopDetails> stopDetails = [];

  StopArrivals({required this.stopDetails});

  factory StopArrivals.fromMap(List<dynamic> map) {
    return StopArrivals(
      stopDetails: List<StopDetails>.from(
        map.map((stopDetail) => StopDetails.fromMap(stopDetail)),
      ),
    );
  }
}

class StopDetails {
  String? btime2;
  String? routeCode;
  String? vehCode;

  StopDetails({
    this.btime2,
    this.routeCode,
    this.vehCode,
  });

  factory StopDetails.fromMap(Map<String, dynamic> map) {
    return StopDetails(
      btime2: map['btime2'],
      routeCode: map['route_code'],
      vehCode: map['veh_code'],
    );
  }

  Map<String, dynamic> toJson() => {
    "btime2": btime2,
    "route_code": routeCode,
    "veh_code": vehCode,
  };
}
