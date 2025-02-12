
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/play.dart';
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
  Role? recentOpponentRole;
  bool showOpponentTrace = false;

  GameEngine(this.play, this.user);

  void resumeGame();
  void doRound();
  /**
   * What to do with the stored play once the game is over.
   */
  void handleGameOverSavePlay();
  void cleanUp();


  PrefDef get savePlayKey;
  double? get progressRatio;

  restartGame() {
    //TODO remote games cannot be restarted, implement a veto
    cleanUp();
    play.reset();
    waitForOpponent = false;
    recentOpponentRole = null;
    savePlay();
    notifyListeners();
    resumeGame();
  }

  nextRound() {

    if (play.isGameOver()) {
      debugPrint("Game over, no next round");
      finish();
      return;
    }

    play.nextRound(!showOpponentTrace);
    savePlay();
    notifyListeners();

    doRound();
  }
  void leave() {
    savePlay();
    cleanUp();
  }

  bool isBoardLocked() => waitForOpponent || play.isGameOver();

  void savePlay() {
    if (play.isGameOver()) {
      handleGameOverSavePlay();
    }
    else {
      final jsonToSave = jsonEncode(play);
      //debugPrint(getPrettyJSONString(game.play));
      debugPrint("Save current play");
      PreferenceService().setString(savePlayKey, jsonToSave);
    }
  }


  Role finish() {
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

    return winner;
  }

  void _saveUser() {
    final jsonToSave = jsonEncode(user);
    debugPrint(getPrettyJSONString(user));
    debugPrint("Save current user");
    PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
  }

}

class SinglePlayerGameEngine extends GameEngine {

  Load? aiLoad;
  SendPort? _aiControlPort;

  SinglePlayerGameEngine(Play play, User user): super(play, user);
  
  resumeGame() {
    if (play.currentPlayer == PlayerType.Ai) {
      _think();
    }
  }

  void doRound() {
    if (play.currentPlayer == PlayerType.Ai) {
      _think();
    }
  }

  
  cleanUp() {
    _kill();
  }

  @override
  void handleGameOverSavePlay() {
    PreferenceService().remove(PreferenceService.DATA_CURRENT_PLAY);
  }

  @override
  PrefDef get savePlayKey => PreferenceService.DATA_CURRENT_PLAY;

  @override
  double? get progressRatio => aiLoad?.ratio;


  void _think() {
    waitForOpponent = true;
    aiLoad = null;
    showOpponentTrace = true;
    notifyListeners();

    var autoplayDelayInSec = 250;
    Future.delayed(Duration(milliseconds: play.isFullAutomaticPlay ? autoplayDelayInSec :  0), () {
      recentOpponentRole = null;

      play.startThinking((Load load)
      {
        aiLoad = load;
        notifyListeners();
      },
          _aiNextMoveHandler,
              (SendPort aiIsolateControlPort) => _aiControlPort = aiIsolateControlPort);
    });

  }
  
  _aiNextMoveHandler(Move move) {
    debugPrint("AI ready");
    waitForOpponent = false;
    recentOpponentRole = play.currentRole;

    play.applyStaleMove(move);
    play.opponentCursor.adaptFromMove(move);
    play.commitMove();

    if (play.isGameOver()) {
      finish();
      notifyListeners();
    }
    else {
      notifyListeners();
      nextRound();
    }
  }
  
  void _kill() {
    _aiControlPort?.send('KILL');
  }
  
}


class MultiPlayerGameEngine extends GameEngine {


  MultiPlayerGameEngine(Play play, User user): super(play, user);


  resumeGame() {
    if (play.currentPlayer == PlayerType.RemoteUser) {
    // TODO indicate waiting
    }
  }

  void doRound() {

    if (play.currentPlayer == PlayerType.RemoteUser) {
      shareGameMove();
    }
  }

  void shareGameMove() {
    //BitsService().;
    final uri = "https://hx.jepfa.de/${play.id}";
    /*
    TODO use BitService
     */
    Share.share('Open this with HyleX: $uri', subject: 'HyleX interaction');
  }


  @override
  void handleGameOverSavePlay() {
    // TODO keep instead of remove PreferenceService().remove(savePlayKey);
  }

  @override
  void cleanUp() {
  }

  @override
  PrefDef get savePlayKey => PrefDef('data/play/${play.id}', null);

  @override
  double? get progressRatio => null;


}