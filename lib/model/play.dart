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

  bool isMove() => !skipped && from != to && from != null && to != null;


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

  Cursor toCursor() {
    final cursor = Cursor();
    if (from != null) {
      cursor.updateStart(from!);
    }
    if (to != null) {
      cursor.updateEnd(to!);
    }
    return cursor;
  }

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
  Coordinate? _start;
  Coordinate? _end;
  final _possibleTargets = HashSet<Coordinate>();

  bool temporary = false;

  Cursor();


  Coordinate? get end => _end;
  Coordinate? get start => _start;
  HashSet<Coordinate> get possibleTargets => _possibleTargets;

  bool get hasEnd => end != null;
  bool get hasStart => start != null;

  updateEnd(Coordinate where) {
    _end = where;
  }

  updateStart(Coordinate where) {
    _start = where;
  }

  clear({bool keepStart = false}) {
    if (!keepStart) {
      _start = null;
      clearPossibleTargets();
    }
    _end = null;
    temporary = false;
  }


  @override
  String toString() {
    return 'Cursor{_startWhere: $_start, _where: $_end, _possibleTargets: $_possibleTargets}';
  }

  Map<String, dynamic> toJson() => {
    'where' : _end, //currentPiece should loaded when deserialized
  };

  void clearPossibleTargets() {
    _possibleTargets.clear();
  }


  void detectPossibleTargetsFor(Coordinate where, Matrix matrix) {
    clearPossibleTargets();

    _possibleTargets.addAll(matrix.getPossibleTargetsFor(where).map((spot) => spot.where));
  }

  bool isHorizontalMove() => _start != null && _end != null && _start!.y == _end!.y;

  bool isVerticalMove() => _start != null && _end != null && _start!.x == _end!.x;

  void adaptFromMove(Move move) {
    clear();
    if (move.isMove()) {
      updateStart(move.from!);
      updateEnd(move.to!);
    }
    else if (!move.skipped) {
      updateEnd(move.from!);
    }
  }

  bool contains(Coordinate where) => _start == where || _end == where;


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
  List<Move> _journal = [];

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

  Move? get lastMoveFromJournal => _journal.lastOrNull;

  bool get isJournalEmpty => _journal.isEmpty;


  applyStaleMove(Move move) {
    if (move.isMove()) {
      _matrix.move(move.from!, move.to!);
    }
    else if (!move.skipped) {
      _matrix.put(move.from!, move.chip!, _stock);
    }
    debugPrint("add move to journal: $move");
    _staleMove = move;

    _stats._setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats._setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

  }

  commitMove() {
    if (_staleMove != null) {
      _journal.add(_staleMove!);
    }
  }

  Move? rollbackLastMove() {
    if (!isJournalEmpty) {
      return _journal.removeLast();
    }
    else {
      return null;
    }
  }

  undoStaleMove() {
    if (_staleMove != null) {
      _undoMove(_staleMove!);
    }
  }
  _undoMove(Move move) {
    debugPrint("undo move: $move");
    if (move.isMove()) {
      _matrix.move(move.to!, move.from!);
    }
    else if (!move.skipped) {
      _matrix.remove(move.from!, _stock);
    }

    if (_staleMove == move) {
      _staleMove = null;
    }

    _stats._setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats._setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());
    }

  bool get hasStaleMove => _staleMove != null;
  
  Move? get staleMove => _staleMove;
  
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

  Move? previousRound() {
    final lastMove = rollbackLastMove();
    if (lastMove != null) {
      _undoMove(lastMove);

      _currentChip = lastMove.chip;

      switchRole();

      if (currentRole == Role.Order) {
        // undo round is over
        decRound();
      }
      _cursor.clear();
      _opponentMove.clear();

      return lastMove;
    }
    return null;
  }

  Player get currentPlayer => _currentRole == Role.Chaos ? _chaosPlayer : _orderPlayer;

  bool get isMultiplayerPlay => _chaosPlayer == Player.RemoteUser || _orderPlayer == Player.RemoteUser;

  bool get isBothSidesSinglePlay => _chaosPlayer == Player.User || _orderPlayer == Player.User;

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