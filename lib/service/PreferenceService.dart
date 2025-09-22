
import 'package:shared_preferences/shared_preferences.dart';


class PreferenceService {

  static final DATA_CURRENT_USER = 'data/user/current';

  static final DATA_PLAY_PREFIX = 'data/play';
  static final DATA_PLAY_HEADER_PREFIX = 'data/playHeader';
  static final DATA_CURRENT_PLAY = '${DATA_PLAY_PREFIX}/current';
  static final DATA_CURRENT_PLAY_HEADER = '${DATA_CURRENT_PLAY}/header';
  
  static final PREF_SHOW_COORDINATES = 'pref/showCoordinates';
  static final PREF_MATCH_SORT_ORDER = 'pref/matchSortOrder';

  static final PreferenceService _service = PreferenceService._internal();

  bool showCoordinates = true;

  factory PreferenceService() {
    return _service;
  }

  PreferenceService._internal() {
    // load cache
    getBool(PREF_SHOW_COORDINATES).then((value) {
      if (value != null) {
        showCoordinates = value;
      }
    });
  }

  Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(key);
  }

  Future<bool?> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(key);
  }

  Future<List<String>> getKeys(String prefix) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
  }

  Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  Future<bool> setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(key, value);
  }

  Future<bool> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.remove(key);
  }

}

