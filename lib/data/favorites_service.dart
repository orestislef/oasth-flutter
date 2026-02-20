import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _keyFavoriteLines = 'favorite_lines';

  static final FavoritesService _instance = FavoritesService._();
  factory FavoritesService() => _instance;
  FavoritesService._();

  Set<String> _favorites = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteLines) ?? [];
    _favorites = list.toSet();
    _initialized = true;
  }

  Set<String> get favorites => Set.unmodifiable(_favorites);

  bool isFavorite(String lineId) => _favorites.contains(lineId);

  Future<bool> toggleFavorite(String lineId) async {
    if (_favorites.contains(lineId)) {
      _favorites.remove(lineId);
    } else {
      _favorites.add(lineId);
    }
    await _persist();
    return _favorites.contains(lineId);
  }

  Future<void> addFavorite(String lineId) async {
    if (_favorites.add(lineId)) {
      await _persist();
    }
  }

  Future<void> removeFavorite(String lineId) async {
    if (_favorites.remove(lineId)) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavoriteLines, _favorites.toList());
  }
}
