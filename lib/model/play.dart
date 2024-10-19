import 'dart:collection';
import 'dart:isolate';
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

  Iterable<StockEntry> getStockEntries() {
    final entries = _available
      .entries
      .map((e) => StockEntry(e.key, e.value))
      .toList();
    
    entries.sort((e1, e2) => e1.chip.id.compareTo(e2.chip.id));
    return entries;
  }

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
      clearPossibleTargets();
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

  void clearPossibleTargets() {
    _possibleTargets.clear();
  }


  void detectPossibleTargetsFor(Coordinate where, Matrix matrix) {
    clearPossibleTargets();

    _possibleTargets.addAll(matrix.getPossibleTargetsFor(where).map((spot) => spot.where));
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
      final color = diceColor(i);

      final chip = GameChip(
          String.fromCharCode('a'.codeUnitAt(0) + i), color);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }


    _stock = Stock(chips);

    _matrix = Matrix(Coordinate(dimension, dimension));
    _cursor = Cursor();
    _opponentMove = Cursor();

    _stats.addListener(() => notifyListeners());
    _stock.addListener(() => notifyListeners());
    _cursor.addListener(() => notifyListeners());

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Color diceColor(int i) {
    /**
     *    rgb
     *  0 x
     *  1 xx
     *  2  x
     *  3  xx
     *  4   x
     *  5 x x
     *  6 xxx
     *  7 y
     *  8 yy
     *  9  y
     * 10  yy
     * 11   y
     * 12 y y
     */

    int r,g,b;
    if (i > 6) {
      r = 40.fuzzyTo(50);
      g = 40.fuzzyTo(50);
      b = 40.fuzzyTo(50);
    }
    else {
      r = 5.fuzzyTo(15);
      g = 5.fuzzyTo(15);
      b = 5.fuzzyTo(15);
    }

    if (i == 0 || i == 1 || i == 5 || i == 6) {
      r = 200.fuzzyTo(220);
    }
    if (i == 1 || i == 2 || i == 3 || i == 6) {
      g = 200.fuzzyTo(220);
    }
    if (i == 3 || i == 4 || i == 5 || i == 6) {
      b = 200.fuzzyTo(220);
    }

    if (i == 7 || i == 8 || i == 12) {
      r = 140.fuzzyTo(150);
    }
    if (i == 8 || i == 9 || i == 10) {
      g = 140.fuzzyTo(150);
    }
    if (i == 10 || i == 11 || i == 12) {
      b = 140.fuzzyTo(150);
    }

    return Color.fromARGB(
        210, r, g, b);
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

    _matrix = Matrix.fromJsonMap(map["matrix"]!);

    final Map<String, dynamic> cursorMap = map["cursor"];
    if (cursorMap.isNotEmpty) {
      _cursor = Cursor.fromJsonMap(cursorMap);
    }

    _currentChip = map["selectedCellTypeId"];

    _aiConfig = AiConfig.fromJsonMap(map["aiConfig"]);
    _initAis(useDefaultParams: false);
  }

  Role get currentRole => _currentRole;

  switchRole() {
    _currentRole = currentRole == Role.Chaos ? Role.Order : Role.Chaos;
  }

  void nextRound(bool clearOpponentCursor) {
    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

    if (currentRole == Role.Order) {
      // round is over
      nextChip();
      incRound();
    }
    switchRole();
    _cursor.clear();
    if (clearOpponentCursor) {
      _opponentMove.clear();
    }
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
    chaosAi = DefaultChaosAi(_aiConfig, this, _loadChangeListener);
    orderAi = DefaultOrderAi(_aiConfig, this, _loadChangeListener);
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
    return _stock.isEmpty() || _matrix.noFreeSpace();
  }

  Future<Move> startThinking() async {

    return await Isolate.run<Move>(() async {
      final start = DateTime.now().millisecondsSinceEpoch;
      Move move;
      if (_currentRole == Role.Chaos) {
        move = await chaosAi!.think(this);
      }
      else { // _currentRole == Role.Order
        move = await orderAi!.think(this);
      }
      final time = DateTime.now().millisecondsSinceEpoch - start;
      debugPrint("Time to predict next move: $time ms");
      final runAutomatic = _chaosPlayer != Player.User && _orderPlayer != Player.User;
      final future = Future<Move>.value(move);
      if (runAutomatic) {
        return Future.delayed(const Duration(milliseconds: 500), () => future);
      }
      else {
        return future;
      }
    });
  }


  _loadChangeListener(Load load) {
    if (load.curr % 5000 == 0) debugPrint("intermediate load: $load, ${identityHashCode(load)}");
  }
}