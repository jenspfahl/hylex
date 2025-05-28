import 'dart:collection';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/stats.dart';
import 'package:hyle_x/model/stock.dart';
import 'package:json_annotation/json_annotation.dart';

import '../engine/ai/ai.dart';
import '../engine/ai/strategy.dart';
import '../ui/ui_utils.dart';
import 'common.dart';
import 'coordinate.dart';
import 'cursor.dart';
import '../utils/fortune.dart';
import 'matrix.dart';
import 'messaging.dart';
import 'move.dart';

enum PlayState {

  // Initial state
  Initialised,

  // only if multiPlay == true and current == inviting player, if an invitation has been sent out
  RemoteOpponentInvited,

  // only if multiPlay == true, when an invitation has been received but not replied
  InvitationPending,

  // only if multiPlay == true, when an invitation has been accepted by invited player
  InvitationAccepted,

  // only if multiPlay == true, when an invitation has been rejected by invited player
  InvitationRejected, // final state

  // Current player can move
  ReadyToMove,

  // Current play is waiting for remote opponent to move (either RemoteUser or Ai)
  WaitForOpponent,

  // current player lost. If both players on a single play are human, this is not used
  Lost, // final state

  // current player won. If both players on a single play are human, this is not used
  Won, // final state

  // current player resigned (and the remote opponent won therefore). If both players on a single play are human, this is not used
  Resigned, // final state

  // opponent player resigned (and the current opponent won therefore). If both players on a single play are human, this is not used
  OpponentResigned, // final state

  // used if both players on a single play are human or any other final state like no invitation response etc..
  Closed, // final state
}

/**
 * This contains header information of each play.
 */
@JsonSerializable()
class PlayHeader {

  late String playId;
  
  late PlaySize playSize;
  PlayMode playMode = PlayMode.HyleX;
  PlayState state = PlayState.Initialised;
  int currentRound = 0;

  // multi player attributes
  Initiator? initiator;
  PlayOpener? playOpener;
  CommunicationContext commContext = CommunicationContext();
  String? opponentId;
  String? opponentName;
  

  PlayHeader.singlePlay(
      this.playSize) {
    playId = generateRandomString(playIdLength);
  }
  
  PlayHeader.multiPlayInvitor(
      this.playSize, 
      this.playMode, 
      this.playOpener, 
      this.state) {
    playId = generateRandomString(playIdLength);
    initiator = Initiator.LocalUser;
  }  
  
  PlayHeader.multiPlayInvited(
      InviteMessage inviteMessage,
      this.state) {
    playId = inviteMessage.playId;
    initiator = Initiator.RemoteUser;
    playSize = inviteMessage.playSize;
    playMode = inviteMessage.playMode;
    playOpener = inviteMessage.playOpener;
    opponentId = inviteMessage.invitingUserId;
    opponentName = inviteMessage.invitingUserName;
  }

  PlayHeader.fromJson(Map<String, dynamic> map) {

    playId = map['playId'];

    playSize = PlaySize.values.firstWhere((p) => p.name == map['playSize']);
    playMode = PlayMode.values.firstWhere((p) => p.name == map['playMode']);
    state = PlayState.values.firstWhere((p) => p.name == map['state']);
    currentRound = map['currentRound'];
    
    if (map['initiator'] != null) {
      initiator = Initiator.values.firstWhere((p) => p.name == map['initiator']);
    }
    if (map['playOpener'] != null) {
      playOpener = PlayOpener.values.firstWhere((p) => p.name == map['playOpener']);
    }

    final previousSignature = map['previousSignature'];
    commContext.previousSignature = previousSignature;
    
    opponentId = map['opponentId'];
    opponentName = map['opponentName'];
    
  }

  Map<String, dynamic> toJson() => {
    "playId" : playId,
    "playSize" : playSize.name,
    "playMode" : playMode.name,
    "state" : state.name,
    "currentRound" : currentRound,

    if (initiator != null) "initiator": initiator?.name,
    if (playOpener != null) "playOpener" : playOpener?.name,
    if (commContext.previousSignature != null) "previousSignature" : commContext.previousSignature,
    if (opponentId != null) "opponentId" : opponentId,
    if (opponentName != null) "opponentName" : opponentName,
  };

  int get dimension => playSize.toDimension();

  String getReadablePlayId() {
    return toReadableId(playId);
  }

  @override
  String toString() {
    return 'PlayHeader{playId: $playId, state: $state, commContext: $commContext, playSize: $playSize, currentRound: $currentRound, name: $opponentName, playMode: $playMode, playOpener: $playOpener}';
  }

  String getReadableState() {
    switch (state) {
      case PlayState.Initialised: return "New match, send invitation needed";
      case PlayState.RemoteOpponentInvited: return "Invitation sent out";
      case PlayState.InvitationPending: return "Open invitation needs response";
      case PlayState.InvitationAccepted: return "Invitation accepted";
      case PlayState.InvitationRejected: return "Invitation rejected";
      case PlayState.ReadyToMove: return "Your turn!";
      case PlayState.WaitForOpponent: return "Awaiting opponent's move";
      case PlayState.Lost: return "Match lost";
      case PlayState.Won: return "Match won";
      case PlayState.Resigned: return "You resigned :(";
      case PlayState.OpponentResigned: return "Opponent resigned, you win";
      case PlayState.Closed: return "Match finished";
    }
  }

  Color getStateColor() {
    switch (state) {
      case PlayState.Initialised: return getColorFromIdx(6);
      case PlayState.RemoteOpponentInvited: return getColorFromIdx(7);
      case PlayState.InvitationPending: return getColorFromIdx(7);
      case PlayState.InvitationAccepted: return getColorFromIdx(4);
      case PlayState.InvitationRejected: return getColorFromIdx(8);
      case PlayState.ReadyToMove: return getColorFromIdx(9);
      case PlayState.WaitForOpponent: return getColorFromIdx(1);
      case PlayState.Lost: return Colors.redAccent;
      case PlayState.Won: return Colors.lightGreenAccent;
      case PlayState.Resigned: return Colors.redAccent;
      case PlayState.OpponentResigned: return Colors.lightGreenAccent;
      case PlayState.Closed: return Colors.black54;
    }
  }
}

@JsonSerializable()
class Play {

  late PlayHeader header;
  bool multiPlay = false;

  // play state
  Role _currentRole = Role.Chaos;
  GameChip? _currentChip;

  Stats _stats = Stats();
  Cursor _selectionCursor = Cursor();
  Cursor _opponentCursor = Cursor();

  late Matrix _matrix;
  late Stock _stock;
  late final PlayerType _chaosPlayer;
  late final PlayerType _orderPlayer;

  Ai? chaosAi;
  Ai? orderAi;

  DateTime startDate = DateTime.timestamp();
  DateTime? endDate;
 

  final List<Move> _journal = [];
  Move? _staleMove;

  Play.newSinglePlay(this.header, this._chaosPlayer, this._orderPlayer) {
    _init(initAi: true);
  }

  Play.newMultiPlay(this.header) {
    _chaosPlayer = header.initiator == Initiator.LocalUser && header.playOpener == PlayOpener.InvitingPlayer ? PlayerType.LocalUser : PlayerType.RemoteUser; //TOOO
    _orderPlayer = _chaosPlayer == PlayerType.LocalUser ? PlayerType.RemoteUser : PlayerType.LocalUser;
    multiPlay = true;
    
    _init(initAi: false);
  }

  // PlayHeader needs to be injected
  Play.fromJson(Map<String, dynamic> map) {

    multiPlay = map['multiPlay'];
    
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

    _initAis();
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


  // initialises the play state to get started
  void _init({required bool initAi}) {

    _journal.clear();
    _opponentCursor.clear();
    _selectionCursor.clear();
    _currentRole = Role.Chaos;
    header.currentRound = 0;//TODO init() on header

    _matrix = Matrix(Coordinate(dimension, dimension));

    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      final chip = GameChip(i);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }
    _stock = Stock(chips);
    nextChip();


    if (initAi) {
      _initAis();
    }
  }

  Map<String, dynamic> toJson() => {
    "multiPlay" : multiPlay,
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

  int getPointsPerChip() => _matrix.getPointsPerChip(header.dimension);

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

  bool get isBothSidesSinglePlay => _chaosPlayer == PlayerType.LocalUser && _orderPlayer == PlayerType.LocalUser;

  bool get isFullAutomaticPlay => _chaosPlayer == PlayerType.LocalAi && _orderPlayer == PlayerType.LocalAi;

  Role finishGame() {

    _currentRole = _stats.getWinner();
    _currentChip = null;
    _selectionCursor.clear();

    return _currentRole;
  }

  void _initAis() {
    chaosAi = DefaultChaosAi();
    orderAi = DefaultOrderAi();

  }

  int get currentRound => header.currentRound;
  Stats get stats => _stats;
  Stock get stock => _stock;
  int get dimension => header.dimension;
  Matrix get matrix => _matrix;
  Cursor get selectionCursor => _selectionCursor;
  Cursor get opponentCursor => _opponentCursor;

  GameChip? get currentChip => _currentChip;

  CommunicationContext get commContext => header.commContext;

  GameChip? nextChip() {
    _currentChip = _stock.drawNext();
    return currentChip;
  }



  incRound() {
    header.currentRound++;
  }

  decRound() {
    header.currentRound--;
  }

  bool get waitForOpponent => header.state == PlayState.WaitForOpponent;


  set waitForOpponent(bool wait) {
    if (wait) {
      header.state = PlayState.WaitForOpponent;
    } else
      header.state = PlayState.ReadyToMove;
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
    _init(initAi: false);
  }


  String getReadablePlayId() {
    return toReadableId(header.playId);
  }



}