import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/spot.dart';
import 'package:json_annotation/json_annotation.dart';

import '../ui/game_ground.dart';
import '../utils.dart';
import 'ai/ai.dart';
import 'ai/strategy.dart';
import 'fortune.dart';
import 'matrix.dart';


enum Role {Chaos, Order}

class Move {
  GameChip? chip;
  Coordinate? from;
  Coordinate? to;
  bool skipped = false;

  Move({this.chip, this.from, this.to, required this.skipped});

  Move.fromJson(Map<String, dynamic> map) {
    final chipKey = map['chip'];
    if (chipKey != null) {
      chip = GameChip.fromKey(chipKey);
    }

    final fromKey = map['from'];
    if (fromKey != null) {
      from = Coordinate.fromKey(fromKey);
    }

    final toKey = map['to'];
    if (toKey != null) {
      to = Coordinate.fromKey(toKey);
    }


    skipped = map['skipped'] as bool;
  }

  Map<String, dynamic> toJson() => {
    if (chip != null) 'chip' : chip!.toKey(),
    if (from != null) 'from' : from!.toKey(),
    if (to != null) 'to' : to!.toKey(),
    'skipped' : skipped
  };

  Move.placed(GameChip chip, Coordinate where): this(chip: chip, from: where, to: where, skipped: false);
  Move.moved(GameChip chip, Coordinate from, Coordinate to): this(chip: chip, from: from, to: to, skipped: false);
  Move.skipped(): this(skipped: true);

  bool isMove() => !skipped && from != to && from != null && to != null;

  Role getRole() {
    if (isPlaced()) {
      return Role.Chaos;
    }
    else {
      return Role.Order;
    }
  }

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
      return "${chip?.name}@$from->$to";
    }
    else {
      return "${chip?.name}@$from";
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

  Stats.fromJson(Map<String, dynamic> map) {

    final Map<String, dynamic> pointsMap = map['points']!;
    _points.addAll(pointsMap.map((key, value) {
      final role = Role.values.firstWhere((r) => r.name == key);
      return MapEntry(role, value);
    }));
  }

  Map<String, dynamic> toJson() => {
    'points' : _points.map((key, value) => MapEntry(key.name, value)),
  };

  
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

  Stock.fromJson(Map<String, dynamic> map) {

    final Map<String, dynamic> stockMap = map['available']!;
    _available.addAll(stockMap.map((key, value) {
      final chip = GameChip.fromKey(key);
      return MapEntry(chip, value);
    }));
  }

  Map<String, dynamic> toJson() => {
    'available' : _available.map((key, value) => MapEntry(key.toKey(), value)),
  };


  Iterable<StockEntry> getStockEntries() {
    final entries = _available
      .entries
      .map((e) => StockEntry(e.key, e.value))
      .toList();
    
    entries.sort((e1, e2) => e1.chip.name.compareTo(e2.chip.name));
    return entries;
  }

  int getStock(GameChip chip) => _available[chip] ?? 0;

  bool hasStock(GameChip chip) => getStock(chip) > 0;

  decStock(GameChip chip) {
    final curr = getStock(chip);
    _available[chip] = max(0, curr - 1);
  }


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

  Cursor.fromJson(Map<String, dynamic> map) {

    final startKey = map['start'];
    if (startKey != null) {
      _start = Coordinate.fromKey(startKey);
    }

    final endKey = map['end'];
    if (endKey != null) {
      _end = Coordinate.fromKey(endKey);
    }

    final Set<String> targetSet = map['possibleTargets']!;
    _possibleTargets.addAll(targetSet.map((value) {
      return Coordinate.fromKey(value);
    }));

    temporary = map['temporary'] as bool;
  }

  Map<String, dynamic> toJson() => {
    if (start != null) 'start' : _start!.toKey(),
    if (end != null) 'end' : end!.toKey(),
    'possibleTargets' : _possibleTargets.map((value) => value.toKey()).toList(),
    "temporary": temporary
  };


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


@JsonSerializable()
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
  DateTime? endDate;
  String? name;
  final List<Move> _journal = [];

  Move? _staleMove;

  Play(this._dimension, this._chaosPlayer, this._orderPlayer) {

    _stats = Stats();

    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      final color = getColorFromIdx(i);

      final chip = GameChip(i);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }


    _stock = Stock(chips);

    _matrix = Matrix(Coordinate(dimension, dimension));
    _cursor = Cursor();
    _opponentMove = Cursor();

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Play.fromJson(Map<String, dynamic> map) {

    _dimension = map['dimension'];
    _currentRound = map['currentRound'];
    _currentRole = map['currentRole'];
    final startKey = map['currentChip'];
    if (startKey != null) {
      _currentChip = GameChip.fromKey(startKey);
    }
    _matrix = Matrix.fromJson(map['matrix']);
    _stats = Stats.fromJson(map['stats']);
    _stock = Stock.fromJson(map['stock']);
    _cursor = Cursor.fromJson(map['cursor']);
    _opponentMove = Cursor.fromJson(map['opponentMove']);
    _chaosPlayer = Player.values.firstWhere((p) => p.name == map['chaosPlayer']);
    _orderPlayer = Player.values.firstWhere((p) => p.name == map['orderPlayer']);

    startDate = map['startDate'];
    final endDateKey = map['endDate'];
    if (endDateKey != null) {
      endDate = endDateKey;
    }

    final staleMoveKey = map['staleMove'];
    if (staleMoveKey != null) {
      _staleMove = Move.fromJson(staleMoveKey);
    }

    final List<Map<String,dynamic>> journalList = map['journal']!;
    _journal.addAll(journalList.map((value) {
      return Move.fromJson(value);
    }));

  }

  Map<String, dynamic> toJson() => {
    "dimension" : _dimension,
    "currentRound" : _currentRound,
    "currentRole" : _currentRole.name,
    if (_currentChip != null) "currentChip" : _currentChip!.toKey(),
    "matrix" : _matrix.toJson(),
    "stats" : _stats.toJson(),
    "stock" : _stock.toJson(),
    "cursor" : _cursor.toJson(),
    "opponentCursor" : _opponentMove.toJson(),
    "chaosPlay" : _chaosPlayer.name,
    "orderPlayer" : _orderPlayer.name,
    "startDate" : startDate.toIso8601String(),
    if (endDate != null) "endDate" : endDate!.toIso8601String(),
    if (name != null) "name" : name,
    if (_staleMove != null) "staleMove" : _staleMove!.toJson(),
    'journal' : _journal.map((j) => j.toJson()).toList(),
  };



  double get progress => currentRound / maxRounds;
  int get maxRounds => dimension * dimension;

  Role get currentRole => _currentRole;

  Role get opponentRole => currentRole == Role.Chaos ? Role.Order : Role.Chaos;

  switchRole() {
    _currentRole = opponentRole;
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