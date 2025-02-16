import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/achievements.dart';
import '../model/play.dart';
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


  void savePlay(PrefDef key, Play play) {
    final jsonToSave = jsonEncode(play);
    debugPrint(_getPrettyJSONString(play));
    debugPrint("Save ${key.key} play");
    PreferenceService().setString(key, jsonToSave);

    final playHeader = play.toMultiPlayHeader();
    if (playHeader != null) {
      savePlayHeader(play.id, playHeader);
    }
  }

  void savePlayHeader(String playId, MultiPlayHeader header) {
    final jsonToSave = jsonEncode(header);
    debugPrint(_getPrettyJSONString(header));

    final key = PrefDef(playId, null);
    debugPrint("Save ${key.key} play header");
    PreferenceService().setString(key, jsonToSave);
  }


  Future<User?> loadUser() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_USER);
    if (json == null) return null;

    final map = jsonDecode(json);
    final user = User.fromJson(map);
    debugPrint("Loaded user: $user");
    return user;
  }

  Future<Play?> loadPlay(PrefDef key) async {
    final json = await PreferenceService().getString(key);
    if (json == null) return null;

    final map = jsonDecode(json);
    final play = Play.fromJson(map);
    debugPrint("Loaded play state: $play");
    return play;
  }

  Future<MultiPlayHeader?> loadPlayHeader(String playId) async {
    final key = PrefDef(playId, null);

    final json = await PreferenceService().getString(key);
    if (json == null) return null;

    final map = jsonDecode(json);
    final header = MultiPlayHeader.fromJson(map);
    debugPrint("Loaded header state: $header");
    return header;
  }


  String _getPrettyJSONString(jsonObject){
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }

}

