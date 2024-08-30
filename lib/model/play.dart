import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hyle_9/model/chip.dart';

import 'ai/ai.dart';
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
}

class StockEntry {
  GameChip type;
  int amount;

  StockEntry(this.type, this.amount);

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

  int getStock(GameChip type) => _available[type] ?? 0;

  bool hasStock(GameChip type) => getStock(type) > 0;

  incStock(GameChip type) {
    _available[type] = getStock(type) + 1;
    notifyListeners();
  }

  decStock(GameChip type) {
    final curr = getStock(type);
    _available[type] = max(0, curr - 1);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'available' : _available.map((key, value) => MapEntry(key.value, value)),
  };

  GameChip? drawNext() {
    //TODO implement random next
    return GameChip(diceInt(7) + 1, Color.fromARGB(200, 200.fuzzyIncrease(1, 50), 200.fuzzyDecrease(1, 150), 0.fuzzyIncrease(1, 250)));
  }

}

class Cursor extends ChangeNotifier {
  final Matrix _matrix;
  Coordinate? _previousWhere;
  Coordinate? _where;
  GameChip? _currentChip;

  Cursor(this._matrix);

  Cursor.fromJsonMap(Map<String, dynamic> map, this._matrix) {
    final Map<String, dynamic>? where = map["where"];
    if (where != null && where.isNotEmpty) {
      _where = Coordinate.fromJsonMap(where);
      _currentChip = _matrix.get(_where!);
    }
  }

  GameChip? get currentChip => _currentChip;
  Coordinate? get where => _where;

  update(Coordinate where) {
    _where = where;
    _currentChip = _matrix.get(where);

    notifyListeners();
  }

  void refresh() {
    if (_where != null) {
      _currentChip = _matrix.get(_where!);
    }
  }

  clear({bool keepForLater = false}) {
    if (keepForLater) {
      _previousWhere = _where;
    }
    
    _where = null;
    _currentChip = null;

    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'where' : _where, //currentPiece should loaded when deserialized
  };

  void recoverPrevious() {
    if (_previousWhere != null) {
      update(_previousWhere!);
      _previousWhere = null;
    }
  }

}


class Play extends ChangeNotifier {


  int dimension = 11;
  int _currentRound = 0;
  Role _currentRole = Role.Chaos;

  late Stats _stats;
  late Stock _stock;
  late Cursor _cursor;
  late Matrix _matrix;
  GameChip? _currentChip;
  late AiConfig _aiConfig;
  late List<PlayAi> matrixAis;
  late List<SpotAi> spotAis;

  Play() {
    _stats = Stats();
    _stock = Stock({
      GameChip(1, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(2, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(3, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(4, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(5, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(6, Color.fromARGB(255, 203, 0, 16)): 7,
      GameChip(7, Color.fromARGB(255, 203, 0, 16)): 7,

    });

    _matrix = Matrix(Coordinate(dimension, dimension), this);
    _cursor = Cursor(_matrix);

    _stats.addListener(() => notifyListeners());
    _stock.addListener(() => notifyListeners());
    _cursor.addListener(() => notifyListeners());

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Play.fromJsonMap(Map<String, dynamic> map) {
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
      _cursor = Cursor.fromJsonMap(cursorMap, _matrix);
    }

    _currentChip = map["selectedCellTypeId"];

    _aiConfig = AiConfig.fromJsonMap(map["aiConfig"]);
    _initAis(useDefaultParams: false);
  }

  get currentRole => _currentRole;

  switchRole() {
    _currentRole = currentRole == Role.Chaos ? Role.Order : Role.Chaos;
  }

  void _initAis({required bool useDefaultParams}) {
    spotAis = [
    ];

    matrixAis = [
      SprinkleResourcesAi(_aiConfig),
      SprinkleAlienCellsAi(_aiConfig),
    ];

    if (useDefaultParams) {
      spotAis.forEach((ai) => ai.defaultAiParams());
      matrixAis.forEach((ai) => ai.defaultAiParams());
    }
  }

  int get currentRound => _currentRound;
  Stats get stats => _stats;
  Stock get stock => _stock;
  Matrix get matrix => _matrix;
  Cursor get cursor => _cursor;
  AiConfig get aiConfig => _aiConfig;

  GameChip? get currentChip => _currentChip;
  GameChip? nextChip() {
    _currentChip = _stock.drawNext();
    notifyListeners();
    return currentChip;
  }



  incRound() {
    _currentRound++;
    _cursor.refresh();
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


}