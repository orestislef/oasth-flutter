import 'package:shared_preferences/shared_preferences.dart';

import '../enums/map_type.dart';

class MapTypeHelper {
  static const String _key = 'map_type';

  static Future<MapType> getMapType() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_key) ?? MapType.google.id;
    return MapType.fromId(id);
  }

  static Future<void> setMapType(MapType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, type.id);
  }
}
