
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/service/MessageService.dart';

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

  void startGame() {
    _init();
    _doPlayerMove();
  }
  
  void stopGame() {
    _cleanUp();
    play.reset();
    play.waitForOpponent = false;
    savePlayState();
    notifyListeners();
  }

  void nextPlayer() {
    play.waitForOpponent = false;
    if (play.isGameOver()) {
      debugPrint("Game over, no next round");
      _finish();
      return;
    }

    play.nextPlayer();
    savePlayState();
    notifyListeners();

    _doPlayerMove();
  }
  
  void pauseGame() {
    savePlayState();
    _cleanUp();
  }

  bool isBoardLocked() => play.waitForOpponent || play.isGameOver();

  void savePlayState() {
    StorageService().savePlay(play);
  }


  void _init();

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

  void _doPlayerMove();

  /**
   * Called when the opponent move is ready to be applied to the current game and play state.
   */
  opponentMoveReceived(Move move) {
    debugPrint("opponent move received");
    play.waitForOpponent = false;

    play.applyStaleMove(move);
    play.opponentCursor.adaptFromMove(move);
    play.commitMove();

    if (play.isGameOver()) {
      _finish();
      notifyListeners();
    }
    else {
      notifyListeners();
      nextPlayer();
    }
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

  @override
  void _init() {
    play.multiPlay = false;
    play.header.state = PlayState.Initialised;
  }

  void _doPlayerMove() {
    if (play.currentPlayer == PlayerType.LocalAi) {
      _think();
    }
    // else the user has to do the move
  }
  
  _cleanUp() {
    _kill();
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
  
  void _kill() {
    _aiControlPort?.send('KILL');
  }

}


class MultiPlayerGameEngine extends GameEngine {


  MultiPlayerGameEngine(Play play, User user): super(play, user);

  @override
  void _init() {
    play.multiPlay = true;
    play.header.state = PlayState.Initialised;
  }

  void _doPlayerMove() {

    if (play.currentPlayer == PlayerType.RemoteUser) {
      play.waitForOpponent = true;
      savePlayState();
      shareGameMove();
    }
  }

  void shareGameMove() {
    final lastMove = play.lastMoveFromJournal;
    final isAcceptInvite = play.header.actor == Actor.Invitee && play.header.playOpener == PlayOpener.Invitee;
    if (isAcceptInvite) {
      MessageService().sendInvitationAccepted(play.header, user, lastMove, null);
    }
    else if (lastMove != null) {
      MessageService().sendMove(play.header, user, lastMove, null);
    }
    else {
      throw Exception("No lat move but there should");
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