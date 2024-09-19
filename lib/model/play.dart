import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_9/model/chip.dart';
import 'package:hyle_9/model/spot.dart';

import '../ui/game_ground.dart';
import '../utils.dart';
import 'ai/ai.dart';
import 'ai/strategy.dart';
import 'fortune.dart';
import 'matrix.dart';


class Stats extends ChangeNotifier {
  final _points = HashMap<Role, int>();
 
  Stats();

  Stats.fromJsonMap(Map<String, dynamic> map) {
 /*   Map<String, dynamic> cellsMap = map["cells"]!;
    _points.addAll(cellsMap.map((key, value) => MapEntry(CellType.fromId(key), value as int)));
*/
  }
  
  int getPoints(Role role) => _points[role] ?? 0;

  void setPoints(Role role, int points) {
    _points[role] = points;
  }


  incPoints(Role role) {
    _points[role] = getPoints(role) + 1;
    notifyListeners();
  }  
  
  decPoints(Role role) {
    final curr = getPoints(role);
    _points[role] = max(0, curr - 1);
    notifyListeners();
  }


  Map<String, dynamic> toJson() => {
   // 'cells' : _cells.map((key, value) => MapEntry(key.id, value)),
   // 'resources' : _resources.map((key, value) => MapEntry(key.id, value)),
   // 'ever' : _ever.map((key, value) => MapEntry(key.id, value)),
  };

  Role getWinner() {
    if (getPoints(Role.Order) > getPoints(Role.Chaos)) {
      return Role.Order;
    }
    return Role.Chaos;
  }

}

class StockEntry {
  GameChip chip;
  int amount;

  StockEntry(this.chip, this.amount);

  bool isEmpty() => amount == 0;
}

class Stock extends ChangeNotifier {
  final _available = HashMap<GameChip, int>();

  Stock(Map<GameChip, int> initialStock) {
    _available.addAll(initialStock);
  }

  Stock.fromJsonMap(Map<String, dynamic> map) {
 //   Map<String, dynamic> availableMap = map["available"]!;
 //   _available.addAll(availableMap.map((key, value) => MapEntry(CellType.fromId(key), value as int)));
  }

  Iterable<StockEntry> getStockEntries() => _available
      .entries
      .map((e) => StockEntry(e.key, e.value));

  int getStock(GameChip chip) => _available[chip] ?? 0;

  bool hasStock(GameChip chip) => getStock(chip) > 0;

  incStock(GameChip chip) {
    _available[chip] = getStock(chip) + 1;
    notifyListeners();
  }

  decStock(GameChip chip) {
    final curr = getStock(chip);
    _available[chip] = max(0, curr - 1);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'available' : _available.map((key, value) => MapEntry(key.id, value)),
  };

  GameChip? drawNext() {
    if (isEmpty()) {
      return null;
    }
    final nextChipIndex = diceInt(_available.length);
    final nextChip = _available.keys.indexed.firstWhere((e) => e.$1 == nextChipIndex).$2;
    final stockForChip = _available[nextChip]??0;
    if (stockForChip <= 0) {
      return drawNext();
    }
    return nextChip;
  }

  void putBack(GameChip chip) {
    final stockForChip = _available[chip]??0;
    _available[chip] = stockForChip + 1;
  }

  int getTotalStock() => _available.values.reduce((v, e) => v + e);

  bool isEmpty() {

    return getTotalStock() == 0;
  }

  int getChipTypes() => _available.length;


}

class Cursor extends ChangeNotifier {
  Coordinate? _startWhere;
  Coordinate? _where;
  final _possibleTargets = HashSet<Coordinate>();

  Cursor();

  Cursor.fromJsonMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? where = map["where"];
    if (where != null && where.isNotEmpty) {
      _where = Coordinate.fromJsonMap(where);
    }
  }

  Coordinate? get where => _where;
  Coordinate? get startWhere => _startWhere;
  HashSet<Coordinate> get possibleTargets => _possibleTargets;

  bool get hasCursor => where != null;
  bool get hasStartCursor => startWhere != null;

  update(Coordinate where) {
    _where = where;

    notifyListeners();
  }

  updateStart(Coordinate where) {
    _startWhere = where;

    notifyListeners();
  }

  clear({bool keepStart = false}) {
    if (!keepStart) {
      _startWhere = null;
      _possibleTargets.clear();
    }
    _where = null;

    notifyListeners();
  }


  @override
  String toString() {
    return 'Cursor{_startWhere: $_startWhere, _where: $_where, _possibleTargets: $_possibleTargets}';
  }

  Map<String, dynamic> toJson() => {
    'where' : _where, //currentPiece should loaded when deserialized
  };

  void detectPossibleTargetsFor(Coordinate where, Matrix matrix) {
    _possibleTargets.clear();
    
    _possibleTargets.addAll(
      matrix.getSpot(where).findFreeNeighborsInDirection(Direction.West).map((spot) => spot.where));
    _possibleTargets.addAll(
        matrix.getSpot(where).findFreeNeighborsInDirection(Direction.East).map((spot) => spot.where));
    _possibleTargets.addAll(
        matrix.getSpot(where).findFreeNeighborsInDirection(Direction.North).map((spot) => spot.where));
    _possibleTargets.addAll(
        matrix.getSpot(where).findFreeNeighborsInDirection(Direction.South).map((spot) => spot.where));
    debugPrint("pos:"+_possibleTargets.toString());
  }


}


class Play extends ChangeNotifier {

  int _currentRound = 1;
  Role _currentRole = Role.Chaos;

  late Stats _stats;
  late Stock _stock;
  late Cursor _cursor;
  late Cursor _opponentMove;
  late int _dimension;
  late Matrix _matrix;
  GameChip? _currentChip;
  late AiConfig _aiConfig;
  late Player _chaosPlayer;
  late Player _orderPlayer;
  ChaosAi? chaosAi;
  OrderAi? orderAi;

  Play(this._dimension, this._chaosPlayer, this._orderPlayer) {
    _stats = Stats();

    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      Color color;
      do {
        color = diceColor();
      } while (chips.keys.any((c) => isTooClose(c.color, color, 100)) || tooDark(color) || tooLight(color));

      final chip = GameChip(
          String.fromCharCode('a'.codeUnitAt(0) + i), color);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }


    _stock = Stock(chips);

    _matrix = Matrix(Coordinate(dimension, dimension), this);
    _cursor = Cursor();
    _opponentMove = Cursor();

    _stats.addListener(() => notifyListeners());
    _stock.addListener(() => notifyListeners());
    _cursor.addListener(() => notifyListeners());

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Color diceColor() {
    return Color.fromARGB(
        210,
        127.fuzzyIncrease(1, 128).fuzzyDecrease(1, 128),
        127.fuzzyIncrease(1, 128).fuzzyDecrease(1, 128),
        127.fuzzyIncrease(1, 128).fuzzyDecrease(1, 128),
        );
  }

  Play.fromJsonMap(Map<String, dynamic> map) {
    _chaosPlayer = Player.Ai;
    _orderPlayer = Player.User;
    _currentRound = map["currentGen"]??0;
   /* _ticks = map["ticks"]??0;
    _secondsPerTick = map["secondsPerTick"]??0;
    _paused = map["paused"]??false;
    _lifeTime = map["lifeTime"]??0;
    _lifeTimeAtLastTick = map["lifeTimeAtLastTick"]??0;

    originZoom = map["originZoom"];
    final originVisibleRectTop = map["originVisibleRect.top"];
    final originVisibleRectBottom = map["originVisibleRect.bottom"];
    final originVisibleRectLeft = map["originVisibleRect.left"];
    final originVisibleRectRight = map["originVisibleRect.right"];
    if (originVisibleRectTop != null && originVisibleRectBottom != null 
        && originVisibleRectLeft != null && originVisibleRectRight != null) {
      originVisibleRect = Rect.fromLTRB(
          originVisibleRectLeft, originVisibleRectTop,
          originVisibleRectRight, originVisibleRectBottom);
    }
    
    currentZoom = map["currentZoom"];
    final currentVisibleRectTop = map["currentVisibleRect.top"];
    final currentVisibleRectBottom = map["currentVisibleRect.bottom"];
    final currentVisibleRectLeft = map["currentVisibleRect.left"];
    final currentVisibleRectRight = map["currentVisibleRect.right"];
    if (currentVisibleRectTop != null && currentVisibleRectBottom != null 
        && currentVisibleRectLeft != null && currentVisibleRectRight != null) {
      currentVisibleRect = Rect.fromLTRB(
          currentVisibleRectLeft, currentVisibleRectTop,
          currentVisibleRectRight, currentVisibleRectBottom);
    }
*/
    _stats = Stats.fromJsonMap(map["stats"]!);
    _stock = Stock.fromJsonMap(map["stock"]!);

    _matrix = Matrix.fromJsonMap(map["matrix"]!, this);

    final Map<String, dynamic> cursorMap = map["cursor"];
    if (cursorMap.isNotEmpty) {
      _cursor = Cursor.fromJsonMap(cursorMap);
    }

    _currentChip = map["selectedCellTypeId"];

    _aiConfig = AiConfig.fromJsonMap(map["aiConfig"]);
    _initAis(useDefaultParams: false);
  }

  get currentRole => _currentRole;

  switchRole() {
    _currentRole = currentRole == Role.Chaos ? Role.Order : Role.Chaos;
  }

  void nextRound() {
    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

    if (currentRole == Role.Order) {
      // round is over
      nextChip();
      incRound();
    }
    switchRole();
    _cursor.clear();
    _opponentMove.clear();
  }

  Player get currentPlayer => _currentRole == Role.Chaos ? _chaosPlayer : _orderPlayer;
  
  Role finishGame() {
    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

    _currentRole = _stats.getWinner();
    _currentChip = null;
    _cursor.clear();

    return _currentRole;
  }

  void _initAis({required bool useDefaultParams}) {
    chaosAi = PureRandomChaosAi(_aiConfig, this);
    orderAi = AlwaysSkipAi(_aiConfig, this);
    /*spotAis = [
    ];

    matrixAis = [
      SprinkleResourcesAi(_aiConfig),
      SprinkleAlienCellsAi(_aiConfig),
    ];

    if (useDefaultParams) {
      spotAis.forEach((ai) => ai.defaultAiParams());
      matrixAis.forEach((ai) => ai.defaultAiParams());
    }*/
  }

  int get currentRound => _currentRound;
  Stats get stats => _stats;
  Stock get stock => _stock;
  int get dimension => _dimension;
  Matrix get matrix => _matrix;
  Cursor get cursor => _cursor;
  Cursor get opponentMove => _opponentMove;
  AiConfig get aiConfig => _aiConfig;

  GameChip? get currentChip => _currentChip;
  GameChip? nextChip() {
    _currentChip = _stock.drawNext();
    notifyListeners();
    return currentChip;
  }



  incRound() {
    _currentRound++;
    notifyListeners();
  }


  Map<String, dynamic> toJson() => {
    'currentRound' : _currentRound,


    'stats' : _stats,
    'stock' : _stock,
    'cursor' : _cursor,
    'matrix' : _matrix,
    'currentChip' : _currentChip,
    'aiConfig': _aiConfig
  };

  bool isGameOver() {
    return _stock.isEmpty();
  }

  Future<Move?> startThinking() {
    Move? move;
    if (_currentRole == Role.Chaos) {
      move = chaosAi?.think(this);
    }
    else if (_currentRole == Role.Order) {
      move = orderAi?.think(this);
    }
    final runAutomatic = _chaosPlayer != Player.User && _orderPlayer != Player.User;
    return Future.delayed(Duration(milliseconds: runAutomatic ? 0 : 500), () => move);
  }

}