import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/spot.dart';

import '../ui/game_ground.dart';
import '../utils.dart';
import 'ai/ai.dart';
import 'ai/strategy.dart';
import 'fortune.dart';
import 'matrix.dart';



class Move {
  GameChip? chip;
  Coordinate? from;
  Coordinate? to;
  bool skipped = false;

  Move({this.chip, this.from, this.to, required this.skipped});

  Move.placed(GameChip chip, Coordinate where): this(chip: chip, from: where, to: where, skipped: false);
  Move.moved(GameChip chip, Coordinate from, Coordinate to): this(chip: chip, from: from, to: to, skipped: false);
  Move.skipped(): this(skipped: true);

  bool isMove() => !skipped && from != to;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Move && runtimeType == other.runtimeType &&
              chip == other.chip && from == other.from && to == other.to &&
              skipped == other.skipped;

  @override
  int get hashCode =>
      chip.hashCode ^ from.hashCode ^ to.hashCode ^ skipped.hashCode;

  @override
  String toString() {
    if (skipped) {
      return "-";
    }
    if (isMove()) {
      return "${chip?.id}@$from->$to";
    }
    else {
      return "${chip?.id}@$from";
    }
  }

  bool isPlaced() => !isMove() && !skipped;

}

class Stats {
  final _points = HashMap<Role, int>();
 
  Stats();

  
  int getPoints(Role role) => _points[role] ?? 0;

  void _setPoints(Role role, int points) {
    _points[role] = points;
  }

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

class Stock {
  final _available = HashMap<GameChip, int>();

  Stock(Map<GameChip, int> initialStock) {
    _available.addAll(initialStock);
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

  decStock(GameChip chip) {
    final curr = getStock(chip);
    _available[chip] = max(0, curr - 1);
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

  GameChip? getChipOfMostStock() {
    final entries = getStockEntries().toList();
    entries.sort((e1, e2) => e2.amount.compareTo(e1.amount));
    return entries.firstOrNull?.chip;
  }


  int getTotalStock() => _available.values.reduce((v, e) => v + e);

  bool isEmpty() {

    return getTotalStock() == 0;
  }

  int getTotalChipTypes() => _available.length;



}

class Cursor {
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
  }

  updateStart(Coordinate where) {
    _startWhere = where;
  }

  clear({bool keepStart = false}) {
    if (!keepStart) {
      _startWhere = null;
      clearPossibleTargets();
    }
    _where = null;
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

  bool isHorizontalMove() => _startWhere != null && _where != null && _startWhere!.y == _where!.y;

  bool isVerticalMove() => _startWhere != null && _where != null && _startWhere!.x == _where!.x;

  void adaptFromMove(Move move) {
    clear();
    if (move.isMove()) {
      updateStart(move.from!);
      update(move.to!);
    }
    else if (!move.skipped) {
      update(move.from!);
    }
  }


}


class Play {

  int _currentRound = 1;
  Role _currentRole = Role.Chaos;

  late Stats _stats;
  late Stock _stock;
  late Cursor _cursor;
  late Cursor _opponentMove;
  late final int _dimension;
  late Matrix _matrix;
  GameChip? _currentChip;
  late AiConfig _aiConfig;
  late final Player _chaosPlayer;
  late final Player _orderPlayer;
  ChaosAi? chaosAi;
  OrderAi? orderAi;

  DateTime startDate = DateTime.timestamp();
  DateTime? endDate = null;
  String? name = null;
  List<Move> journal = [];

  Move? _staleMove = null;

  Play(this._dimension, this._chaosPlayer, this._orderPlayer) {
    _stats = Stats();

    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      final color = getColorFromIdx(i);

      final chip = GameChip(
          String.fromCharCode('a'.codeUnitAt(0) + i), color);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }


    _stock = Stock(chips);

    _matrix = Matrix(Coordinate(dimension, dimension));
    _cursor = Cursor();
    _opponentMove = Cursor();

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  double get progress => currentRound / maxRounds;
  int get maxRounds => dimension * dimension;

  Role get currentRole => _currentRole;

  switchRole() {
    _currentRole = currentRole == Role.Chaos ? Role.Order : Role.Chaos;
  }

  applyMove(Move move) {
    if (move.isMove()) {
      _matrix.move(move.from!, move.to!);
    }
    else if (!move.skipped) {
      _matrix.put(move.from!, move.chip!, _stock);
    }
    debugPrint("add move to journal: $move");
    _staleMove = move;
    journal.add(move);

    _stats._setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats._setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

  }

  Move? undoLastMove() {
    final lastMove = journal.lastOrNull;
    debugPrint("last move: $lastMove");
    if (lastMove != null) {
      if (lastMove.isMove()) {
        _matrix.move(lastMove.to!, lastMove.from!);
      }
      else if (!lastMove.skipped) {
        _matrix.remove(lastMove.from!, _stock);
      }

      if (_staleMove == lastMove) {
        _staleMove = null;
      }

      _stats._setPoints(Role.Order, _matrix.getTotalPointsForOrder());
      _stats._setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

      return journal.removeLast();
    }
    return null;
  }

  bool get isDirty => _staleMove != null;
  Move? get currentMove => _staleMove;

  void nextRound(bool clearOpponentCursor) {

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

    _staleMove = null;
  }

  void previousRound() {
    final lastMove = undoLastMove();
    if (lastMove != null) {
      _currentChip = lastMove.chip;

      switchRole();

      if (currentRole == Role.Order) {
        // undo round is over
        decRound();
      }
      _cursor.clear();
      _opponentMove.clear();
    }
  }

  Player get currentPlayer => _currentRole == Role.Chaos ? _chaosPlayer : _orderPlayer;

  bool get isMultiplayerPlay => _chaosPlayer == Player.RemoteUser || _orderPlayer == Player.RemoteUser;

  bool get isFullAutomaticPlay => _chaosPlayer == Player.Ai && _orderPlayer == Player.Ai;

  Role finishGame() {

    _currentRole = _stats.getWinner();
    _currentChip = null;
    _cursor.clear();

    return _currentRole;
  }

  void _initAis({required bool useDefaultParams}) {
    chaosAi = DefaultChaosAi(_aiConfig, this);
    orderAi = DefaultOrderAi(_aiConfig, this);
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
    return currentChip;
  }



  incRound() {
    _currentRound++;
  }

  decRound() {
    _currentRound--;
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

  startThinking(
      Function(Load) aiProgressListener,
      Function(Move) nextMoveHandler,
      Function(SendPort) aiControlHandlerReceived) async {

    final resultPort = ReceivePort();
    resultPort.listen((message) {

      if (message is Move) {
        nextMoveHandler(message);

        // close this stream
        resultPort.close();
      }
      else if (message is Load) {
        aiProgressListener(message);
      }
      else if (message is SendPort) {
        aiControlHandlerReceived(message);
      }
    });
    debugPrint("Spawn main");
    final sendPort = resultPort.sendPort;
    Isolate.spawn(_startThinking, [sendPort, this]);
    debugPrint("End spawn main");
  }



  void _startThinking(List<dynamic> args) {
    SendPort sendPort = args[0];
    Play play = args[1];

    final controlPort = ReceivePort();
    sendPort.send(controlPort.sendPort);

    controlPort.listen((message) {
      if (message == 'KILL') {
        debugPrint("Killing AI...");
        Isolate.current.kill(priority:  Isolate.immediate);
      }
    });

    final start = DateTime.now().millisecondsSinceEpoch;
    if (play.currentRole == Role.Chaos) {
      play.chaosAi!.think(play, (load) => sendPort.send(load)).then((move) {
        sendPort.send(move);
        final time = DateTime.now().millisecondsSinceEpoch - start;
        debugPrint("Time to predict next Chaos move: $time ms");
      });
    }
    else { // _currentRole == Role.Order
      play.orderAi!.think(play, (load) => sendPort.send(load)).then((move) {
        sendPort.send(move);
        final time = DateTime.now().millisecondsSinceEpoch - start;
        debugPrint("Time to predict next Order move: $time ms");
      });
    }


  }

}