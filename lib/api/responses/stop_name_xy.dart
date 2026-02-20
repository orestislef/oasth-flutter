class StopsNameXy {
  final List<StopNameXy> stopsNameXy;

  const StopsNameXy({required this.stopsNameXy});

  factory StopsNameXy.fromMap(List<dynamic> map) {
    return StopsNameXy(
      stopsNameXy: map.map((e) => StopNameXy.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stopsNameXy': stopsNameXy.map((e) => e.toMap()).toList(),
      };
}

class StopNameXy {
  final String stopDescr;
  final String stopDescrMatrixEng;
  final double stopLat;
  final double stopLng;
  final String stopHeading;
  final String stopId;
  final String isTerminal;

  const StopNameXy({
    required this.stopDescr,
    required this.stopDescrMatrixEng,
    required this.stopLat,
    required this.stopLng,
    required this.stopHeading,
    required this.stopId,
    required this.isTerminal,
  });

  factory StopNameXy.fromMap(Map<String, dynamic> map) {
    return StopNameXy(
      stopDescr: map['stop_descr']?.toString() ?? '',
      stopDescrMatrixEng: map['stop_descr_matrix_eng']?.toString() ?? '',
      stopLat: double.tryParse(map['stop_lat']?.toString() ?? '') ?? 0.0,
      stopLng: double.tryParse(map['stop_lng']?.toString() ?? '') ?? 0.0,
      stopHeading: map['stop_heading']?.toString() ?? '',
      stopId: map['stop_id']?.toString() ?? '',
      isTerminal: map['isTerminal']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'stop_descr': stopDescr,
        'stop_descr_matrix_eng': stopDescrMatrixEng,
        'stop_lat': stopLat.toString(),
        'stop_lng': stopLng.toString(),
        'stop_heading': stopHeading,
        'stop_id': stopId,
        'isTerminal': isTerminal,
      };
}
