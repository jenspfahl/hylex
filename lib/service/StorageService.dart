import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hyle_x/model/common.dart';

import '../model/play.dart';
import '../model/user.dart';
import '../ui/pages/multi_player_matches.dart';
import 'PreferenceService.dart';



class StorageService {

  static final StorageService _service = StorageService._internal();

  static bool enableMocking = false;

  factory StorageService() {
    return _service;
  }

  StorageService._internal() {}


  Future<bool> saveUser(User user) {
    final jsonToSave = jsonEncode(user);
    debugPrint("Save current user:");
    //debugPrint(_getPrettyJSONString(user));
    if (enableMocking) return Future.value(true);
    return PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
  }

  Future<User?> loadUser() async {
    if (enableMocking) return Future.value(null);

    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_USER);
    if (json == null) return null;

    final map = jsonDecode(json);
    final user = User.fromJson(map);
    debugPrint("Loaded user: $user");
    return user;
  }
  
  Future<bool> savePlay(Play play) async {
    if (enableMocking) return Future.value(true);

    final headerKey = play.multiPlay
        ? _getPlayHeaderKey(play.header.playId)
        : PreferenceService.DATA_CURRENT_PLAY_HEADER;

    final key = play.multiPlay
        ? _getPlayKey(play.header.playId)
        : PreferenceService.DATA_CURRENT_PLAY;


    final results = await Future.wait([
        _saveRawPlayHeader(headerKey, play.header),
        _saveRawPlay(key, play),
    ]);

    return !results.any((e) => !e);
  }

  Future<bool> _saveRawPlay(String key, Play play) {
    debugPrint("Save ${key} play:");
    debugPrint(_getPrettyJSONString(play));
    final jsonToSave = jsonEncode(play);
    return PreferenceService().setString(key, jsonToSave);
  }

  Future<bool> savePlayHeader(PlayHeader header) async {
    if (enableMocking) return Future.value(true);

    final key = _getPlayHeaderKey(header.playId);
    var saved = await _saveRawPlayHeader(key, header);

    globalMultiPlayerMatchesKey.currentState?.playHeaderChanged();

    return saved;
  }

  Future<Play?> loadCurrentSinglePlay() async {
    if (enableMocking) return Future.value(null);

    final play = await _loadPlay(PreferenceService.DATA_CURRENT_PLAY);
    final header = await _loadPlayHeader(PreferenceService.DATA_CURRENT_PLAY_HEADER);
    if (play == null || header == null) return null;
    play.header = header;
    return play;
  }

  Future<PlayHeader?> loadPlayHeader(String playId) async {
    if (enableMocking) return Future.value(null);

    final key = _getPlayHeaderKey(playId);
    return _loadPlayHeader(key);
  }

  Future<Play?> loadPlayFromHeader(PlayHeader header) async {
    if (enableMocking) return Future.value(null);

    debugPrint("Load play from header $header");
    final reloadedHeader = await _loadPlayHeader(_getPlayHeaderKey(header.playId));
    if (reloadedHeader == null) {
      return Future.value(null);
    }
    final play = await _loadPlay(_getPlayKey(header.playId));
    play?.header = reloadedHeader;
    return play;
  }

  Future<List<PlayHeader>> loadAllPlayHeaders() async {
    if (enableMocking) return Future.value([]);

    debugPrint("Load all headers");
    final keys = await PreferenceService().getKeys(PreferenceService.DATA_PLAY_HEADER_PREFIX);

    if (keys.isEmpty) {
      return Future.value(<PlayHeader>[]);
    }
    final futures = keys
        .map((key) => PreferenceService().getString(key));

    final values = await Future.wait(futures);

    return values
        .where((value) => value != null)
        .map((json) {
          final map = jsonDecode(json!);
          _getPrettyJSONString(map);
          return PlayHeader.fromJson(map);
        })
        .toList();


  }

  Future<void> deletePlayHeaderAndPlay(String playId) async {
    if (enableMocking) return Future.value(null);

    final key = _getPlayHeaderKey(playId);

    await Future.wait([
      PreferenceService().remove(key),
      PreferenceService().remove(key)]
    );
  }

  Future<bool> _saveRawPlayHeader(String key, PlayHeader header) {
    debugPrint("Save ${key} play header:");
    final jsonToSave = jsonEncode(header);
    debugPrint(_getPrettyJSONString(header));
    return PreferenceService().setString(key, jsonToSave);
  }

  String _getPlayKey(String playId) => '${PreferenceService.DATA_PLAY_PREFIX}/$playId';
  String _getPlayHeaderKey(String playId) => '${PreferenceService.DATA_PLAY_HEADER_PREFIX}/$playId';

  Future<Play?> _loadPlay(String key) async {
    final json = await PreferenceService().getString(key);
    if (json == null) return null;

    final map = jsonDecode(json);
    final play = Play.fromJson(map);
    debugPrint("Loaded play: $play");
    debugPrint(_getPrettyJSONString(json));
    return play;
  }

  Future<PlayHeader?> _loadPlayHeader(String key) async {
    final json = await PreferenceService().getString(key);
    if (json == null) return null;

    final map = jsonDecode(json);
    final header = PlayHeader.fromJson(map);
    debugPrint("Loaded play header: $header");
    debugPrint(_getPrettyJSONString(json));
    return header;
  }


  String _getPrettyJSONString(jsonObject){
    var encoder = const JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }

}

