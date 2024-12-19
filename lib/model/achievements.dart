import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/model/spot.dart';
import 'package:json_annotation/json_annotation.dart';

import '../ui/game_ground.dart';
import '../utils.dart';
import 'ai/ai.dart';
import 'ai/strategy.dart';
import 'fortune.dart';
import 'matrix.dart';
import 'move.dart';


class User {
  late Achievements achievements;
  String? name;

  User() {
    achievements = Achievements();
  }

  User.fromJson(Map<String, dynamic> map) {
    name = map['name'];
    achievements = Achievements.fromJson(map['achievements']!);
  }

  Map<String, dynamic> toJson() => {
    if (name != null) "name" : name,
    "achievements" : achievements.toJson(),
  };
}

class Achievements {
  final Map<int, int> _wonOrderGames = HashMap(); // dimension, count
  final Map<int, int> _wonChaosGames = HashMap(); // dimension, count
  final Map<int, int> _lostOrderGames = HashMap(); // dimension, count
  final Map<int, int> _lostChaosGames = HashMap(); // dimension, count
  final Map<int, int> _highScoresForOrder = HashMap(); // dimension, high score
  final Map<int, int> _highScoresForChaos = HashMap(); // dimension, high score
  final Map<int, int> _totalPointsForOrder = HashMap(); // dimension, high score
  final Map<int, int> _totalPointsForChaos = HashMap(); // dimension, high score

  Achievements();

  Achievements.fromJson(Map<String, dynamic> map) {

    final Map<String, dynamic> wonOrderGamesMap = map['wonOrderGames']!;
    _wonOrderGames.addAll(wonOrderGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> wonChaosGamesMap = map['wonChaosGames']!;
    _wonChaosGames.addAll(wonChaosGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));


    final Map<String, dynamic> lostOrderGamesMap = map['lostOrderGames']!;
    _lostOrderGames.addAll(lostOrderGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> lostChaosGamesMap = map['lostChaosGames']!;
    _lostChaosGames.addAll(lostChaosGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));


    final Map<String, dynamic> highScoresForOrderMap = map['highScoresForOrder']!;
    _highScoresForOrder.addAll(highScoresForOrderMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> highScoresForChaosMap = map['highScoresForChaos']!;
    _highScoresForChaos.addAll(highScoresForChaosMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));

    final Map<String, dynamic> totalPointsForOrderMap = map['totalPointsForOrder']!;
    _totalPointsForOrder.addAll(totalPointsForOrderMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> totalPointsForChaosMap = map['totalPointsForChaos']!;
    _totalPointsForChaos.addAll(totalPointsForChaosMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
  }

  Map<String, dynamic> toJson() => {
    'wonOrderGames' : _wonOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    'wonChaosGames' : _wonChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    'lostOrderGames' : _lostOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    'lostChaosGames' : _lostChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    'highScoresForOrder' : _highScoresForOrder.map((key, value) => MapEntry(key.toString(), value)),
    'highScoresForChaos' : _highScoresForChaos.map((key, value) => MapEntry(key.toString(), value)),
    'totalPointsForOrder' : _totalPointsForOrder.map((key, value) => MapEntry(key.toString(), value)),
    'totalPointsForChaos' : _totalPointsForChaos.map((key, value) => MapEntry(key.toString(), value)),
  };

  int getWonGamesCount(Role role, int dimension) {
    if (role == Role.Order) {
      return _wonOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _wonChaosGames[dimension] ?? 0;
    }
  }

  int getLostGamesCount(Role role, int dimension) {
    if (role == Role.Order) {
      return _lostOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _lostChaosGames[dimension] ?? 0;
    }
  }

  int getTotalGameCount(Role role, int dimension) => getWonGamesCount(role, dimension) + getLostGamesCount(role, dimension);

  num getOverallGameCount() {
    return _wonOrderGames.values.fold(0, (v, e) => v + e) +
        _wonChaosGames.values.fold(0, (v, e) => v + e) +
        _lostOrderGames.values.fold(0, (v, e) => v + e) +
        _lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallWonCount() {
    return _wonOrderGames.values.fold(0, (v, e) => v + e) +
        _wonChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallLostCount() {
    return _lostOrderGames.values.fold(0, (v, e) => v + e) +
        _lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  int getHighScore(Role role, int dimension) {
    if (role == Role.Order) {
      return _highScoresForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _highScoresForChaos[dimension] ?? 0;
    }
  }

  int getTotalScore(Role role, int dimension) {
    if (role == Role.Order) {
      return _totalPointsForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _totalPointsForChaos[dimension] ?? 0;
    }
  }

  num getOverallScore() {
    return _totalPointsForOrder.values.fold(0, (v, e) => v + e) +
        _totalPointsForChaos.values.fold(0, (v, e) => v + e);
  }

  incWonGame(Role role, int dimension) {
    if (role == Role.Order) {
      _wonOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _wonChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  incLostGame(Role role, int dimension) {
    if (role == Role.Order) {
      _lostOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _lostChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  registerPointsForScores(Role role, int dimension, int points) {
    if (role == Role.Order) {
      _totalPointsForOrder.update(dimension, (old) => old + points, ifAbsent: () => points);
      _highScoresForOrder.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
    if (role == Role.Chaos) {
      _totalPointsForChaos.update(dimension, (old) => old + points, ifAbsent: () => points);
      _highScoresForChaos.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
  }

  clearAll() {
    _wonOrderGames.clear();
    _wonChaosGames.clear();
    _lostOrderGames.clear();
    _lostChaosGames.clear();
    _highScoresForOrder.clear();
    _highScoresForChaos.clear();
    _totalPointsForOrder.clear();
    _totalPointsForChaos.clear();
  }

}