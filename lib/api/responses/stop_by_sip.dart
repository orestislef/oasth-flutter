class StopBySip {
  final String id;
  final String titleEl;
  final String titleEn;
  final double lat;
  final double lng;

  const StopBySip({
    required this.id,
    required this.titleEl,
    required this.titleEn,
    required this.lat,
    required this.lng,
  });

  factory StopBySip.fromMap(Map<String, dynamic> map) {
    return StopBySip(
      id: map['id']?.toString() ?? '',
      titleEl: map['titleel']?.toString() ?? '',
      titleEn: map['titleen']?.toString() ?? '',
      lat: double.tryParse(map['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(map['lng']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'titleel': titleEl,
        'titleen': titleEn,
        'lat': lat.toString(),
        'lng': lng.toString(),
      };
}
