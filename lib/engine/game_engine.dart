
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/service/MessageService.dart';
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

  GameEngine(this.play, this.user);

  double? get progressRatio;

  void startGame();
  
  Future<void> stopGame() async {
    _cleanUp();
    play.reset();
    await savePlayState();
    notifyListeners();
  }

  Future<void> nextPlayer() async {
    if (play.isGameOver()) {
      debugPrint("Game over, no next round");
      _finish();
      return;
    }

    play.nextPlayer();

    notifyListeners();

    _doNextPlayerMove();

    await savePlayState();
  }
  
  Future<void> pauseGame() async {
    await savePlayState();
    _cleanUp();
  }

  bool isBoardLocked() => play.waitForOpponent || play.isGameOver();

  Future<bool> savePlayState() async {
    return StorageService().savePlay(play);
  }

  
  Role _finish() {
    final winner = play.finishGame();
    if (!play.isFullAutomaticPlay && !play.isBothSidesSinglePlay) {
      //TODO add match-achievements
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
    
    _handleGameOver();

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
      buildAlertDialog("Cannot apply opponent's move. Reason: $result");
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
    notifyListeners();

  }
  
  
  /**
   * What to do with the stored play once the game is over.
   */
  void _handleGameOver();
  
  void _cleanUp();


}

class SinglePlayerGameEngine extends GameEngine {

  Load? aiLoad;
  SendPort? _aiControlPort;

  SinglePlayerGameEngine(Play play, User user): super(play, user);

  void startGame() {
    _doNextPlayerMove();
  }

  void _doNextPlayerMove() {
    if (play.currentPlayer == PlayerType.LocalAi) {
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
    notifyListeners();

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

}


class MultiPlayerGameEngine extends GameEngine {


  MultiPlayerGameEngine(Play play, User user): super(play, user);

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
      MessageService().sendCurrentPlayState(play.header, user, null);
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

}