
import 'dart:ui';

import 'package:hyle_x/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum SignMessages {
  Never, OnDemand, Always;

  String getName(AppLocalizations l10n) {
    return switch(this) {
      SignMessages.Never => l10n.settings_signMessages_Never,
      SignMessages.OnDemand => l10n.settings_signMessages_OnDemand,
      SignMessages.Always => l10n.settings_signMessages_Always,
    };
  }
}

class PreferenceService {

  static final DATA_CURRENT_USER = 'data/user/current';

  static final DATA_PLAY_PREFIX = 'data/play';
  static final DATA_PLAY_HEADER_PREFIX = 'data/playHeader';
  static final DATA_PLAY_SNAPSHOT_PREFIX = 'data/snapshot/play';
  static final DATA_PLAY_SNAPSHOT_HEADER_PREFIX = 'data/snapshot/playHeader';
  static final DATA_CURRENT_PLAY = '${DATA_PLAY_PREFIX}/current';
  static final DATA_CURRENT_PLAY_HEADER = '${DATA_CURRENT_PLAY}/header';

  static final DATA_LOGO_COLOR_H = 'data/logoColor/h';
  static final DATA_LOGO_COLOR_Y = 'data/logoColor/y';
  static final DATA_LOGO_COLOR_L = 'data/logoColor/l';
  static final DATA_LOGO_COLOR_E = 'data/logoColor/e';

  static final PREF_SHOW_COORDINATES = 'pref/showCoordinates';
  static final PREF_SHOW_HINTS = 'pref/showHints';
  static final PREF_SHOW_POINTS = 'pref/showPoints';
  static final PREF_SHOW_CHIP_ERRORS = 'pref/showPChipErrors';
  static final PREF_MATCH_SORT_ORDER = 'pref/matchSortOrder';
  static final PREF_SIGN_ALL_MESSAGES = 'pref/signAllMessages';

  static final PreferenceService _service = PreferenceService._internal();
  

  bool showCoordinates = true;
  bool showHints = true;
  bool showPoints = true;
  bool showChipErrors = true;
  SignMessages signMessages = SignMessages.Never;

  factory PreferenceService() {
    return _service;
  }

  PreferenceService._internal() {
    // load cache
    _loadCachedBoolPref(PREF_SHOW_COORDINATES, (v) => showCoordinates = v);
    _loadCachedBoolPref(PREF_SHOW_POINTS, (v) => showPoints = v);
    _loadCachedBoolPref(PREF_SHOW_HINTS, (v) => showHints = v);
    _loadCachedBoolPref(PREF_SHOW_CHIP_ERRORS, (v) => showChipErrors = v);
    getInt(PREF_SIGN_ALL_MESSAGES).then((value) {
      if (value != null) {
        signMessages = SignMessages.values.firstWhere((e) => e.index == value);
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

  _loadCachedBoolPref(String key, Function(bool) setter) {
    getBool(key).then((value) {
      if (value != null) {
        setter(value);
      }
    });
  }
}

