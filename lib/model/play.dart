import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/stats.dart';
import 'package:hyle_x/model/stock.dart';
import 'package:hyle_x/service/BitsService.dart';
import 'package:json_annotation/json_annotation.dart';

import '../engine/ai/ai.dart';
import '../engine/ai/strategy.dart';
import '../ui/game_ground.dart';
import 'coordinate.dart';
import 'cursor.dart';
import 'fortune.dart';
import 'matrix.dart';
import 'move.dart';


enum PlayState {

  // Initial state
  Initialised,

  // only if multiPlay == true and current == inviting player, if an invitation has been sent out
  RemoteOpponentInvited,

  // only if multiPlay == true, when an invitation has been accepted by invited player
  InvitationAccepted,

  // only if multiPlay == true, when an invitation has been rejected by invited player
  InvitationRejected, // final state

  // Play is going on
  Ongoing,

  // current player lost. If both players on a single play are human, this is not used
  Lost, // final state

  // current player won. If both players on a single play are human, this is not used
  Won, // final state

  // current player resigned (and the remote opponent won therefore). If both players on a single play are human, this is not used
  Resigned, // final state

  // used if both players on a single play are human or any other final state like no invitation response etc..
  Closed, // final state
}


/**
 * This is a pre-object of Play is there is an ongoing invitation process.
 */
@JsonSerializable()
class PlayRequest {

  late String playId;

  CommunicationContext commContext = CommunicationContext();

  PlaySize playSize;
  PlayMode playMode;
  PlayOpener playOpener;
  String name;
  PlayState state;

  PlayRequest(this.playSize, this.playMode, this.playOpener, this.name, this.state) {
    playId = generateRandomString(8);
  }
}

@JsonSerializable()
class Play {

  late String id;

  bool multiPlay = false;
  PlayState state = PlayState.Initialised;
  CommunicationContext _commContext = CommunicationContext();
  
  late int _currentRound;
  late Role _currentRole;
  GameChip? _currentChip;

  late Stats _stats;
  late Stock _stock;
  late Cursor _selectionCursor;
  late Cursor _opponentCursor;
  late final int _dimension;
  late Matrix _matrix;
  late AiConfig _aiConfig;
  late final PlayerType _chaosPlayer;
  late final PlayerType _orderPlayer;
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

  Play.fromRequest(this._dimension, this._chaosPlayer, this._orderPlayer, PlayRequest playRequest) {
    id = playRequest.playId;
    name = playRequest.name;
    state = playRequest.state;
    commContext.previousSignature = playRequest.commContext.previousSignature;
    multiPlay = true;
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
    _selectionCursor = Cursor();
    _opponentCursor = Cursor();
    
    _aiConfig = AiConfig();
    _initAis(useDefaultParams: true);
  }

  Play.fromJson(Map<String, dynamic> map) {

    id = map['id'];
    multiPlay = map['multiPlay'];
    state = PlayState.values.firstWhere((p) => p.name == map['state']);

    final previousSignature = map['previousSignature'];
    _commContext.previousSignature = previousSignature;

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
    _selectionCursor = Cursor.fromJson(map['selectionCursor']);

    _opponentCursor = Cursor.fromJson(map['opponentCursor']);

    _chaosPlayer = PlayerType.values.firstWhere((p) => p.name == map['chaosPlayer']);
    _orderPlayer = PlayerType.values.firstWhere((p) => p.name == map['orderPlayer']);

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

  PlayerType get chaosPlayer => _chaosPlayer;

  PlayerType get orderPlayer => _orderPlayer;

  PlayerType getWinnerPlayer() {
    final winner = _stats.getWinner();
    if (winner == Role.Order) {
      return _orderPlayer;
    }
    return _chaosPlayer;
  }

  Map<String, dynamic> toJson() => {
    "id" : id,
    "state" : state.name,
    "multiPlay" : multiPlay,
    "previousSignature" : _commContext.previousSignature,
    "dimension" : _dimension,
    "currentRound" : _currentRound,
    "currentRole" : _currentRole.name,
    if (_currentChip != null) "currentChip" : _currentChip!.toKey(),
    "matrix" : _matrix.toJson(),
    "stats" : _stats.toJson(),
    "stock" : _stock.toJson(),
    "selectionCursor" : _selectionCursor.toJson(),
    "opponentCursor" : _opponentCursor.toJson(),
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

  void nextPlayer() {

    switchRole();
    if (currentRole == Role.Chaos) {
      // transition from Order to Chaos

      nextChip();
      incRound();
    }

    _selectionCursor.clear();
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
      _selectionCursor.clear();
      _opponentCursor.clear();

      return lastMove;
    }
    return null;
  }

  PlayerType get currentPlayer => _currentRole == Role.Chaos ? _chaosPlayer : _orderPlayer;

  bool get isMultiplayerPlay => _chaosPlayer == PlayerType.RemoteUser || _orderPlayer == PlayerType.RemoteUser;

  bool get isBothSidesSinglePlay => _chaosPlayer == PlayerType.User && _orderPlayer == PlayerType.User;

  bool get isFullAutomaticPlay => _chaosPlayer == PlayerType.Ai && _orderPlayer == PlayerType.Ai;

  Role finishGame() {

    _currentRole = _stats.getWinner();
    _currentChip = null;
    _selectionCursor.clear();

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
  Cursor get selectionCursor => _selectionCursor;
  Cursor get opponentCursor => _opponentCursor;
  AiConfig get aiConfig => _aiConfig;

  GameChip? get currentChip => _currentChip;
  CommunicationContext get commContext => _commContext;

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


  String getReadablePlayId() {
    return toReadableId(id);
  }



}