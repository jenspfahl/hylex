import 'dart:collection';
import 'dart:math';


import 'common.dart';

enum Scope {All, Single, Multi}


class _Data {
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

  final _Data allData = _Data();
  final _Data singleData = _Data();
  final _Data multiData = _Data();


  Achievements();

  Achievements.fromJson(Map<String, dynamic> map) {
    loadDataFromJson("", map, allData);
    loadDataFromJson("single_", map, singleData);
    loadDataFromJson("multi_", map, multiData);

  }

  loadDataFromJson(String prefix, Map<String, dynamic> map, _Data data) {

    final Map<String, dynamic>? wonOrderGamesMap = map[prefix + 'wonOrderGames'];
    if (wonOrderGamesMap != null) {
      data.wonOrderGames.addAll(wonOrderGamesMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }

    final Map<String, dynamic>? wonChaosGamesMap = map[prefix + 'wonChaosGames'];
    if (wonChaosGamesMap != null) {
      data.wonChaosGames.addAll(wonChaosGamesMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }


    final Map<String, dynamic>? lostOrderGamesMap = map[prefix + 'lostOrderGames'];
    if (lostOrderGamesMap != null) {
      data.lostOrderGames.addAll(lostOrderGamesMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }

    final Map<String, dynamic>? lostChaosGamesMap = map[prefix + 'lostChaosGames'];
    if (lostChaosGamesMap != null) {
      data.lostChaosGames.addAll(lostChaosGamesMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }


    final Map<String, dynamic>? highScoresForOrderMap = map[prefix + 'highScoresForOrder'];
    if (highScoresForOrderMap != null) {
      data.highScoresForOrder.addAll(highScoresForOrderMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }

    final Map<String, dynamic>? highScoresForChaosMap = map[prefix + 'highScoresForChaos'];
    if (highScoresForChaosMap != null) {
      data.highScoresForChaos.addAll(highScoresForChaosMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }

    final Map<String, dynamic>? totalPointsForOrderMap = map[prefix + 'totalPointsForOrder'];
    if (totalPointsForOrderMap != null) {
      data.totalPointsForOrder.addAll(totalPointsForOrderMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }

    final Map<String, dynamic>? totalPointsForChaosMap = map[prefix + 'totalPointsForChaos'];
    if (totalPointsForChaosMap != null) {
      data.totalPointsForChaos.addAll(totalPointsForChaosMap.map((key, value) {
        return MapEntry(int.parse(key), value);
      }));
    }
  }

  Map<String, dynamic> toJson() {
    final map = saveDataToJson("", allData);
    map.addAll(saveDataToJson("single_", singleData));
    map.addAll(saveDataToJson("multi_", multiData));
    return map;
  }

  Map<String, dynamic> saveDataToJson(String prefix, _Data data) => {
    prefix + 'wonOrderGames' : data.wonOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'wonChaosGames' : data.wonChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'lostOrderGames' : data.lostOrderGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'lostChaosGames' : data.lostChaosGames.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'highScoresForOrder' : data.highScoresForOrder.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'highScoresForChaos' : data.highScoresForChaos.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'totalPointsForOrder' : data.totalPointsForOrder.map((key, value) => MapEntry(key.toString(), value)),
    prefix + 'totalPointsForChaos' : data.totalPointsForChaos.map((key, value) => MapEntry(key.toString(), value)),
  };

  _Data _getDataForScope(Scope scope) => switch (scope) {
      Scope.All => allData,
      Scope.Single => singleData,
      Scope.Multi => multiData,
    };

  int getWonGamesCount(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getDataForScope(scope).wonOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getDataForScope(scope).wonChaosGames[dimension] ?? 0;
    }
  }

  int getLostGamesCount(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getDataForScope(scope).lostOrderGames[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getDataForScope(scope).lostChaosGames[dimension] ?? 0;
    }
  }

  int getTotalGameCount(Role role, int dimension, Scope scope) =>
      getWonGamesCount(role, dimension, scope) + getLostGamesCount(role, dimension, scope);

  num getOverallGameCount(Scope scope) {
    return _getDataForScope(scope).wonOrderGames.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).wonChaosGames.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).lostOrderGames.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallWonCount(Scope scope) {
    return _getDataForScope(scope).wonOrderGames.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).wonChaosGames.values.fold(0, (v, e) => v + e);
  }

  num getOverallLostCount(Scope scope) {
    return _getDataForScope(scope).lostOrderGames.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).lostChaosGames.values.fold(0, (v, e) => v + e);
  }

  int getHighScore(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getDataForScope(scope).highScoresForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getDataForScope(scope).highScoresForChaos[dimension] ?? 0;
    }
  }

  int getTotalScore(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      return _getDataForScope(scope).totalPointsForOrder[dimension] ?? 0;
    }
    else { // if (role == Role.Chaos) {
      return _getDataForScope(scope).totalPointsForChaos[dimension] ?? 0;
    }
  }

  num getOverallScore(Scope scope) {
    return _getDataForScope(scope).totalPointsForOrder.values.fold(0, (v, e) => v + e) +
        _getDataForScope(scope).totalPointsForChaos.values.fold(0, (v, e) => v + e);
  }

  incWonGame(Role role, int dimension, bool isMultiPlay) {
    _incWonGame(role, dimension, Scope.All);
    _incWonGame(role, dimension, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _incWonGame(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      _getDataForScope(scope).wonOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _getDataForScope(scope).wonChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  incLostGame(Role role, int dimension, bool isMultiPlay) {
    _incLostGame(role, dimension, Scope.All);
    _incLostGame(role, dimension, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _incLostGame(Role role, int dimension, Scope scope) {
    if (role == Role.Order) {
      _getDataForScope(scope).lostOrderGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
    if (role == Role.Chaos) {
      _getDataForScope(scope).lostChaosGames.update(dimension, (old) => old + 1, ifAbsent: () => 1);
    }
  }

  registerPointsForScores(Role role, int dimension, int points, bool isMultiPlay) {
    _registerPointsForScores(role, dimension, points, Scope.All);
    _registerPointsForScores(role, dimension, points, isMultiPlay ? Scope.Multi : Scope.Single);
  }

  _registerPointsForScores(Role role, int dimension, int points, Scope scope) {
    if (role == Role.Order) {
      _getDataForScope(scope).totalPointsForOrder.update(dimension, (old) => old + points, ifAbsent: () => points);
      _getDataForScope(scope).highScoresForOrder.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
    if (role == Role.Chaos) {
      _getDataForScope(scope).totalPointsForChaos.update(dimension, (old) => old + points, ifAbsent: () => points);
      _getDataForScope(scope).highScoresForChaos.update(dimension, (old) => max(old, points), ifAbsent: () => points);
    }
  }

  clearAll() {
    Scope.values.forEach(_clearAll);
  }

  _clearAll(Scope scope) {
    _getDataForScope(scope).wonOrderGames.clear();
    _getDataForScope(scope).wonChaosGames.clear();
    _getDataForScope(scope).lostOrderGames.clear();
    _getDataForScope(scope).lostChaosGames.clear();
    _getDataForScope(scope).highScoresForOrder.clear();
    _getDataForScope(scope).highScoresForChaos.clear();
    _getDataForScope(scope).totalPointsForOrder.clear();
    _getDataForScope(scope).totalPointsForChaos.clear();
  }

}