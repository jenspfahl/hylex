
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/PlayStateManager.dart';
import 'package:hyle_x/ui/dialogs.dart';

import '../model/common.dart';
import '../model/move.dart';
import '../model/user.dart';
import '../service/PreferenceService.dart';
import '../service/StorageService.dart';
import 'ai/strategy.dart';

abstract class GameEngine extends ChangeNotifier {

  User user;
  Play play;
  BuildContext Function()? contextProvider;
  Function() handleGameOver;

  GameEngine(this.play, this.user, this.contextProvider, this.handleGameOver);

  double? get progressRatio;

  void startGame();
  
  Future<void> stopGame() async {
    _cleanUp();
    play.reset();
    await savePlayState();
  }

  Future<void> nextPlayer() async {
    if (play.isGameOver()) {
      debugPrint("Game over detected, no next round");
      _finish();
      return;
    }

    // check if player did a move
    final lastMove = play.journal.lastOrNull;
    if (lastMove == null || !lastMove.isFrom(play.currentRole)) {
      throw Exception("Cannot switch to next player, current player didn't apply a move.");
    }

    _doNextPlayerMove();

    await savePlayState();
  }
  
  Future<void> pauseGame() async {
    await savePlayState();
    _cleanUp();
  }

  bool isBoardLocked() => play.waitForOpponent
      || play.header.state == PlayState.FirstGameFinished_ReadyToSwap
      || play.isGameOver();

  undoLastMove() async {
    final lastMove = play.undoLastMove();
    if (lastMove == null) {
      startGame();
    }
    await savePlayState();
  }

  Future<bool> savePlayState() async {
    final saved = await StorageService().savePlay(play);
    notifyListeners();
    return saved;
  }

  
  Role _finish() {
    final winner = play.finishGame();
    if (!play.isFullAutomaticPlay && !play.isBothSidesSinglePlay) {
      if (winner == Role.Order) {
        if (play.orderPlayer == PlayerType.LocalUser) {
          play.header.state = PlayState.Won;
          user.achievements.incWonGame(Role.Order, play.dimension);
          user.achievements.registerPointsForScores(Role.Order, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.chaosPlayer == PlayerType.LocalUser) {
          play.header.state = PlayState.Lost;
          user.achievements.incLostGame(Role.Chaos, play.dimension);
        }
      }
      else if (winner == Role.Chaos) {
        if (play.chaosPlayer == PlayerType.LocalUser) {
          play.header.state = PlayState.Won;
          user.achievements.incWonGame(Role.Chaos, play.dimension);
          user.achievements.registerPointsForScores(Role.Chaos, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.orderPlayer == PlayerType.LocalUser) {
          play.header.state = PlayState.Lost;
          user.achievements.incLostGame(Role.Order, play.dimension);
        }
      }
      StorageService().saveUser(user);
    }
    else if (play.multiPlay) {
      if ((winner == Role.Chaos && play.chaosPlayer == PlayerType.LocalUser)
      || (winner == Role.Order && play.orderPlayer == PlayerType.LocalUser)) {
        play.header.state = PlayState.Won;
      }
      else {
        play.header.state = PlayState.Lost;
      }
    }
    else {
      play.header.state = PlayState.Closed;
    }

    handleGameOver();
    _handleGameOver();

    savePlayState();

    return winner;
  }

  void _doNextPlayerMove();

  /**
   * Called when the opponent move is ready to be applied to the current game and play state.
   */
  Future<void> opponentMoveReceived(Move opponentMove) async {
    debugPrint("opponent move received");

    
    final result = play.validateMove(opponentMove);
    if (result != null) {
      debugPrint("opponent move $opponentMove is invalid: $result");
      showAlertDialog("Cannot apply opponent's move. Reason: $result");
      return;
    }

    play.applyStaleMove(opponentMove);
    play.opponentCursor.adaptFromMove(opponentMove);
    play.opponentCursor.markTraceForDoneMove();
    play.commitMove();

    await nextPlayer();
    
  }
  
  
  /**
   * What to do with the stored play once the game is over.
   */
  void _handleGameOver();
  
  void _cleanUp();

  resignGame();

  String getFullPlayAsUrl() => FullStateMessage(play, user).serialize().toUrl();


}

class SinglePlayerGameEngine extends GameEngine {

  Load? aiLoad;
  SendPort? _aiControlPort;

  SinglePlayerGameEngine(
      Play play,
      User user,
      BuildContext Function()? contextProvider,
      Function() handleGameOver
      ) : super(play, user, contextProvider, handleGameOver);

  void startGame() {
    _thinkOrWait();
  }

  void _doNextPlayerMove() {
    play.nextPlayer();
    _thinkOrWait();
  }

  void _thinkOrWait() {
    if (play.isGameOver()) {
      return;
    }
    if (play.currentPlayer == PlayerType.LocalAi) {
      play.waitForOpponent = true;
      _think();
    }
    else {
      play.waitForOpponent = false;
      savePlayState();
    }
  }
  
  _cleanUp() {
    _killAiAgents();
  }

  @override
  void _handleGameOver() {
    PreferenceService().remove(PreferenceService.DATA_CURRENT_PLAY);
    PreferenceService().remove(PreferenceService.DATA_CURRENT_PLAY_HEADER);
  }

  @override
  double? get progressRatio => aiLoad?.ratio;

  void _think() {
    aiLoad = null;
    savePlayState();

    var autoplayDelayInSec = 250;
    Future.delayed(Duration(milliseconds: play.isFullAutomaticPlay ? autoplayDelayInSec :  0), () {

      play.startThinking((Load load)
      {
        aiLoad = load;
        notifyListeners();
      },
          opponentMoveReceived,
              (SendPort aiIsolateControlPort) => _aiControlPort = aiIsolateControlPort);
    });

  }
  
  void _killAiAgents() {
    _aiControlPort?.send('KILL');
  }

  @override
  resignGame() {
    //not implemented for single player
  }

}


class MultiPlayerGameEngine extends GameEngine {


  MultiPlayerGameEngine(
      Play play,
      User user,
      BuildContext Function()? contextProvider,
      Function() handleGameOver)
      : super(play, user, contextProvider, handleGameOver);

  void startGame() {
  }

  void _doNextPlayerMove() {

    if (play.isFirstGameOverForClassicMode()) {
      if (play.header.getLocalRoleForMultiPlay() == Role.Order) {
        _readyForRoleSwapForClassicMode();
      }
      else {
        _waitForRoleSwapForClassicMode();
        shareGameMove(false);
      }
    }
    else {
      play.nextPlayer();
      if (play.currentPlayer == PlayerType.RemoteUser && !play.waitForOpponent) {
        play.waitForOpponent = true;
        shareGameMove(false);
      }
      else {
        play.waitForOpponent = false;
      }
    }

  }

  void _readyForRoleSwapForClassicMode() {
    play.header.state = PlayState.FirstGameFinished_ReadyToSwap;
    play.switchRole(); // to indicate that the other (remote Order) has to react
    play.currentChip = null;
    debugPrint("ready: Switch to ${play.header.state} and role ${play.currentRole}");
  }

  void _waitForRoleSwapForClassicMode() {
    play.header.state = PlayState.FirstGameFinished_WaitForOpponent;
    play.switchRole(); // to indicate that the other (remote Order) has to react
    play.currentChip = null;
    debugPrint("wait: Switch to ${play.header.state}");
  }

  void shareGameMove(bool showAllOptions) {

    if (play.header.isStateShareable()) {
      MessageService().sendCurrentPlayState(play.header, user, contextProvider, showAllOptions);
    }
  }

  @override
  void _handleGameOver() {
    // TODO keep instead of remove PreferenceService().remove(savePlayKey);
  }

  @override
  void _cleanUp() {
  }

  @override
  double? get progressRatio => null;

  @override
  Future<void> opponentMoveReceived(Move move) async {
    if (play.currentPlayer == PlayerType.RemoteUser) {

      if (play.isFirstGameOverForClassicMode()
        && play.header.state == PlayState.FirstGameFinished_WaitForOpponent) {

        play.swapGameForClassicMode();
        play.nextPlayer();
      }
      await super.opponentMoveReceived(move);
    }
  }

  @override
  resignGame() async {
    await PlayStateManager().doResign(play.header, user);
    await MessageService().sendResignation(play.header, user, contextProvider);
  }

}