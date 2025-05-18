import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';


class PrefDef {
  String key;
  dynamic defaultValue;
  PrefDef(this.key, this.defaultValue);
}
class PreferenceService {

  static final DATA_CURRENT_USER = PrefDef('data/user/current', null);

  static final DATA_PLAY_PREFIX = 'data/play/';
  static final DATA_PLAY_HEADER_PREFIX = 'data/playHeader/';
  static final DATA_CURRENT_PLAY = PrefDef('${DATA_PLAY_PREFIX}current', null);
  static final DATA_CURRENT_PLAY_HEADER = PrefDef('${DATA_CURRENT_PLAY}/header', null);

  static final PreferenceService _service = PreferenceService._internal();

  factory PreferenceService() {
    return _service;
  }

  PreferenceService._internal() {}

  Future<String?> getString(PrefDef def) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(def.key)??def.defaultValue;
  }

  Future<int?> getInt(PrefDef def) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(def.key)??def.defaultValue;
  }

  Future<bool?> getBool(PrefDef def) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(def.key)??def.defaultValue;
  }

  Future<List<String>> getKeys(String prefix) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
  }

  Future<bool> setString(PrefDef def, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(def.key, value);
  }

  Future<bool> setInt(PrefDef def, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(def.key, value);
  }

  Future<bool> setBool(PrefDef def, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(def.key, value);
  }

  Future<bool> remove(PrefDef def) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.remove(def.key);
  }

}

