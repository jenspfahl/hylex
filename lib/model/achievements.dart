import 'dart:collection';
import 'dart:math';


import 'common.dart';

enum Scope {All, Single, Multi}


class Stats {
  final Map<int, int> wonOrderGames = HashMap(); // dimension, count
  final Map<int, int> wonChaosGames = HashMap(); // dimension, count
  final Map<int, int> lostOrderGames = HashMap(); // dimension, count
  final Map<int, int> lostChaosGames = HashMap(); // dimension, count
  final Map<int, int> highScoresForOrder = HashMap(); // dimension, high score
  final Map<int, int> highScoresForChaos = HashMap(); // dimension, high score
  final Map<int, int> totalPointsForOrder = HashMap(); // dimension, high score
  final Map<int, int> totalPointsForChaos = HashMap(); // dimension, high score
}

class Achievements {

  final Stats allStats = Stats();
  final Stats singleStats = Stats();
  final Stats multiStats = Stats();


  Achievements();

  Achievements.fromJson(Map<String, dynamic> map) {
    loadStatsFromJson("", map, allStats);
    loadStatsFromJson("single_", map, singleStats);
    loadStatsFromJson("multi_", map, multiStats);

  }

  loadStatsFromJson(String prefix, Map<String, dynamic> map, Stats stats) {

    final Map<String, dynamic> wonOrderGamesMap = map[prefix + 'wonOrderGames']!;
    stats.wonOrderGames.addAll(wonOrderGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> wonChaosGamesMap = map[prefix + 'wonChaosGames']!;
    stats.wonChaosGames.addAll(wonChaosGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));


    final Map<String, dynamic> lostOrderGamesMap = map[prefix + 'lostOrderGames']!;
    stats.lostOrderGames.addAll(lostOrderGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> lostChaosGamesMap = map[prefix + 'lostChaosGames']!;
    stats.lostChaosGames.addAll(lostChaosGamesMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));


    final Map<String, dynamic> highScoresForOrderMap = map[prefix + 'highScoresForOrder']!;
    stats.highScoresForOrder.addAll(highScoresForOrderMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> highScoresForChaosMap = map[prefix + 'highScoresForChaos']!;
    stats.highScoresForChaos.addAll(highScoresForChaosMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));

    final Map<String, dynamic> totalPointsForOrderMap = map[prefix + 'totalPointsForOrder']!;
    stats.totalPointsForOrder.addAll(totalPointsForOrderMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
    final Map<String, dynamic> totalPointsForChaosMap = map[prefix + 'totalPointsForChaos']!;
    stats.totalPointsForChaos.addAll(totalPointsForChaosMap.map((key, value) {
      return MapEntry(int.parse(key), value);
    }));
  }

  Map<String, dynamic> toJson() {
    final map = saveStatsToJson("", allStats);
    map.addAll(saveStatsToJson("single_", singleStats));
    map.addAll(saveStatsToJson("multi_", multiStats));
    return map;
  }

  Map<String, dynamic> saveStatsToJson(String prefix, Stats stats) => {
    prefix + 'wonOrderGames' : stats.wonOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'wonChaosGames' : stats.wonChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'lostOrderGames' : stats.lostOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'lostChaosGames' : stats.lostChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'highScoresForOrder' : stats.highScoresForOrder.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'highScoresForChaos' : stats.highScoresForChaos.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'totalPointsForOrder' : stats.totalPointsForOrder.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'totalPointsForChaos' : stats.totalPointsForChaos.map((key, value) => MapEntry(key.toString(), value)),
  };

  Stats _getStatsForScope(Scope scope) => switch (scope) {
      Scope.All => allStats,
      Scope.Single => singleStats,
      Scope.Multi => multiStats,
    };

  int getWonGamesCount(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getStatsForScope(scope).wonOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getStatsForScope(scope).wonChaosGames[dimension] ?? 0;
    }
  }

  int getLostGamesCount(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getStatsForScope(scope).lostOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getStatsForScope(scope).lostChaosGames[dimension] ?? 0;
    }
  }

  int getTotalGameCount(Role role, int dimension, Scope scope) =>
      getWonGamesCount(role, dimension, scope) + getLostGamesCount(role, dimension, scope);

  num getOverallGameCount(Scope scope) {
    return _getStatsForScope(scope).wonOrderGames.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).wonChaosGames.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).lostOrderGames.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallWonCount(Scope scope) {
    return _getStatsForScope(scope).wonOrderGames.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).wonChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallLostCount(Scope scope) {
    return _getStatsForScope(scope).lostOrderGames.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  int getHighScore(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getStatsForScope(scope).highScoresForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getStatsForScope(scope).highScoresForChaos[dimension] ?? 0;
    }
  }

  int getTotalScore(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getStatsForScope(scope).totalPointsForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getStatsForScope(scope).totalPointsForChaos[dimension] ?? 0;
    }
  }

  num getOverallScore(Scope scope) {
    return _getStatsForScope(scope).totalPointsForOrder.values.fold(0, (v, e) => v + e) +
        _getStatsForScope(scope).totalPointsForChaos.values.fold(0, (v, e) => v + e);
  }

  incWonGame(Role role, int dimension, bool isMultiPlay) {
    _incWonGame(role, dimension, Scope.All);
    _incWonGame(role, dimension, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _incWonGame(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      _getStatsForScope(scope).wonOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _getStatsForScope(scope).wonChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  incLostGame(Role role, int dimension, bool isMultiPlay) {
    _incLostGame(role, dimension, Scope.All);
    _incLostGame(role, dimension, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _incLostGame(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      _getStatsForScope(scope).lostOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _getStatsForScope(scope).lostChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  registerPointsForScores(Role role, int dimension, int points, bool isMultiPlay) {
    _registerPointsForScores(role, dimension, points, Scope.All);
    _registerPointsForScores(role, dimension, points, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _registerPointsForScores(Role role, int dimension, int points, Scope scope) {
    if (role == Role.Order) {
      _getStatsForScope(scope).totalPointsForOrder.update(dimension, (old) => old + points, ifAbsent: () => points);
      _getStatsForScope(scope).highScoresForOrder.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
    if (role == Role.Chaos) {
      _getStatsForScope(scope).totalPointsForChaos.update(dimension, (old) => old + points, ifAbsent: () => points);
      _getStatsForScope(scope).highScoresForChaos.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
  }

  clearAll() {
    Scope.values.forEach(_clearAll);
  }

  _clearAll(Scope scope) {
    _getStatsForScope(scope).wonOrderGames.clear();
    _getStatsForScope(scope).wonChaosGames.clear();
    _getStatsForScope(scope).lostOrderGames.clear();
    _getStatsForScope(scope).lostChaosGames.clear();
    _getStatsForScope(scope).highScoresForOrder.clear();
    _getStatsForScope(scope).highScoresForChaos.clear();
    _getStatsForScope(scope).totalPointsForOrder.clear();
    _getStatsForScope(scope).totalPointsForChaos.clear();
  }

}