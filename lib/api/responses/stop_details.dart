class StopArrivals {
  final List<StopDetails> stopDetails;

  const StopArrivals({required this.stopDetails});

  factory StopArrivals.fromMap(List<dynamic> map) {
    return StopArrivals(
      stopDetails: map.map((e) => StopDetails.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stopDetails': stopDetails.map((e) => e.toMap()).toList(),
      };
}

class StopDetails {
  final String btime2;
  final String routeCode;
  final String vehCode;

  const StopDetails({
    required this.btime2,
    required this.routeCode,
    required this.vehCode,
  });

  factory StopDetails.fromMap(Map<String, dynamic> map) {
    return StopDetails(
      btime2: map['btime2']?.toString() ?? '',
      routeCode: map['route_code']?.toString() ?? '',
      vehCode: map['veh_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'btime2': btime2,
        'route_code': routeCode,
        'veh_code': vehCode,
      };
}
