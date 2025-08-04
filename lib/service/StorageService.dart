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
    //debugPrint(_getPrettyJSONString(user));
    PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
  }

  Future<User?> loadUser() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_USER);
    if (json == null) return null;

    final map = jsonDecode(json);
    final user = User.fromJson(map);
    debugPrint("Loaded user: $user");
    return user;
  }
  
  Future<bool> savePlay(Play play) async {

    final headerKey = play.isMultiplayerPlay
        ? _getPlayHeaderKey(play.header.playId)
        : PreferenceService.DATA_CURRENT_PLAY_HEADER;

    final key = play.isMultiplayerPlay
        ? _getPlayKey(play.header.playId)
        : PreferenceService.DATA_CURRENT_PLAY;


    final results = await Future.wait([
        _saveRawPlayHeader(headerKey, play.header),
        _saveRawPlay(key, play)
    ]);

    return !results.any((e) => !e);
  }

  Future<bool> _saveRawPlay(String key, Play play) {
    debugPrint("Save ${key} play:");
    debugPrint(_getPrettyJSONString(play));
    final jsonToSave = jsonEncode(play);
    return PreferenceService().setString(key, jsonToSave);
  }

  Future<bool> savePlayHeader(PlayHeader header) {
    final key = _getPlayHeaderKey(header.playId);
    return _saveRawPlayHeader(key, header);
  }

  Future<Play?> loadCurrentSinglePlay() async {
    final play = await _loadPlay(PreferenceService.DATA_CURRENT_PLAY);
    final header = await _loadPlayHeader(PreferenceService.DATA_CURRENT_PLAY_HEADER);
    if (play == null || header == null) return null;
    play.header = header;
    return play;
  }

  Future<PlayHeader?> loadPlayHeader(String playId) async {
    final key = _getPlayHeaderKey(playId);
    return _loadPlayHeader(key);
  }

  Future<Play?> loadPlayFromHeader(PlayHeader header) async {
    final key = _getPlayKey(header.playId);
    final play = await _loadPlay(key);
    play?.header = header;
    return play;
  }

  Future<List<PlayHeader>> loadAllPlayHeaders() async {

    final keys = await PreferenceService().getKeys(PreferenceService.DATA_PLAY_HEADER_PREFIX);

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

