
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/service/BitsService.dart';
import 'package:share_plus/share_plus.dart';

import '../service/PreferenceService.dart';
import '../ui/game_ground.dart';
import '../utils.dart';
import '../model/achievements.dart';
import '../model/move.dart';
import 'ai/strategy.dart';

abstract class GameEngine extends ChangeNotifier {

  User user;
  Play play;

  bool waitForOpponent = false;

  GameEngine(this.play, this.user);

  PrefDef get savePlayKey;
  double? get progressRatio;

  void startGame() {
    _doPlayerMove();
  }
  
  void stopGame() {
    _cleanUp();
    play.reset();
    waitForOpponent = false;
    savePlay();
    notifyListeners();
  }

  void nextPlayer() {

    if (play.isGameOver()) {
      debugPrint("Game over, no next round");
      _finish();
      return;
    }

    play.nextPlayer();
    savePlay();
    notifyListeners();

    _doPlayerMove();
  }
  
  void pauseGame() {
    savePlay();
    _cleanUp();
  }

  bool isBoardLocked() => waitForOpponent || play.isGameOver();

  void savePlay() {
    final jsonToSave = jsonEncode(play);
    //debugPrint(getPrettyJSONString(game.play));
    debugPrint("Save current play");
    PreferenceService().setString(savePlayKey, jsonToSave);
    
  }


  Role _finish() {
    final winner = play.finishGame();
    if (!play.isFullAutomaticPlay && !play.isBothSidesSinglePlay) {
      //TODO add match-achievements
      if (winner == Role.Order) {
        if (play.orderPlayer == PlayerType.User) {
          user.achievements.incWonGame(Role.Order, play.dimension);
          user.achievements.registerPointsForScores(Role.Order, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.chaosPlayer == PlayerType.User) {
          user.achievements.incLostGame(Role.Chaos, play.dimension);
        }
      }
      else if (winner == Role.Chaos) {
        if (play.chaosPlayer == PlayerType.User) {
          user.achievements.incWonGame(Role.Chaos, play.dimension);
          user.achievements.registerPointsForScores(Role.Chaos, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.orderPlayer == PlayerType.User) {
          user.achievements.incLostGame(Role.Order, play.dimension);
        }
      }
      _saveUser();
    }
    
    _handleGameOver();

    return winner;
  }

  void _saveUser() {
    final jsonToSave = jsonEncode(user);
    debugPrint(getPrettyJSONString(user));
    debugPrint("Save current user");
    PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
  }


  void _doPlayerMove();

  /**
   * Called when the opponent move is ready to be applied to the current game and play state.
   */
  opponentMoveReceived(Move move) {
    debugPrint("opponent move received");
    waitForOpponent = false;

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
  
  void _doPlayerMove() {
    if (play.currentPlayer == PlayerType.Ai) {
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
  }

  @override
  PrefDef get savePlayKey => PreferenceService.DATA_CURRENT_PLAY;

  @override
  double? get progressRatio => aiLoad?.ratio;


  void _think() {
    waitForOpponent = true;
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
  

  void _doPlayerMove() {

    if (play.currentPlayer == PlayerType.RemoteUser) {
      shareGameMove();
      waitForOpponent = true;
    }
  }

  void shareGameMove() {
    final lastMove = play.lastMoveFromJournal;
    if (lastMove != null) {
      final message = BitsService().sendMove(play.id, play.currentRound, lastMove);

      Share.share('Open this link with HyleX: ${message.toUrl()}', subject: 'HyleX interaction');
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
  PrefDef get savePlayKey => PrefDef('data/play/${play.id}', null);

  @override
  double? get progressRatio => null;



}