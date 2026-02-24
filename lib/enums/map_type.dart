enum MapType {
  osm(0),
  google(1),
  satellite(-1);

  final int id;
  const MapType(this.id);

  static MapType fromId(int id) {
    return MapType.values
        .firstWhere((e) => e.id == id, orElse: () => MapType.google);
  }
}
