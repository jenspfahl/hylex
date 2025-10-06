
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
      debugPrint("Game over, no next round");
      _finish();
      return;
    }

    // check if player did a move
    final lastMove = play.journal.lastOrNull;
    if (lastMove == null || !lastMove.isFrom(play.currentRole)) {
      throw Exception("Cannot switch to next player, current player didn't apply a move.");
    }

    play.nextPlayer();

    _doNextPlayerMove();

    await savePlayState();
  }
  
  Future<void> pauseGame() async {
    await savePlayState();
    _cleanUp();
  }

  bool isBoardLocked() => play.waitForOpponent || play.isGameOver();

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
  opponentMoveReceived(Move opponentMove) async {
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

    play.waitForOpponent = false;

    if (play.isGameOver()) {
      _finish();
    }
    else {
      await nextPlayer();
    }
  }
  
  
  /**
   * What to do with the stored play once the game is over.
   */
  void _handleGameOver();
  
  void _cleanUp();

  resignGame();


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
    _doNextPlayerMove();
  }

  void _doNextPlayerMove() {
    if (!play.isGameOver() && play.currentPlayer == PlayerType.LocalAi) {
      _think();
    }
    // else the user has to do the move
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
    play.waitForOpponent = true;
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

    if (play.currentPlayer == PlayerType.RemoteUser && !play.waitForOpponent) {
      play.waitForOpponent = true;
      shareGameMove();
    }
  }

  void shareGameMove() {

    if (play.header.isStateShareable()) {
      MessageService().sendCurrentPlayState(play.header, user, contextProvider);
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
  opponentMoveReceived(Move move) {
    if (play.currentPlayer == PlayerType.RemoteUser) {
      super.opponentMoveReceived(move);
    }
  }

  @override
  resignGame() async {
    await PlayStateManager().doResign(play.header, user);
    await MessageService().sendResignation(play.header, user, contextProvider);
  }

}