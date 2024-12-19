import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/stats.dart';
import 'package:hyle_x/model/stock.dart';
import 'package:json_annotation/json_annotation.dart';

import '../ui/game_ground.dart';
import 'ai/ai.dart';
import 'ai/strategy.dart';
import 'coordinate.dart';
import 'cursor.dart';
import 'fortune.dart';
import 'matrix.dart';
import 'move.dart';



@JsonSerializable()
class Play {

  late String id;
  late int _currentRound;
  late Role _currentRole;

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
    id = generateRandomString(8);
    _init();
  }

  // initialises the play to get started
  void _init() {

    _currentRound = 1;
    _currentRole = Role.Chaos;

    _journal.clear();

    _stats = Stats();
    
    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      final chip = GameChip(i);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }
    
    
    _stock = Stock(chips);
    nextChip();

    _matrix = Matrix(Coordinate(dimension, dimension));
    _cursor = Cursor();
    _opponentMove = Cursor();
    
    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Play.fromJson(Map<String, dynamic> map) {

    id = map['id'];
    _dimension = map['dimension'];
    _currentRound = map['currentRound'];
    _currentRole = Role.values.firstWhere((p) => p.name == map['currentRole']);
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

    startDate = DateTime.parse(map['startDate']);
    final endDateKey = map['endDate'];
    if (endDateKey != null) {
      endDate = DateTime.parse(endDateKey);
    }

    final staleMoveKey = map['staleMove'];
    if (staleMoveKey != null) {
      _staleMove = Move.fromJson(staleMoveKey);
    }

    final List<dynamic> journalList = map['journal']!;
    _journal.addAll(journalList.map((value) {
      return Move.fromJson(value);
    }));

    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Player get chaosPlayer => _chaosPlayer;

  Player get orderPlayer => _orderPlayer;

  Player getWinnerPlayer() {
    final winner = _stats.getWinner();
    if (winner == Role.Order) {
      return _orderPlayer;
    }
    return _chaosPlayer;
  }

  Map<String, dynamic> toJson() => {
    "id" : id,
    "dimension" : _dimension,
    "currentRound" : _currentRound,
    "currentRole" : _currentRole.name,
    if (_currentChip != null) "currentChip" : _currentChip!.toKey(),
    "matrix" : _matrix.toJson(),
    "stats" : _stats.toJson(),
    "stock" : _stock.toJson(),
    "cursor" : _cursor.toJson(),
    "opponentMove" : _opponentMove.toJson(),
    "chaosPlayer" : _chaosPlayer.name,
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
  List<Move> get journal => _journal.toList(growable: false);

  bool get isJournalEmpty => _journal.isEmpty;


  applyStaleMove(Move move) {
    if (move.isMove()) {
      _matrix.move(move.from!, move.to!);
    }
    else if (!move.skipped) {
      _matrix.put(move.from!, move.chip!, _stock);
    }
    _staleMove = move;
    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());

  }

  commitMove() {
    if (_staleMove != null) {
      debugPrint("add move to journal: $_staleMove");
      _journal.add(_staleMove!);
    }
    _staleMove = null;
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

    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos());
    }

  bool get hasStaleMove => _staleMove != null;
  
  Move? get staleMove => _staleMove;
  
  Move? get currentMove => _staleMove;

  int getPointsPerChip() => _matrix.getPointsPerChip(_dimension);

  void nextRound(bool clearOpponentCursor) {

    switchRole();
    if (currentRole == Role.Chaos) {
      // transition from Order to Chaos

      nextChip();
      incRound();
    }

    _cursor.clear();
    if (clearOpponentCursor) {
      _opponentMove.clear();
    }
  }

  Move? previousRound() {
    final lastMove = rollbackLastMove();
    if (lastMove != null) {
      _undoMove(lastMove);

      _currentChip = lastMove.chip;

      switchRole();

      if (currentRole == Role.Order) {
        // transition from Chaos back to Order
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

  bool get isBothSidesSinglePlay => _chaosPlayer == Player.User && _orderPlayer == Player.User;

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
    return !hasStaleMove && (_stock.isEmpty() || _matrix.noFreeSpace());
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

  void reset() {
    _init();
  }


}