import 'dart:collection';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
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


enum PlayStateGroup {
  AwaitOpponentAction(false),
  TakeAction(false),
  FinishedAndWon(true),
  FinishedAndLost(true),
  Other(true);

  final bool isFinal;
  const PlayStateGroup(this.isFinal);
}
/**
 * Single:
 *     Initialised --> [ ReadyToMove | WaitForOpponent ] --> [ Won | Lost | Closed]
 *
 * Invitor:
 *     RemoteOpponentInvited --> InvitationRejected
 *     RemoteOpponentInvited --> RemoteOpponentAccepted --> [ ReadyToMove | WaitForOpponent ] --> [ Won | Lost | Resigned | OpponentResigned ]
 *
 * Invitee:
 *     InvitationPending --> InvitationRejected
 *     InvitationPending --> InvitationAccepted_ReadyToMove --> [ ReadyToMove | WaitForOpponent ] --> [ Won | Lost | Resigned | OpponentResigned ]
 *     InvitationPending --> InvitationAccepted_WaitForOpponent --> [ WaitForOpponent | ReadyToMove ] --> [ Won | Lost | Resigned | OpponentResigned ]
 *
 * Multiplayer flows:
 *   Rejection:
 *    Invitor:  RemoteOpponentInvited
 *      Invitee:  InvitationPending
 *      Invitee:  InvitationRejected(final)
 *        Invitor:  InvitationRejected(final)
 *  Acceptance:
 *    Invitor:  RemoteOpponentInvited
 *      Invitee:  InvitationPending
 *      Invitee:  InvitationAccepted
 *        Invitor:  ReadyToMove
 *        Invitor:  WaitForOpponent
 *          Invitee: ReadyToMove
 *          Invitee: WaitForOpponent
 *           ...
 *
 * more details in README.MD
 */
enum PlayState {
  
  // Initial state for single play
  Initialised({Actor.Single}, false, false, false, PlayStateGroup.Other),

  // only if multiPlay == true and current == invitor player, if an invitation has been sent out
  RemoteOpponentInvited({Actor.Invitor}, true, false, false, PlayStateGroup.AwaitOpponentAction),

  // only if multiPlay == true, when an invitation has been received but not replied
  InvitationPending({Actor.Invitee}, false, false, false, PlayStateGroup.TakeAction),

  // only if multiPlay == true, when an invitation has been accepted by the remote player
  RemoteOpponentAccepted_ReadyToMove({Actor.Invitor}, false, true, false, PlayStateGroup.TakeAction),

  // only if multiPlay == true, when an invitation has been accepted by invited player and has to perform the first moe
  InvitationAccepted_ReadyToMove({Actor.Invitee}, false, true, false, PlayStateGroup.TakeAction),

  // only if multiPlay == true, when an invitation has been accepted by invited player and awaits the first move from the invitor
  InvitationAccepted_WaitForOpponent({Actor.Invitee}, true, true, false, PlayStateGroup.AwaitOpponentAction),

  // only if multiPlay == true, when an invitation has been rejected by invited player
  InvitationRejected({Actor.Invitor, Actor.Invitee}, null, false, true, PlayStateGroup.Other), // final state

  // Current player can move
  ReadyToMove({Actor.Single, Actor.Invitor, Actor.Invitee}, false, true, false, PlayStateGroup.TakeAction),

  // Current play is waiting for remote opponent to move (either RemoteUser or Ai)
  WaitForOpponent({Actor.Single, Actor.Invitor, Actor.Invitee}, true, true, false, PlayStateGroup.AwaitOpponentAction),

  // current player lost. If both players on a single play are human, this is not used
  Lost({Actor.Single, Actor.Invitor, Actor.Invitee}, null, true, true, PlayStateGroup.FinishedAndLost), // final state

  // current player won. If both players on a single play are human, this is not used
  Won({Actor.Single, Actor.Invitor, Actor.Invitee}, null, true, true, PlayStateGroup.FinishedAndWon), // final state

  // current player resigned (and the remote opponent won therefore). If both players on a single play are human, this is not used
  Resigned({Actor.Invitor, Actor.Invitee}, true, true, true, PlayStateGroup.FinishedAndLost), // final state

  // opponent player resigned (and the current opponent won therefore). If both players on a single play are human, this is not used
  OpponentResigned({Actor.Invitor, Actor.Invitee}, false, true, true, PlayStateGroup.FinishedAndWon), // final state

  // used if both players on a single play are human or any other final state like no invitation response etc..
  Closed({Actor.Single}, false, false, true, PlayStateGroup.Other),

  // Classic mode only: First game has been finished, now the roles can be swapped and the local player becomes Chaos to take the first move of the second game
  FirstGameFinished_ReadyToSwap({Actor.Invitor, Actor.Invitee}, false, true, false, PlayStateGroup.TakeAction),

  // Classic mode only: First game has been finished, now the roles can be swapped and the local player becomes Order who has to wait for the opponents first move of the second game
  FirstGameFinished_WaitForOpponent({Actor.Invitor, Actor.Invitee}, true, true, false, PlayStateGroup.AwaitOpponentAction),

  ;

  const PlayState(this.forActors, this.isShareable, this.hasGameBoard, this.isFinal, this.group);

  final Set<Actor> forActors;
  final bool? isShareable; // if null (won or lost), shareable depends on we did the last move (it is usually chaos)
  final bool hasGameBoard;
  final bool isFinal;
  final PlayStateGroup group;

  checkTransition(PlayState newPlayState, Actor forActor) {
    if (this == newPlayState) {
      return;
    }
    if (!newPlayState.forActors.contains(forActor)) {
      throw Exception("new state $newPlayState not allowed for $forActor");
    }
    if (this.isFinal) {
      throw Exception("current state $this is already final");
    }

    if (allowedTransitions[this]?.contains(newPlayState) == false) {
      throw Exception("transition from current state $this to $newPlayState not allowed");
    }
  }

  String toMessage() {
    switch (this) {
      case PlayState.Initialised: return translate("playStates.initialised");
      case PlayState.RemoteOpponentInvited: return translate("playStates.remoteOpponentInvited");
      case PlayState.InvitationPending: return translate("playStates.invitationPending");
      case PlayState.RemoteOpponentAccepted_ReadyToMove: return translate("playStates.remoteOpponentAccepted_ReadyToMove");
      case PlayState.InvitationAccepted_ReadyToMove: return translate("playStates.invitationAccepted_ReadyToMove");
      case PlayState.InvitationAccepted_WaitForOpponent: return translate("playStates.invitationAccepted_WaitForOpponent");
      case PlayState.InvitationRejected: return translate("playStates.invitationRejected");
      case PlayState.ReadyToMove: return translate("playStates.readyToMove");
      case PlayState.WaitForOpponent: return translate("playStates.waitForOpponent");
      case PlayState.FirstGameFinished_ReadyToSwap: return translate("playStates.firstGameFinished_ReadyToSwap");
      case PlayState.FirstGameFinished_WaitForOpponent: return translate("playStates.firstGameFinished_WaitForOpponent");
      case PlayState.Lost: return translate("playStates.lost");
      case PlayState.Won: return translate("playStates.won");
      case PlayState.Resigned: return translate("playStates.resigned");
      case PlayState.OpponentResigned: return translate("playStates.opponentResigned");
      case PlayState.Closed: return translate("playStates.closed");
    }
  }

  Color toColor() {
    switch (this) {
      case PlayState.Initialised: return getColorFromIdx(6);
      case PlayState.RemoteOpponentInvited: return getColorFromIdx(7);
      case PlayState.InvitationPending: return getColorFromIdx(7);
      case PlayState.RemoteOpponentAccepted_ReadyToMove: return getColorFromIdx(4);
      case PlayState.InvitationAccepted_ReadyToMove: return getColorFromIdx(9);
      case PlayState.InvitationAccepted_WaitForOpponent: return getColorFromIdx(1);
      case PlayState.InvitationRejected: return getColorFromIdx(8);
      case PlayState.ReadyToMove: return getColorFromIdx(9);
      case PlayState.WaitForOpponent: return getColorFromIdx(1);
      case PlayState.FirstGameFinished_ReadyToSwap: return getColorFromIdx(9);
      case PlayState.FirstGameFinished_WaitForOpponent: return getColorFromIdx(1);
      case PlayState.Lost: return Colors.redAccent;
      case PlayState.Won: return Colors.lightGreenAccent;
      case PlayState.Resigned: return Colors.redAccent;
      case PlayState.OpponentResigned: return Colors.lightGreenAccent;
      case PlayState.Closed: return Colors.black54;
    }
  }

  static Map<PlayState, List<PlayState>> allowedTransitions = _createAllowedTransitions();

  static Map<PlayState, List<PlayState>> _createAllowedTransitions() {
    final Map<PlayState, List<PlayState>> transitions = HashMap();

    transitions[PlayState.Initialised] = [ReadyToMove, WaitForOpponent, Lost, Won, Closed];
    transitions[PlayState.RemoteOpponentInvited] = [InvitationRejected, RemoteOpponentAccepted_ReadyToMove];
    transitions[PlayState.InvitationPending] = [InvitationRejected, InvitationAccepted_ReadyToMove, InvitationAccepted_WaitForOpponent];
    transitions[PlayState.RemoteOpponentAccepted_ReadyToMove] = [WaitForOpponent, Resigned];
    transitions[PlayState.InvitationAccepted_WaitForOpponent] = [ReadyToMove, OpponentResigned];
    transitions[PlayState.InvitationAccepted_ReadyToMove] = [InvitationAccepted_WaitForOpponent, Resigned];
    transitions[PlayState.WaitForOpponent] = [ReadyToMove, FirstGameFinished_ReadyToSwap, OpponentResigned, Lost, Won, Closed];
    transitions[PlayState.ReadyToMove] = [WaitForOpponent, FirstGameFinished_WaitForOpponent, Resigned, Lost, Won, Closed];
    transitions[PlayState.FirstGameFinished_WaitForOpponent] = [ReadyToMove, OpponentResigned];
    transitions[PlayState.FirstGameFinished_ReadyToSwap] = [ReadyToMove, Resigned];

    return transitions;
  }
}

/**
 * This contains header information of each play.
 */
@JsonSerializable()
class PlayHeader {

  late String playId;
  late PlaySize playSize;
  PlayMode playMode = PlayMode.HyleX;
  PlayState _state = PlayState.Initialised;
  int currentRound = 0;
  bool? rolesSwapped = null; // only true if PlayMode.CLASSIC and the second game goes on
  Map<String, dynamic> props = HashMap();

  // multi player attributes
  late Actor actor;
  PlayOpener? playOpener;
  CommunicationContext commContext = CommunicationContext();
  String? opponentId;
  String? opponentName;
  DateTime? lastTimestamp;
  String? successorPlayId;


  PlayHeader.singlePlay(
      this.playSize) {
    playId = generateRandomString(playIdLength);
    actor = Actor.Single;
    _touch();
  }
  
  PlayHeader.multiPlayInvitor(
      this.playSize, 
      this.playMode, 
      this.playOpener) {
    playId = generateRandomString(playIdLength);
    actor = Actor.Invitor;
    _state = PlayState.RemoteOpponentInvited;
    if (playMode == PlayMode.Classic) {
      rolesSwapped = false;
    }
    _touch();
  }
  
  PlayHeader.multiPlayInvitee(
      InviteMessage inviteMessage,
      CommunicationContext? comContext,
      PlayState state) {
    playId = inviteMessage.playId;
    actor = Actor.Invitee;
    _state = state;
    if (comContext != null) {
      commContext = comContext;
    }
    playSize = inviteMessage.playSize;
    playMode = inviteMessage.playMode;
    playOpener = inviteMessage.playOpener;
    opponentId = inviteMessage.invitorUserId;
    opponentName = inviteMessage.invitorUserName;
    if (playMode == PlayMode.Classic) {
      rolesSwapped = false;
    }
    _touch();
  }

  PlayHeader.internal(
      this.playId,
      this.playSize,
      this.playMode,
      PlayState state,
      this.currentRound,
      this.actor,
      this.playOpener,
      this.opponentId,
      this.opponentName
      ) {
    _state = state;
  }

  PlayHeader.fromJson(Map<String, dynamic> map) {

    playId = map['playId'];
    successorPlayId = map['successorPlayId'];

    playSize = PlaySize.values.firstWhere((p) => p.name == map['playSize']);
    playMode = PlayMode.values.firstWhere((p) => p.name == map['playMode']);
    _state = PlayState.values.firstWhere((p) => p.name == map['state']);
    currentRound = map['currentRound'];
    rolesSwapped = map['rolesSwapped'];
    actor = Actor.values.firstWhere((p) => p.name == map['actor']);

    if (map['playOpener'] != null) {
      playOpener = PlayOpener.values.firstWhere((p) => p.name == map['playOpener']);
    }

    commContext.roundTripSignature = map['roundTripSignature'];
    final predecessorMessagePayload = map['predecessorMessagePayload'];
    final predecessorMessageSignature = map['predecessorMessageSignature'];
    if (predecessorMessagePayload != null && predecessorMessageSignature != null) {
      commContext.predecessorMessage = SerializedMessage(predecessorMessagePayload, predecessorMessageSignature);
    }

    final List<dynamic> messageHistory = map['messageHistory']!;
    if (messageHistory.isNotEmpty) {
      commContext.messageHistory.addAll(messageHistory.map((value) {
        return ChannelMessage.fromJson(value);
      }));
    }

    final List<dynamic>? propList = map['props'];
    if (propList != null) {
      propList.forEach((e) {
        final keyValue = e as Map<String, dynamic>;
        props.addAll(keyValue);
      });
    }

    opponentId = map['opponentId'];
    opponentName = map['opponentName'];

    final lastChange = map['lastChange'];
    if (lastChange != null) {
      lastTimestamp = DateTime.parse(lastChange);
    }


    
  }

  PlayState get state {
    return _state;
  }

  set state(PlayState newState) {
    _state.checkTransition(newState, actor);
    _state = newState;
    _touch();
  }

  String getTitle() {
    if (opponentName != null) {
      return translate("gameTitle.playAgainstOpponent",
        args: {
          "playId" : getReadablePlayId(),
          "opponent" : opponentName
        });
    }
    else {
      return getReadablePlayId();
    }
  }

  _touch() {
    lastTimestamp = DateTime.timestamp();
  }

  Map<String, dynamic> toJson() => {
    "playId" : playId,
    "playSize" : playSize.name,
    "playMode" : playMode.name,
    "state" : _state.name,
    "currentRound" : currentRound,
    "rolesSwapped" : rolesSwapped,
    "actor": actor.name,
    if (playOpener != null) "playOpener" : playOpener?.name,
    if (commContext.roundTripSignature != null) "roundTripSignature" : commContext.roundTripSignature,
    if (commContext.predecessorMessage != null) "predecessorMessagePayload" : commContext.predecessorMessage!.payload,
    if (commContext.predecessorMessage != null) "predecessorMessageSignature" : commContext.predecessorMessage!.signature,
    "messageHistory" : commContext.messageHistory.map((m) => m.toJson()).toList(),
    "props" : props.entries.map((e) => {e.key: e.value}).toList(),

    if (opponentId != null) "opponentId" : opponentId,
    if (opponentName != null) "opponentName" : opponentName,
    if (lastTimestamp != null) "lastChange" : lastTimestamp!.toIso8601String(),
    "successorPlayId" : successorPlayId,

  };

  int get dimension => playSize.dimension;
  int get maxRounds => playSize.dimension * playSize.dimension;

  String getReadablePlayId() {
    return toReadableId(playId);
  }

  Role? getLocalRoleForMultiPlay() {
    return actor.getActorRoleFor(playOpener);
  }

  @override
  String toString() {
    return 'PlayHeader{playId: $playId, state: $_state, commContext: $commContext, playSize: $playSize, currentRound: $currentRound, name: $opponentName, playMode: $playMode, playOpener: $playOpener, actor: $actor, roleSwapped: $rolesSwapped}';
  }

  void init(bool multiPlay, int round) {
    currentRound = round;
    if (!multiPlay) {
      _state = PlayState.Initialised;
    }
  }

  bool isStateShareable() {
    if (state.isShareable == null) {
      if (state == PlayState.InvitationRejected) {
        final lastMessage = commContext.messageHistory.lastOrNull;
        return lastMessage != null
            && lastMessage.channel == Channel.Out
            && lastMessage.serializedMessage.extractOperation() == Operation.RejectInvite;
      }
      // Chaos does the last move
      return actor.getActorRoleFor(playOpener) == Role.Chaos;
    }
    else {
      return state.isShareable == true;
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
  Matrix? _classicModeFirstMatrix;
  late Stock _stock;
  late PlayerType _chaosPlayer;
  late PlayerType _orderPlayer;

  Ai? chaosAi;
  Ai? orderAi;

  DateTime startDate = DateTime.timestamp();
  DateTime? endDate;
 

  final List<Move> _journal = [];
  Move? _staleMove;

  Play.newSinglePlay(this.header, this._chaosPlayer, this._orderPlayer) {
    _init(multiPlay: false);
  }

  Play.newMultiPlay(this.header) {
    final actorRole = header.getLocalRoleForMultiPlay();
    if (actorRole == null) {
      throw Exception("When creating a multi play the play opener should be decided.");
    }
    _chaosPlayer = actorRole == Role.Chaos ? PlayerType.LocalUser : PlayerType.RemoteUser; 
    _orderPlayer = actorRole == Role.Order ? PlayerType.LocalUser : PlayerType.RemoteUser; 

    _init(multiPlay: true);
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
    final classicModeFirstMatrixJson = map['classicModeFirstMatrix'];
    if (classicModeFirstMatrixJson != null) {
      _classicModeFirstMatrix = Matrix.fromJson(classicModeFirstMatrixJson);
    }

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
    final winner = getWinnerRole();
    if (winner == Role.Order) {
      return _orderPlayer;
    }
    return _chaosPlayer;
  }

  PlayerType getLooserPlayer() {
    final looser = getLooserRole();
    if (looser == Role.Order) {
      return _orderPlayer;
    }
    return _chaosPlayer;
  }

  Role getWinnerRole() {
    if (multiPlay && header.state == PlayState.Resigned) {
      return header.getLocalRoleForMultiPlay()!.opponentRole;
    }
    else if (multiPlay && header.state == PlayState.OpponentResigned) {
      return header.getLocalRoleForMultiPlay()!;
    }
    else {
      return _stats.getWinner();
    }
  }
  Role getLooserRole() => getWinnerRole().opponentRole;

  // initialises the play state to get started
  void _init({
    required bool multiPlay,
    Role? role,
    PlayerType? chaosPlayer,
    PlayerType? orderPlayer,
    bool clearJournal = true,
    int? round,
  }) {

    this.multiPlay = multiPlay;
    if (clearJournal) {
      _journal.clear();
    }
    _opponentCursor.clear();
    _selectionCursor.clear();
    _currentRole = role ?? Role.Chaos;

    if (chaosPlayer != null) {
      _chaosPlayer = chaosPlayer;
    }
    if (orderPlayer != null) {
      _orderPlayer = orderPlayer;
    }

    header.init(multiPlay, round ?? 1);

    _matrix = Matrix(Coordinate(dimension, dimension));
    _stats.clear();

    var chips = HashMap<GameChip, int>();
    for (int i = 0; i < dimension; i++) {
      final chip = GameChip(i);
      chips[chip] = dimension; // the stock per chip is the dimension value
    }
    _stock = Stock(chips);
    nextChip();


    if (!multiPlay) {
      _initAis();
    }
  }

  Map<String, dynamic> toJson() => {
    "multiPlay" : multiPlay,
    "currentRole" : _currentRole.name,
    if (_currentChip != null) "currentChip" : _currentChip!.toKey(),
    "matrix" : _matrix.toJson(),
    if (_classicModeFirstMatrix != null) "classicModeFirstMatrix" : _classicModeFirstMatrix!.toJson(),
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

  Role get opponentRole => currentRole.opponentRole;

  switchRole() {
    debugPrint("Switch role from $_currentRole");
    _currentRole = opponentRole;
  }

  Move? get lastMoveFromJournal => _journal.lastOrNull;
  List<Move> get journal => _journal.toList(growable: false);

  bool get isJournalEmpty => _journal.isEmpty;


  applyStaleMove(Move move) {
    //check move is valid (against the rules)
    final result = validateMove(move);

    if (result != null) {
      throw Exception(result);
    }

    if (move.isMove()) {
      // set moved chip
      _matrix.move(move.from!, move.to!);
    }
    else if (!move.skipped) {
      _matrix.put(move.to!, move.chip!, _stock);
    }
    _staleMove = move;
    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    if (header.playMode != PlayMode.Classic) {
      _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos(header.playSize));
    }
  }

  commitMove() {
    if (_staleMove != null) {
      debugPrint("add move to journal: $_staleMove");
      _journal.add(_staleMove!);

      selectionCursor.clear();
      opponentCursor.adaptFromMove(_staleMove!);
      opponentCursor.markTraceForDoneMove();
    }

    _staleMove = null;
  }

  Move? _removeLastMoveFromJournal() {
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
      _matrix.remove(move.to!, _stock);
    }

    if (_staleMove == move) {
      _staleMove = null;
    }

    _stats.setPoints(Role.Order, _matrix.getTotalPointsForOrder());
    if (header.playMode != PlayMode.Classic) {
      _stats.setPoints(Role.Chaos, _matrix.getTotalPointsForChaos(header.playSize));
    }
  }

  bool get hasStaleMove => _staleMove != null;
  
  Move? get staleMove => _staleMove;
  
  Move? get currentMove => _staleMove;

  int getChaosPointsPerChip() => header.playSize.chaosPointsPerChip;

  bool shouldGameBeOver() => !hasStaleMove && (_stock.isEmpty() || _matrix.noFreeSpace());

  void swapGameForClassicMode() {
    _stats.classicModeFirstRoundOrderPoints = _stats.getPoints(Role.Order);
    // swap roles and clear play board but remember order points
    _classicModeFirstMatrix = matrix.clone();

    _init(
      multiPlay: true,
      role: header.getLocalRoleForMultiPlay()!.opponentRole,
      chaosPlayer: orderPlayer,
      orderPlayer: chaosPlayer,
      clearJournal: false,
      round: header.getLocalRoleForMultiPlay() == Role.Chaos ? 0 : 1 
    );


    header.playOpener = header.playOpener == PlayOpener.Invitor ? PlayOpener.Invitee : PlayOpener.Invitor;
    
    header.rolesSwapped = true;
    header.state = PlayState.ReadyToMove;

    debugPrint("swapped: ${header.state}");

  }

  bool isFirstGameOverForClassicMode() => header.playMode == PlayMode.Classic
      && header.rolesSwapped == false
      && shouldGameBeOver();

  void nextPlayer() {
    switchRole();
    if (currentRole == Role.Chaos) {
      // transition from Order to Chaos

      nextChip();
      incRound();
    }
    else {
      _currentChip = null;
    }

  }

  Move? previousPlayer() {
    final lastMove = _removeLastMoveFromJournal();
    if (lastMove != null) {
      _undoMove(lastMove);

      if (lastMove.isPlaced()) {
        _currentChip = lastMove.chip;
      }
      else {
        _currentChip = null;
      }

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

  bool get isMultiplayerPlay => _chaosPlayer == PlayerType.RemoteUser || _orderPlayer == PlayerType.RemoteUser; //TODO could be replaced with this.multiPlay

  bool get isBothSidesSinglePlay => _chaosPlayer == PlayerType.LocalUser && _orderPlayer == PlayerType.LocalUser;

  bool get isFullAutomaticPlay => _chaosPlayer == PlayerType.LocalAi && _orderPlayer == PlayerType.LocalAi;

  bool get isWithAiPlay => _chaosPlayer == PlayerType.LocalAi || _orderPlayer == PlayerType.LocalAi;

  Role finishGame() {

    _currentRole = getWinnerRole();
    _currentChip = null;
    _selectionCursor.clear();
    _opponentCursor.clear();

    endDate = DateTime.now();

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
  Matrix? get classicModeFirstMatrix => _classicModeFirstMatrix;
  Cursor get selectionCursor => _selectionCursor;
  Cursor get opponentCursor => _opponentCursor;

  GameChip? get currentChip => _currentChip;
  set currentChip(GameChip? chip) => _currentChip = chip;

  CommunicationContext get commContext => header.commContext;

  GameChip? nextChip() {
    if (multiPlay && _chaosPlayer == PlayerType.RemoteUser) {
      // don't show drawn chips by remote players as it happens remotely.
      _currentChip = null;
    }
    else {
      _currentChip = _stock.drawNext();
    }
    return _currentChip;
  }



  incRound() {
    header.currentRound++;
  }

  decRound() {
    header.currentRound--;
  }

  bool get waitForOpponent => header.state == PlayState.WaitForOpponent
      || header.state == PlayState.InvitationAccepted_WaitForOpponent
      || header.state == PlayState.FirstGameFinished_WaitForOpponent;


  set waitForOpponent(bool wait) {
    if (wait) {
      if (header.state == PlayState.InvitationAccepted_ReadyToMove) {
        header.state = PlayState.InvitationAccepted_WaitForOpponent;
      }
      else if (header.state != PlayState.InvitationAccepted_WaitForOpponent
          && header.state != PlayState.FirstGameFinished_WaitForOpponent) {
        header.state = PlayState.WaitForOpponent;
      }
    } else {
      if (header.state != PlayState.InvitationAccepted_ReadyToMove
          && header.state != PlayState.RemoteOpponentAccepted_ReadyToMove
          && header.state != PlayState.FirstGameFinished_ReadyToSwap) {
        header.state = PlayState.ReadyToMove;
      }
    }
  }

  bool isGameOver() {
    if (header.playMode == PlayMode.HyleX) {
      return shouldGameBeOver() || header.state.isFinal;
    }
    else if (header.playMode == PlayMode.Classic) {
      return (header.rolesSwapped == true && shouldGameBeOver())
          || header.state.isFinal;
    }
    throw Exception("Unknown play mode ${header.playMode} for isGameOver");
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
    _init(multiPlay: this.multiPlay);
  }

  String getReadablePlayId() {
    return toReadableId(header.playId);
  }

  /**
   * Returns the last undo-ed move. If null, the beginning has reached and a game restart is required, e.g. to start AI thinking
   */
  Move? undoLastMove() {
    var lastMove = previousPlayer();
    if (currentPlayer == PlayerType.LocalAi) {
      // undo AI move also
      lastMove = previousPlayer();
    }

    if (lastMove != null) {
      final moveBefore = lastMoveFromJournal;
      if (moveBefore != null) {
        opponentCursor.adaptFromMove(moveBefore);
        opponentCursor.markTraceForDoneMove();
      }
    }
    return lastMove;
  }


  // returns null if the move is valid
  String? validateMove(Move move) {
    if (move.isMove() && move.chip == null) {
      // if move came from a message, the chip can be null (for order only)
      move.chip = _matrix.getChip(move.from!);
    }

    if (isGameOver()) {
      return "Game is already over";
    }

    if (currentRole == Role.Chaos && !move.isPlaced()) {
      return "This move is not allowed for Chaos";
    }
    if (currentRole == Role.Order && move.isPlaced()) {
      return "This move is not allowed for Order";
    }

    if (move.isMove()) {
      final from = move.from;
      final to = move.to;

      if (from == null) {
        return "moving from is missing";
      }
      if (to == null) {
        return "moving to is missing";
      }
      if (from.x != to.x && from.y != to.y) {
        return "Move is not vertical or horizontal";
      }

      if (_matrix.isFree(from)) {
        return "Cannot move from an empty field, no chip to move";
      }
      if (!_matrix.isFree(to)) {
        return "Cannot move to an occupied field";
      }

      final possibleTargets = _matrix.detectTraceForPossibleOrderMoves(from).map((s) => s.where);
      if (!possibleTargets.contains(to)) {
        return "cannot move from $from to $to, either out of matrix or blocking cells in between.";
      }

    }
    else if (move.isPlaced()) {
      final chip = move.chip;
      final to = move.to;

      if (chip == null) {
        return "placing chip is missing";
      }
      if (to == null) {
        return "placing to is missing";
      }

      if (!stock.hasStock(chip)) {
        return "No more stock left for $chip";
      }
      if (!_matrix.isFree(to)) {
        return "Cannot place chip on an occupied filed";
      }
    }

    return null;
  }

  PlayerType getPlayerTypeOf(Role role) {
    return role == Role.Chaos ? chaosPlayer : orderPlayer;
  }


}