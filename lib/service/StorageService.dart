import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/play.dart';
import '../model/user.dart';
import 'PreferenceService.dart';



class StorageService {

  static final StorageService _service = StorageService._internal();

  factory StorageService() {
    return _service;
  }

  StorageService._internal() {}


  void saveUser(User user) {
    final jsonToSave = jsonEncode(user);
    debugPrint("Save current user:");
    debugPrint(_getPrettyJSONString(user));
    PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
  }


  void savePlay(Play play) {
    final jsonToSave = jsonEncode(play);
    debugPrint(_getPrettyJSONString(play));
    final key = play.isMultiplayerPlay
        ? PrefDef('${PreferenceService.DATA_PLAY_PREFIX}${play.header.playId}', null)
        : PreferenceService.DATA_CURRENT_PLAY;
    debugPrint("Save ${key.key} play");
    PreferenceService().setString(key, jsonToSave);

    savePlayHeader(play.header);
  }

  void savePlayHeader(PlayHeader header) {
    final jsonToSave = jsonEncode(header);
    debugPrint(_getPrettyJSONString(header));

    final key = PrefDef(PreferenceService.DATA_PLAY_HEADER_PREFIX + header.playId, null);
    debugPrint("Save ${key.key} play header");
    PreferenceService().setString(key, jsonToSave);
  }

  void deletePlayHeaderAndPlay(String playId) {
    PreferenceService().remove(
        PrefDef(PreferenceService.DATA_PLAY_HEADER_PREFIX + playId, null));
    PreferenceService().remove(
        PrefDef(PreferenceService.DATA_PLAY_PREFIX + playId, null));
  }


  Future<User?> loadUser() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_USER);
    if (json == null) return null;

    final map = jsonDecode(json);
    final user = User.fromJson(map);
    debugPrint("Loaded user: $user");
    return user;
  }

  Future<Play?> _loadPlay(PrefDef key) async {
    final json = await PreferenceService().getString(key);
    if (json == null) return null;

    final map = jsonDecode(json);
    final play = Play.fromJson(map);
    debugPrint("Loaded play state: $play");
    return play;
  }

  Future<Play?> loadCurrentSinglePlay() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_PLAY);
    if (json == null) return null;

    final map = jsonDecode(json);
    final play = Play.fromJson(map);
    debugPrint("Loaded play state: $play");
    final header = await _loadPlayHeader(PreferenceService.DATA_CURRENT_PLAY_HEADER);
    if (header == null) return null;
    play.header = header;
    return play;
  }

  Future<PlayHeader?> _loadPlayHeader(PrefDef prefDef) async {
    final json = await PreferenceService().getString(prefDef);
    if (json == null) return null;

    final map = jsonDecode(json);
    final header = PlayHeader.fromJson(map);
    debugPrint("Loaded header state: $header");
    return header;
  }

  Future<PlayHeader?> loadPlayHeader(String playId) async {
    final key = PrefDef(PreferenceService.DATA_PLAY_HEADER_PREFIX + playId, null);
    return _loadPlayHeader(key);
  }

  Future<Play?> loadPlayFromHeader(PlayHeader header) async {
    final key = PrefDef(PreferenceService.DATA_PLAY_PREFIX + header.playId, null);
    final play = await _loadPlay(key);
    play?.header = header;
    return play;
  }

  Future<List<PlayHeader>> loadAllPlayHeaders() async {

    final keys = await PreferenceService().getKeys(PreferenceService.DATA_PLAY_HEADER_PREFIX);

    final futures = keys
        .map((key) => PrefDef(key, null))
        .map((prefDef) => PreferenceService().getString(prefDef));

    final values = await Future.wait(futures);

    return values
        .where((value) => value != null)
        .map((json) {
          final map = jsonDecode(json!);
          return PlayHeader.fromJson(map);
        })
        .toList();


  }


  String _getPrettyJSONString(jsonObject){
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }

}

