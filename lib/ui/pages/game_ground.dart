
import 'dart:async';
import 'dart:collection';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/matrix.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/pages/multi_player_matches.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/ui/pages/start_page.dart';
import 'package:hyle_x/utils/dates.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../../engine/game_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../model/chip.dart';
import '../../model/common.dart';
import '../../model/cursor.dart';
import '../../service/MessageService.dart';
import '../chip_extension.dart';
import '../../model/coordinate.dart';
import '../../model/move.dart';
import '../../model/play.dart';
import '../../model/spot.dart';
import '../../model/stock.dart';
import '../../model/user.dart';
import '../ui_utils.dart';
import '../Tooltips.dart';
import '../dialogs.dart';

class HyleXGround extends StatefulWidget {
  User user;
  Play play;
  Move? opponentMoveToApply;
  Function()? loadHandler;

  HyleXGround(this.user, this.play, {super.key, this.opponentMoveToApply, this.loadHandler});

  @override
  State<HyleXGround> createState() => _HyleXGroundState();

}

class _HyleXGroundState extends State<HyleXGround> with TickerProviderStateMixin {

  late GameEngine gameEngine;

  GameChip? _emphasiseAllChipsOf;
  Role? _emphasiseAllChipsOfRole;
  bool _gameOverShown = false;
  Coordinate? _dragStartedAt;
  Coordinate? _validDragTarget;
  GameChip? _draggingChip;

  late StreamSubscription<FGBGType> fgbgSubscription;

  final _chaosChipTooltip = "chaosChipTooltip";
  final _orderChipTooltip = "orderChipTooltip";
  final _stockChipToolTipKey = "stockChipToolTip";

  bool _changeAutoPlayLock = false;

  late Animation<double> cellDropAnimation;
  late Animation<AlignmentGeometry> cellTopToBottomMoveAnimation;
  late Animation<AlignmentGeometry> cellBottomToTopMoveAnimation;
  late Animation<AlignmentGeometry> cellLeftToRightMoveAnimation;
  late Animation<AlignmentGeometry> cellRightToLeftMoveAnimation;
  late AnimationController cellAnimationController;

  AppLocalizations get l10n => AppLocalizations.of(context)!;


  @override
  void initState() {
    super.initState();

    _changeAutoPlayLock = false;

    SmartDialog.dismiss(); // dismiss loading dialog


    if (widget.play.multiPlay) {
      gameEngine = MultiPlayerGameEngine(
          widget.play,
          widget.user,
          () => context,
              () {
            if (!_gameOverShown) {
              (gameEngine as MultiPlayerGameEngine).shareGameMove(false);
              _gameOverShown = true;
            }
          }
      );
    }
    else {
      gameEngine = SinglePlayerGameEngine(
          widget.play,
          widget.user,
          () => context,
              () {
            if (!_gameOverShown) {
              _showGameOver(context);
              _gameOverShown = true;
            }
          }
      );
    }


    fgbgSubscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.background) {
        // TODO could be removed, we save whenever we change the play
        gameEngine.savePlayState();
      }
    });

    gameEngine.addListener(_gameListener);


    // add animation

    cellAnimationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    cellAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {

        gameEngine.play.moveToAnimate = null;
        // setting state directly leads to stopping animations
        Future.delayed(Duration(milliseconds: 500), () => setState(() {}));
      }
    });

    cellDropAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween(begin: gameEngine.play.dimension > 9 ? 1.95 : gameEngine.play.dimension > 7 ? 1.75 : 1.25, end: 0.75), weight: 0.75),
      TweenSequenceItem<double>(tween: Tween(begin: 0.75, end: 1.0), weight: 0.25),
    ]).animate(CurvedAnimation(parent: cellAnimationController, curve: Curves.easeIn));

    cellTopToBottomMoveAnimation = Tween<AlignmentGeometry>(begin: AlignmentGeometry.topCenter, end: AlignmentGeometry.bottomCenter)
        .animate(CurvedAnimation(parent: cellAnimationController, curve: Curves.easeInOut));

    cellBottomToTopMoveAnimation = Tween<AlignmentGeometry>(begin: AlignmentGeometry.bottomCenter, end: AlignmentGeometry.topCenter)
        .animate(CurvedAnimation(parent: cellAnimationController, curve: Curves.easeInOut));

    cellLeftToRightMoveAnimation = Tween<AlignmentGeometry>(begin: AlignmentGeometry.centerLeft, end: AlignmentGeometry.centerRight)
        .animate(CurvedAnimation(parent: cellAnimationController, curve: Curves.easeInOut));

    cellRightToLeftMoveAnimation = Tween<AlignmentGeometry>(begin: AlignmentGeometry.centerRight, end: AlignmentGeometry.centerLeft)
        .animate(CurvedAnimation(parent: cellAnimationController, curve: Curves.easeInOut));


    // start game


    if (!gameEngine.play.automaticPlayPaused) {
      gameEngine.startGame();
    }

    if (widget.opponentMoveToApply != null) {
      gameEngine.opponentMoveReceived(widget.opponentMoveToApply!);
    }

    if (widget.loadHandler != null) {
      widget.loadHandler!();
    }
  }

  _gameListener() {
    if (mounted) {
      setState(() {
        debugPrint("update UI");
      });
      globalMultiPlayerMatchesKey.currentState?.playHeaderChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameBody();
  }

  @override
  void dispose() {
    cellAnimationController.dispose();
    gameEngine.pauseGame();
    gameEngine.removeListener(_gameListener);
    fgbgSubscription.cancel();

    super.dispose();
  }

  Widget _buildGameBody() {

    return WillPopScope(
      onWillPop: () async {
        await gameEngine.pauseGame(); //await to get the play saved to avoid race conditions
        Navigator.pop(super.context); // go to start page
        return true;
      },
      child: Scaffold(
                appBar: AppBar(
                  //automaticallyImplyLeading: false,
                  leadingWidth: 25,
                  title: GestureDetector(
                    onTap: () {
                      showAlertDialog(_getGameTitle(), icon: null);
                    },
                    onLongPress: () {
                      if (isDebug) {
                        final fullPlayAsUrl = gameEngine.getFullPlayAsUrl();
                        showAlertDialog(fullPlayAsUrl, icon: null);
                        debugPrint(fullPlayAsUrl);
                        debugPrint(fullPlayAsUrl.length.toString());
                      }
                    },
                    child: Text(
                      _getGameTitle(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                  actions: [
                    Visibility(
                      visible: _isUndoAllowed(),
                      child: IconButton(
                        icon: const Icon(Icons.undo_outlined),
                        onPressed: () async {
                          if (!_isUndoAllowed()) {
                            toastInfo(context, "Undo not possible here");
                            return;
                          }
                          else {
                            if (gameEngine.play.hasStaleMove) {
                              gameEngine.play.undoStaleMove();
                              gameEngine.play.selectionCursor.clear();
                              await gameEngine.savePlayState();
                              setState(() {});
                            }
                            else {
                              final recentRole = gameEngine.play.opponentRole
                                  .name;
                              final currentRole = gameEngine.play.currentRole
                                  .name;
                              var message = l10n.dialog_undoLastMove(
                                  recentRole);

                              if (gameEngine.play.isWithAiPlay &&
                                  gameEngine.play.journal.length > 1) {
                                message = l10n.dialog_undoLastTwoMoves(
                                    currentRole, recentRole);
                              }

                              ask(message, l10n, () async {
                                await gameEngine.undoLastMove();
                                setState(() {
                                  toastInfo(context, l10n.dialog_undoCompleted);
                                });
                              });
                            }
                          }



                        },
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isFullAutomaticPlay && !gameEngine.play.isGameOver(),
                      child: IconButton(
                        icon: Icon(gameEngine.play.automaticPlayPaused ? Icons.not_started : Icons.pause),
                        onPressed: () async {
                          if (_changeAutoPlayLock) {
                            // this doesn't help if a user clicks very often in a row on this button
                            debugPrint("Locked!");
                            return;
                          }
                          _changeAutoPlayLock = true;
                          if (gameEngine.play.automaticPlayPaused) {
                            gameEngine.startGame();
                            gameEngine.play.automaticPlayPaused = false;
                          }
                          else {
                            await gameEngine.pauseGame();
                            gameEngine.play.automaticPlayPaused = true;
                          }
                          setState(() {
                          });
                          Future.delayed(Duration(milliseconds: 900), () {
                            _changeAutoPlayLock = false;
                          });
                        },
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                              showDragHandle: true,
                              context: context,

                              builder: (BuildContext context) {

                                return SafeArea(
                                  child: StatefulBuilder(
                                    builder: (BuildContext context, setSheetState) {
                                  
                                      // TODO potential memory leak, this listener is never removed within an ongoing play
                                      gameEngine.addListener(() {
                                        if (context.mounted) {
                                          setSheetState((){});
                                        }
                                      });
                                  
                                      final elements = gameEngine.play.journal
                                          .indexed
                                          .map((e) => _buildJournalEvent(e))
                                          .toList()
                                          .reversed
                                          .toList();
                                  
                                      elements.add(const Text(""));
                                      elements.add(_buildJournalLineSeparator(context, l10n.gameState_gameStarted));
                                      if (gameEngine.play.isGameOver()) {
                                        elements.insert(0, _buildJournalLineSeparator(context, l10n.gameState_gameOver));
                                        elements.insert(1, const Text(""));
                                      }
                                      return Container(
                                        height: MediaQuery.sizeOf(context).height / 2,
                                        width: MediaQuery.sizeOf(context).width,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Center(
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Column(
                                                    children: elements,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );


                            },
                          );
                        },
                        icon: const Icon(Icons.history)),
                    Visibility(
                      visible: !gameEngine.play.isMultiplayerPlay,
                      child: IconButton(
                        icon: const Icon(Icons.restart_alt_outlined),
                        onPressed: () => {

                          ask(l10n.dialog_restartGame, l10n, () async {
                                await gameEngine.stopGame();
                                _gameOverShown = false;
                                _changeAutoPlayLock = false;
                                gameEngine.startGame();
                          })
                        },
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isMultiplayerPlay && gameEngine.play.waitForOpponent,
                      child: GestureDetector(
                        onLongPress: () => _showMultiPlayTestDialog(gameEngine.play.header, gameEngine.user),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            globalStartPageKey.currentState?.scanNextMove(forceShowAllOptions: false, header: gameEngine.play.header);
                          },
                          onLongPress: () {
                            globalStartPageKey.currentState?.scanNextMove(forceShowAllOptions: true, header: gameEngine.play.header);
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isMultiplayerPlay
                          && !gameEngine.play.waitForOpponent
                          && !gameEngine.play.isGameOver()
                          && gameEngine.play.currentRound > 1, // cannot give up in round 1
                      child: IconButton(
                        icon: const Icon(Icons.sentiment_dissatisfied_outlined),
                        onPressed: () {
                          ask(l10n.dialog_wantToResign, l10n, () async {
                            await gameEngine.resignGame();
                            setState(() {});
                          });
                        },
                      ),
                    ),
                    if (gameEngine.play.isMultiplayerPlay)
                      PopupMenuButton<int>(
                        onSelected: (item) {
                          if (item == 0) {
                            _showGameDetails(gameEngine.play, gameEngine.user);
                          }
                          else if (item == 1 && gameEngine.play.classicModeFirstMatrix != null) {
                            _showFirstGameOfClassicMode(
                                gameEngine.play.classicModeFirstMatrix!,
                                gameEngine.play.header.getLocalRoleForMultiPlay()!.opponentRole,
                                gameEngine.play.stats.classicModeFirstRoundOrderPoints!);
                          }
                          else if (item == 2 && gameEngine.play.header.isStateShareable()) {
                            MessageService().sendCurrentPlayState(
                                gameEngine.play.header, widget.user, () => context, true);
                          }
                          else if (item == 3) {
                            globalStartPageKey.currentState?.scanNextMove(
                                forceShowAllOptions: true,
                                header: gameEngine.play.header);
                          }
                          else if (item == 4) {
                            ask(l10n.matchMenu_redoLastMessageConfirmation, l10n, () async {
                              final latestSnapshot = await StorageService().loadPlayFromHeader(gameEngine.play.header, asSnapshot: true);
                              if (latestSnapshot != null) {
                                await StorageService().savePlay(latestSnapshot);
                                gameEngine.play = latestSnapshot;
                                setState(() {});
                                toastInfo(context, l10n.done);
                              }
                              else {
                                showAlertDialog("No last state to use to repair current state!");
                              }
                            }, icon: Icons.warning);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<int>(value: 0, child: Text(l10n.matchMenu_matchInfo)),
                          if (gameEngine.play.header.rolesSwapped == true
                              && gameEngine.play.classicModeFirstMatrix != null)
                            PopupMenuItem<int>(value: 1, child: Text(l10n.matchMenu_showFirstGame)),
                          if (gameEngine.play.header.isStateShareable() && gameEngine.play.header.props[HeaderProps.rememberMessageSending] != null)
                            PopupMenuItem<int>(value: 2, child: Text(l10n.matchMenu_showSendOptions)),
                          if (gameEngine.play.header.props[HeaderProps.rememberMessageReading] != null)
                            PopupMenuItem<int>(value: 3, child: Text(l10n.matchMenu_showReadingOptions)),
                          if (gameEngine.play.lastMoveFromJournal != null && !gameEngine.play.header.state.isFinal)
                            PopupMenuItem<int>(value: 4, child: Text(l10n.matchMenu_redoLastMessage)),
                        ],
                      ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0 - gameEngine.play.dimension),
                        child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildRoleIndicator(Role.Chaos, gameEngine.play.chaosPlayer, true),
                                    Column(children: [
                                      Text(l10n.gameHeader_roundOf(gameEngine.play.currentRound, gameEngine.play.maxRounds)),
                                      if (gameEngine.play.header.rolesSwapped != null)
                                        Text (gameEngine.play.header.rolesSwapped! ? l10n.gameHeader_rolesSwapped : l10n.playMode_classic,
                                          style: TextStyle(fontStyle: FontStyle.italic),),
                                    ]),
                                    _buildRoleIndicator(Role.Order, gameEngine.play.orderPlayer, false),
                                  ],
                                ),
                              ),
                              LinearProgressIndicator(
                                value: gameEngine.play.progress,
                                backgroundColor: Colors.brown[100],
                              ),
                              Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                    child: Center(
                                      child: GridView.builder(
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: gameEngine.play.stock.getTotalChipTypes(),
                                          ),
                                          itemBuilder: _buildChipStock,
                                          itemCount: gameEngine.play.stock.getTotalChipTypes(),
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics()),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                    height: 20,
                                    child: GridView.builder(
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: gameEngine.play.stock.getTotalChipTypes(),
                                        ),
                                        itemBuilder: _buildChipStockIndicator,
                                        itemCount: gameEngine.play.stock.getTotalChipTypes(),
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics()),
                                  ),
                                ],
                              ),
                              AspectRatio(
                                aspectRatio: 1,
                                child: _buildChipGrid(_buildBoardGrid),
                              ),
                  
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                                child: _buildHint(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 0, top: 0, right: 0, bottom: 16),
                                child: _buildSubmitButton(context),
                              ),
                            ]),
                      ),
                    ),
                  ),
                )),
    );

  }

  Container _buildJournalLineSeparator(BuildContext context, [String? text]) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Center(child: text != null
          ? Text("--------- $text ---------")
          : Text("------------------------------------")),
    );
  }

  Widget _buildChipGrid(NullableIndexedWidgetBuilder builder) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2.0)),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gameEngine.play.dimension,
          ),
          itemBuilder: builder,
          itemCount: gameEngine.play.maxRounds,
          physics: const NeverScrollableScrollPhysics()),
    );
  }

  String _getGameTitle() {

    return gameEngine.play.isMultiplayerPlay
                        ? gameEngine.play.header.getTitle(l10n)
                        : gameEngine.play.isFullAutomaticPlay
                          ? l10n.gameTitle_automatic
                          : gameEngine.play.isBothSidesSinglePlay
                            ? l10n.gameTitle_alternate
                            : l10n.gameTitle_againstComputer;
  }

  Widget _buildJournalEvent((int, Move) e) {
    final maxRound = gameEngine.play.maxRounds;
    final isClassic = gameEngine.play.header.playMode == PlayMode.Classic;

    var swapThreshold = (maxRound * 2) - 1;
    var isRoleSwap = isClassic && (e.$1 == swapThreshold);
    var isSecondGame = isClassic && (e.$1 >= swapThreshold);

    var idx = (e.$1+1)/2;
    var round = isSecondGame ? idx.floor() : idx.ceil();
    if (isSecondGame) {
      round = (round % maxRound) + 1;
    }

    final move = e.$2;
    final role = move.toRole();
    final localPlayer = gameEngine.play.getPlayerTypeOf(role);
    final opponentPlayer = gameEngine.play.getPlayerTypeOf(role.opponentRole);

    Widget row = _buildMoveLine(move, prefix: "${l10n.gameHeader_round(round)}): ",
        playerType: !gameEngine.play.isBothSidesSinglePlay
            ? (isClassic
              ? (gameEngine.play.header.rolesSwapped == true
                ? (isSecondGame ? localPlayer : opponentPlayer)
                : (isSecondGame ? opponentPlayer : localPlayer))
              : localPlayer)
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (move.toRole() == Role.Order) _buildJournalLineSeparator(context),
        row,
        if (isRoleSwap) Text(""),
        if (isRoleSwap) _buildJournalLineSeparator(context, l10n.gameHeader_rolesSwapped),
        if (isRoleSwap) Text(""),
      ]
    );
  }


  _showMultiPlayTestDialog(PlayHeader playHeader, User user) {
    if (isDebug) {
      SmartDialog.show(
          builder: (_) {
            return RemoteTestWidget(
              rootContext: context,
              playHeader: playHeader,
              localUser: user,
              messageHandler: (message) {
                globalStartPageKey.currentState?.handleReceivedMessage(
                    message.toUri());
              },
            );
          });
    }
  }



  Widget _buildMoveLine(Move move, {String? prefix, PlayerType? playerType}) {
    final eventLineString = move.toReadableStringWithChipPlaceholder(playerType, l10n);
    return _replaceWithChipIcon(prefix, eventLineString, move.chip);
  }

  Widget _replaceWithChipIcon(String? prefix, String text, GameChip? chip) {

    if (text.contains("{chip}") && chip != null) {
      final split = text.split("{chip}");
      final first = split[0];
      final second = split[1];

      return Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (prefix != null)
            Text(prefix),
          Text("${first}${chip.getChipName(l10n)} "),
          CircleAvatar(
              backgroundColor: _getChipColor(chip, null),
              maxRadius: 6,
          ),
          Text(second),
        ],
      );
    }
    else {
      return Wrap(alignment: WrapAlignment.start,
        children: [
          if (prefix != null)
            Text(prefix),
          Text(text),
        ],
      );
    }
  }



  bool _isUndoAllowed() => !gameEngine.isBoardLocked()
      && !gameEngine.play.isGameOver()
      && !gameEngine.play.isFullAutomaticPlay
      && !gameEngine.play.isMultiplayerPlay
      && (!gameEngine.play.isJournalEmpty || gameEngine.play.hasStaleMove);


  Widget _buildHint(BuildContext context) {
    if (gameEngine.play.isGameOver()) {
      return Text(_buildWinnerOrLooserText(),
          style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center);
    }
    else if (gameEngine.play.currentPlayer == PlayerType.LocalAi) {
      return _buildAiProgressText();
    }
    else if (gameEngine.play.header.state == PlayState.FirstGameFinished_WaitForOpponent) {
      return Text(l10n.gameState_firstGameFinishedOfTwo);
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return Text(l10n.gameState_waitingForRemoteOpponent(gameEngine.play.currentRole.name));
    }
    else {
      return _buildDoneText();
    }
  }

  String _buildWinnerOrLooserText() {

    final winnerRole = gameEngine.play.getWinnerRole();
    final looserRole = gameEngine.play.getLooserRole();
    final winnerPlayer = gameEngine.play.getWinnerPlayer();
    final looserPlayer = gameEngine.play.getLooserPlayer();

    if (gameEngine.play.isFullAutomaticPlay || gameEngine.play.isBothSidesSinglePlay) {
      return l10n.gameState_gameOverWinner(winnerRole.name);
    }
    else if (gameEngine.play.isWithAiPlay) {
      if (winnerPlayer == PlayerType.LocalUser) {
        return l10n.gameState_gameOverWinner("${winnerRole.name} (${winnerPlayer.getName(l10n)})");
      }
      else {
        return l10n.gameState_gameOverLooser("${looserRole.name} (${looserPlayer.getName(l10n)})");
      }
    }
    else if (gameEngine.play.isMultiplayerPlay) {
      var localRole = gameEngine.play.header.getLocalRoleForMultiPlay();

      if (gameEngine.play.header.state == PlayState.Resigned) {
        return l10n.gameState_gameOverYouResigned;
      }
      else if (gameEngine.play.header.state == PlayState.OpponentResigned) {
        return l10n.gameState_gameOverOpponentResigned;
      }

      if (winnerRole == localRole) {
        return l10n.gameState_gameOverWinner("${localRole!.name} (${winnerPlayer.getName(l10n)})");
      }
      else {
        return l10n.gameState_gameOverLooser("${localRole!.name} (${looserPlayer.getName(l10n)})");
      }
    }
    else {
      return "";
    }

  }

  String _buildLooserText() {

    final looserRole = gameEngine.play.getLooserRole();
    final looserPlayer = gameEngine.play.getLooserPlayer();

    return l10n.gameState_gameOverLooser("${looserRole.name} (${looserPlayer.getName(l10n)})");
  }

  Widget _buildAiProgressText() {
    if (gameEngine.play.automaticPlayPaused) {
      return Text(l10n.gameState_gamePaused);
    }
    final text = _buildAiProcessingText();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        text,
        const Text("  "),
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.butt,
            strokeWidth: 2,
            value: gameEngine.progressRatio,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
    ],);
  }

  Widget _buildSubmitButton(BuildContext context) {
    if (gameEngine.play.isGameOver()) {
      if (gameEngine.play.isMultiplayerPlay) {
        return Column(
          children: [
            if (gameEngine.play.getWinnerPlayer() != PlayerType.LocalUser && gameEngine.play.header.playMode == PlayMode.HyleX)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildFilledButton(context,
                    Icons.restart_alt,
                    l10n.submitButton_rematch,
                        () {

                      if (gameEngine.play.header.successorPlayId != null) {
                        showChoiceDialog(l10n.dialog_askForRematchAgain(toReadablePlayId(gameEngine.play.header.successorPlayId!)),
                            firstString: l10n.dialog_askAgain,
                            firstHandler: () {
                              globalStartPageKey.currentState?.inviteRemoteOpponentForRevenge(
                                  context,
                                  gameEngine.play.header.playSize,
                                  gameEngine.play.header.playMode,
                                  predecessorPlay: gameEngine.play.header
                              );
                            },
                            secondString: MaterialLocalizations.of(context).cancelButtonLabel,
                            secondHandler: () {  });
                      }
                      else {
                        globalStartPageKey.currentState?.inviteRemoteOpponentForRevenge(
                            context,
                            gameEngine.play.header.playSize,
                            gameEngine.play.header.playMode,
                            predecessorPlay: gameEngine.play.header
                        );
                      }

                    }),
              )
            ,
            if (gameEngine.play.header.isStateShareable())
              GestureDetector(
                onLongPress: () {
                  if (gameEngine is MultiPlayerGameEngine) {
                    (gameEngine as MultiPlayerGameEngine).shareGameMove(true);
                  }
                },
                child: buildOutlinedButton(
                    context,
                    Icons.near_me,
                    l10n.submitButton_shareAgain,
                        () {
                      if (gameEngine is MultiPlayerGameEngine) {
                        (gameEngine as MultiPlayerGameEngine).shareGameMove(false);
                      }
                    }
                ),
              ),
          ],
        );
      }
      else {
        return buildFilledButton(
            context,
            Icons.restart_alt,
            l10n.submitButton_restart,
            () async {
            await gameEngine.stopGame();
            _gameOverShown = false;
            _changeAutoPlayLock = false;
            gameEngine.startGame();
          });
      }
    }
    else if (gameEngine.play.currentPlayer == PlayerType.LocalUser) {
      if (gameEngine.play.header.state == PlayState.FirstGameFinished_ReadyToSwap) {
        return buildFilledButton(
            context,
            Icons.swap_horiz_outlined,
            l10n.submitButton_swapRoles,
                () {
              gameEngine.play.swapGameForClassicMode();
              gameEngine.savePlayState();
            },
        );
      }
      final isDirty = gameEngine.play.hasStaleMove;
      return buildFilledButton(
          context,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? Icons.redo
              : Icons.near_me,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? l10n.submitButton_skipMove
              : l10n.submitButton_submitMove,
          () {
            if (gameEngine.isBoardLocked()) {
              return;
            }
            if (gameEngine.play.isGameOver()) {
              return;
            }
            if (gameEngine.play.currentRole == Role.Chaos && !isDirty) {
              toastInfo(context, l10n.error_chaosHasToPlace);
              return;
            }

            final skipMove = !isDirty && gameEngine.play.currentRole == Role.Order;
            if (gameEngine.play.multiPlay && skipMove) {
              ask(l10n.dialog_skipMove, l10n, () async {
                gameEngine.play.applyStaleMove(Move.skipped());
                gameEngine.play.commitMove();
                gameEngine.nextPlayer();
              });
            }
            else {
              if (skipMove) {
                gameEngine.play.applyStaleMove(Move.skipped());
              }
              gameEngine.play.commitMove();
              gameEngine.nextPlayer();
            }
          },
        isBold: isDirty
      );
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return GestureDetector(
        onLongPress: () {
          if (gameEngine is MultiPlayerGameEngine) {
            (gameEngine as MultiPlayerGameEngine).shareGameMove(true);
          }
        },
        child: buildOutlinedButton(
            context,
            Icons.near_me,
            l10n.submitButton_shareAgain,
            () {
            if (gameEngine is MultiPlayerGameEngine) {
              (gameEngine as MultiPlayerGameEngine).shareGameMove(false);
            }
          }
        ),
      );
    }
    return Container();
  }

  Widget _buildDoneText() {
    Widget? lastMoveHint = null;

    final lastMove = gameEngine.play.lastMoveFromJournal;
    if (lastMove != null) {
      lastMoveHint = _buildMoveLine(lastMove);
    }

    var appendix = "";

    if (PreferenceService().showHints) {
      if (gameEngine.play.header.state ==
          PlayState.FirstGameFinished_ReadyToSwap) {
        appendix = "➤ ${l10n.hint_swapRoles}";
      }
      else if (gameEngine.play.currentRole == Role.Order) {
        appendix = "➤ ${l10n.hint_orderToMove}";
      }
      else if (gameEngine.play.currentRole == Role.Chaos) {
        appendix = "➤ ${l10n.hint_chaosToPlace("{chip}")}";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lastMoveHint != null)
          lastMoveHint,
        if (!gameEngine.play.isFullAutomaticPlay)
          _replaceWithChipIcon(null, appendix, gameEngine.play.currentChip)
      ],
    );

  }


  Widget _buildAiProcessingText() {
    if (gameEngine.play.currentRole == Role.Order) {
      return Text(l10n.gameState_waitingForPlayerToMove(gameEngine.play.currentRole.name));
    }
    else {
      return _replaceWithChipIcon(null,
          l10n.gameState_waitingForPlayerToPlace("{chip}", gameEngine.play.currentRole.name),
          gameEngine.play.currentChip);
    }
  }

  void _showGameOver(BuildContext context) {
    if (gameEngine.play.isBothSidesSinglePlay || gameEngine.play.isFullAutomaticPlay) {
      toastInfo(context, _buildWinnerOrLooserText());
    }
    else if (gameEngine.play.getWinnerPlayer() == PlayerType.LocalUser) {
      toastWon(context, _buildWinnerOrLooserText());
    }
    else {
      toastLost(context, _buildLooserText());
    }

  }

  Widget _buildRoleIndicator(Role role, PlayerType player, bool isLeftElseRight) {

    final isSelected = gameEngine.play.currentRole == role;
    final color = gameEngine.play.isGameOver()
        ? gameEngine.play.getWinnerRole() == role
          ? Colors.black
          : Colors.black
        : isSelected
          ? Colors.white
          : null;

    final backgroundColor = gameEngine.play.isGameOver() == true
        ? gameEngine.play.getWinnerRole() == role
        ? Colors.lightGreenAccent
        : Colors.redAccent
        : isSelected
        ? DIALOG_BG
        : null;

    var tooltipKey = role == Role.Chaos
        ? _chaosChipTooltip
        : _orderChipTooltip;
    final tooltipPrefix =
      gameEngine.play.isGameOver()
        ? gameEngine.play.getWinnerRole() == role
            ? l10n.winner
            : l10n.looser
        : isSelected
            ? l10n.gameHeader_currentPlayer
            : l10n.gameHeader_waitingPlayer;

    final secondLine = (role == Role.Chaos && gameEngine.play.header.playMode != PlayMode.Classic)
        ? "\n${l10n.gameHeader_chaosChipCount(gameEngine.play.getChaosPointsPerChip())}"
        : "";

    return SuperTooltip(
      controller: Tooltips().controlTooltip(tooltipKey),
      onShow: () => Tooltips().hideTooltipLater(tooltipKey),
      showBarrier: false,
      hideTooltipOnTap: true,
      content: Text(
        "$tooltipPrefix: ${player.getName(l10n)}$secondLine",
        softWrap: true,

        style: TextStyle(
          color: Colors.black,
        ),
      ),
      child: GestureDetector(
        onLongPressStart: (details) {
          setState(() {
            _emphasiseAllChipsOfRole = role;
          });
        },
        onLongPressEnd: (details) => {
          setState(() {
            _emphasiseAllChipsOfRole = null;
          })
        },
        child: buildRoleIndicator(role,
            playerType: player,
            gameEngine: gameEngine,
            isSelected: isSelected,
            color: color,
            backgroundColor: backgroundColor
        ),
      ),
    );
  }

  Widget _buildBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % gameEngine.play.matrix.dimension.x);
    y = (index / gameEngine.play.matrix.dimension.y).floor();

    final where = Coordinate(x, y);
    final spot = gameEngine.play.matrix.getSpot(where);
    final chip = spot.content;


    return GestureDetector(
      onTap: () {
        _gridItemTapped(context, where);
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(80), width: 0.5),
          ),
          child: _buildDroppableCell(where, chip),
        ),
      ),
    );
  }

  Widget _buildDroppableCell(
      Coordinate where,
      GameChip? chip) {
    if (gameEngine.isBoardLocked()) {
      return _buildWrappedChip(where);
    }
    debugPrint("_validDragTarget=$_validDragTarget _draggingChip=$_draggingChip _dragStartedAt=$_dragStartedAt");
    return Container(
      color: _validDragTarget == where
          ? _draggingChip?.color.withAlpha(gameEngine.play.currentRole == Role.Order ? 140 : 100)
          : null,
      child: DragTarget<Coordinate>(
        onMove: (details) {
          if (gameEngine.play.currentRole == Role.Order) {
            if (_validDragTarget != where
                && chip == null
                && (gameEngine.play.selectionCursor.trace.contains(where) || gameEngine.play.selectionCursor.start == where)) {
              setState(() {
                _validDragTarget = where;
              });
            }
          }
          else {
            if (_validDragTarget != where && chip == null) {
              setState(() {
                _validDragTarget = where;
              });
            }
          }
        },
        onLeave: (details) {
          setState(() {
            _validDragTarget = null;
          });
        },
        builder: (BuildContext context, List<Object?> candidateData, List<dynamic> rejectedData) {
          return chip != null && _isChipDraggableForRole(where, chip)
              ? _buildDraggableChip(where, chip)
              : _buildWrappedChip(where);
        }),
    );
  }

  Widget _buildDraggableChip(
      Coordinate where,
      GameChip chip) {

    return LayoutBuilder(
      builder: (context, constraints) {
        return LongPressDraggable<Coordinate>(
          maxSimultaneousDrags: 1,
          data: where,
          hitTestBehavior: HitTestBehavior.translucent,
          onDragStarted: () {
            if (gameEngine.play.currentRole == Role.Chaos) {
              _handleOccupiedFieldForChaos(where, context);
            }
            else if (gameEngine.play.currentRole == Role.Order) {
              if (gameEngine.play.selectionCursor.start != where) {
                _handleOccupiedFieldForOrder(where, context);
              }
            }
            debugPrint("Start to drag $where $chip");

            setState(() {
              _dragStartedAt = where;
              _draggingChip = chip;
              _validDragTarget = null;
            });
          },
          onDragCompleted: () {
            debugPrint("onDragCompleted");

            bool dropAllowed = false;
            if (_validDragTarget != null) {
              final chipOnTarget = gameEngine.play.matrix.getChip(_validDragTarget!);
              if (gameEngine.play.currentRole == Role.Chaos) {
                if (chipOnTarget == null) {
                  dropAllowed = _handleFreeFieldForChaos(context, _validDragTarget!, false);
                }
                else {
                  dropAllowed = _handleOccupiedFieldForChaos(_validDragTarget!, context);
                }
              }
              else if (gameEngine.play.currentRole == Role.Order) {
                if (chipOnTarget == null) {
                  dropAllowed = _handleFreeFieldForOrder(context, _validDragTarget!, false);
                }
                else {
                  dropAllowed = _handleOccupiedFieldForOrder(_validDragTarget!, context);
                }
              }
            }
            else if (_validDragTarget == null && _dragStartedAt != null) {
              // undo dragging
              debugPrint("undo dragging to $_dragStartedAt");

              if (gameEngine.play.currentRole == Role.Chaos) {
                dropAllowed = _handleFreeFieldForChaos(context, _dragStartedAt!, false);
              }
              else if (gameEngine.play.currentRole == Role.Order) {
                dropAllowed = _handleFreeFieldForOrder(context, _dragStartedAt!, false);
              }
            }
            debugPrint("dropAllowed=$dropAllowed _dragStartedAt=$_dragStartedAt _dragTarget=$_validDragTarget");

            if (dropAllowed) {
              setState(() {
                _dragStartedAt = null;
                _validDragTarget = null;
                _draggingChip = null;
              });
            }
          },
          onDraggableCanceled: (_,__) {
            debugPrint("onDragCancelled");

            if (_dragStartedAt != null) {
              // undo dragging
              debugPrint("undo dragging due to cancel");

              if (gameEngine.play.currentRole == Role.Chaos) {
                // do nothing, swiped out
              }
              else if (gameEngine.play.currentRole == Role.Order) {
                _handleFreeFieldForOrder(context, _dragStartedAt!, false);
                _handleOccupiedFieldForOrder(_dragStartedAt!, context);
              }
            }

            setState(() {
              _dragStartedAt = null;
              _validDragTarget = null;
              _draggingChip = null;
            });
          },
          delay: Duration(milliseconds: 150),
          feedback: SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: buildGameChip("", chipColor: chip.color.withAlpha(255), dimension: gameEngine.play.dimension)
          ),
          child: Center(
            child: _buildWrappedChip(where),
          ),
        );
      }
    );
  }

  bool _isChipDraggableForRole(Coordinate where, GameChip chip) {
    if (gameEngine.play.currentRole == Role.Order) {
      return !gameEngine.play.hasStaleMove || where == gameEngine.play.staleMove?.to;
    }
    else { // Chaos
      return where == gameEngine.play.staleMove?.to;
    }
  }

  Center _buildWrappedChip(Coordinate where) {
    return Center(
        child: _wrapLastMove(_buildGridItem(where), where));
  }


  Widget _buildReadOnlyBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % gameEngine.play.matrix.dimension.x);
    y = (index / gameEngine.play.matrix.dimension.y).floor();
    final where = Coordinate(x, y);
    final chip = gameEngine.play.classicModeFirstMatrix!.getChip(where);
    final points = gameEngine.play.classicModeFirstMatrix!.getPoints(where);
    return GestureDetector(
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(80), width: 0.5)),
          child: Center(
            child: buildGameChip(
              points > 0 && PreferenceService().showPoints ? points.toString() : "",
              chipColor: chip != null ? _getChipColor(chip, where): null,
              dimension: gameEngine.play.dimension,
              showCoordinates: PreferenceService().showCoordinates,
              where: where,
            )
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(Coordinate where) {

    final spot = gameEngine.play.matrix.getSpot(where);
    final chip = spot.content;

    var pointText = spot.orderPoints > 0 && PreferenceService().showPoints ? spot.orderPoints.toString() : "";

    if (_emphasiseAllChipsOfRole == Role.Chaos) {
      if (chip != null && spot.orderPoints == 0 && gameEngine.play.header.playMode != PlayMode.Classic) {
        pointText = gameEngine.play.getChaosPointsPerChip().toString();
      }
      else {
        pointText = "";
      }
    }
    else if (_emphasiseAllChipsOfRole == Role.Order) {
      pointText = spot.orderPoints > 0 ? spot.orderPoints.toString() : "";
    }


    if (gameEngine.play.selectionCursor.end == where && !cellAnimationController.isAnimating) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (gameEngine.play.selectionCursor.start == where && !cellAnimationController.isAnimating) {
      return DottedBorder(
        options: RectDottedBorderOptions(
          dashPattern: const [2,4]),
        child: _buildChip(chip, pointText, where),
      );
    }
    return _buildChip(chip, pointText, where);

  }

  Widget _buildChip(GameChip? chip, String text, [Coordinate? where, BoxConstraints? constraints]) {

    bool possibleTarget = false;
    Spot? startSpot;
    if (gameEngine.play.currentRole == Role.Order && where != null) {
      var selectionCursor = gameEngine.play.selectionCursor;
      possibleTarget = selectionCursor.hasStart && selectionCursor.trace.contains(where);

      if (selectionCursor.hasEnd) {
        startSpot = gameEngine.play.matrix.getSpot(selectionCursor.end!);
      }
      else if (selectionCursor.hasStart) {
        startSpot = gameEngine.play.matrix.getSpot(selectionCursor.start!);
      }
    }


    // show trace of opponent move
    var opponentCursor = gameEngine.play.opponentCursor;
    if (startSpot == null && opponentCursor.hasEnd && where != null) {
      startSpot ??= gameEngine.play.matrix.getSpot(opponentCursor.end!);
      possibleTarget |= opponentCursor.trace.contains(where);
    }

    var shadedColor = startSpot?.content?.color.withOpacity(0.2);

    Move? moveToAnimate = null;
    if (where != null && gameEngine.play.moveToAnimate?.to == where) {
      moveToAnimate = gameEngine.play.moveToAnimate;
      cellAnimationController.reset();
      cellAnimationController.forward();
      debugPrint("Start animation at $moveToAnimate");

    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return buildGameChip(gameEngine.play.moveToAnimate?.to == where && cellAnimationController.isAnimating ? "" : text,
            chipColor: _dragStartedAt == where && _draggingChip != null
                ? _draggingChip!.color.withAlpha(20)
                : chip != null ? _getChipColor(chip, where): null,
            backgroundColor: possibleTarget ? shadedColor : null,
            dimension: gameEngine.play.dimension,
            showCoordinates: PreferenceService().showCoordinates,
            where: where,
            onLongPressStart: where == null ? (details) {
              setState(() {
                _emphasiseAllChipsOf = chip;
              });
            } : null,
            onLongPressEnd: where == null ? (details) => {
              setState(() {
                _emphasiseAllChipsOf = null;
              })
            } : null,
            animationController: PreferenceService().animateMoves ? cellAnimationController : null,
            moveToAnimate: moveToAnimate,
            cellAnimation: moveToAnimate?.isPlaced() == true
                ? cellDropAnimation
                : moveToAnimate?.isLeftToRightMove() == true
                ?  cellLeftToRightMoveAnimation
                : moveToAnimate?.isRightToLeftMove() == true
                ?  cellRightToLeftMoveAnimation
                : moveToAnimate?.isTopToBottomMove() == true
                ?  cellTopToBottomMoveAnimation
                : moveToAnimate?.isBottomToTopMove() == true
                ?  cellBottomToTopMoveAnimation
                : null,
            cellSize: constraints.maxHeight,
        );
      }
    );
  }

  Color _getChipColor(GameChip chip, Coordinate? considerPointsAt) {
    Role? roleAtPos = null;
    if (_emphasiseAllChipsOfRole != null && considerPointsAt != null) {
      final points = gameEngine.play.matrix.getPoints(considerPointsAt);
      roleAtPos = points == 0 ? Role.Chaos : Role.Order;
    }
    return ((_emphasiseAllChipsOf != null && _emphasiseAllChipsOf != chip)
        || (roleAtPos != null && _emphasiseAllChipsOfRole != roleAtPos))
        ? chip.color.withOpacity(0.2)
        : chip.color;
  }


  Future<void> _gridItemTapped(BuildContext context, Coordinate where) async {

    if (gameEngine.isBoardLocked() || _dragStartedAt != null || _draggingChip != null) {
      return;
    }

    setState(() {
      if (gameEngine.play.currentRole == Role.Chaos) {
        if (gameEngine.play.matrix.isFree(where)) {
          _handleFreeFieldForChaos(context, where, true);
        }
        else {
          _handleOccupiedFieldForChaos(where, context);
        }
      }
      if (gameEngine.play.currentRole == Role.Order) {
        if (gameEngine.play.matrix.isFree(where)) {
          _handleFreeFieldForOrder(context, where, true);
        }
        else {
          _handleOccupiedFieldForOrder(where, context);
        }
      }
    });
  }

  bool _handleFreeFieldForChaos(BuildContext context, Coordinate coordinate, bool animate) {
    final cursor = gameEngine.play.selectionCursor;
    if (cursor.end != null && !gameEngine.play.matrix.isFree(cursor.end!)) {
      if (PreferenceService().showChipErrors) {
        toastInfo(context, l10n.error_chaosAlreadyPlaced);
      }
      return false;
    }
    else {
      final currentChip = gameEngine.play.currentChip!;
      if (!gameEngine.play.stock.hasStock(currentChip)) {
        if (PreferenceService().showChipErrors) {
          toastInfo(context, l10n.error_noMoreStock);
        }
        return false;
      }
      gameEngine.play.applyStaleMove(Move.placed(currentChip, coordinate), animate: animate);
      gameEngine.play.selectionCursor.updateEnd(coordinate);
    }
    return true;
  }

  bool _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = gameEngine.play.selectionCursor;
    if (cursor.end != coordinate) {
      if (PreferenceService().showChipErrors) {
        toastInfo(context, l10n.error_onlyRemoveRecentlyPlacedChip);
      }
      return false;
    }
    else {
      gameEngine.play.undoStaleMove();
      gameEngine.play.selectionCursor.clear();
    }
    return true;
  }

  bool _handleFreeFieldForOrder(BuildContext context, Coordinate coordinate, bool animate) {
    final selectionCursor = gameEngine.play.selectionCursor;
    if (!selectionCursor.hasStart) {
      if (PreferenceService().showChipErrors) {
        toastInfo(context, l10n.error_orderHasToSelectAChip);
      }
      return false;
    }
    else if (/*!cursor.hasEnd && */selectionCursor.start == coordinate) {
      // clear start cursor if not target is selected
      gameEngine.play.undoStaleMove();
      selectionCursor.clear();
    }
    else if (!selectionCursor.trace.contains(coordinate) && selectionCursor.start != coordinate) {
      if (PreferenceService().showChipErrors) {
        toastInfo(context, l10n.error_orderMoveInvalid);
      }
      return false;
    }
    else if (selectionCursor.hasStart) {
      if (selectionCursor.hasEnd) {
        final from = gameEngine.play.matrix.getSpot(selectionCursor.end!);
        Move? moveToAnimate = null;
        // this is a correction move, so undo last move and apply again below
        final staleMove = gameEngine.play.staleMove;
        gameEngine.play.undoStaleMove();
        if (animate && staleMove != null && (staleMove.to?.x == coordinate.x || staleMove.to?.y == coordinate.y)) {
          moveToAnimate = Move.moved(staleMove.chip!, staleMove.to!, coordinate);
        }
        gameEngine.play.applyStaleMove(Move.moved(from.content!, selectionCursor.start!, coordinate),
            animate: animate, moveToAnimate: moveToAnimate);
      }
      else {
        final from = gameEngine.play.matrix.getSpot(selectionCursor.start!);
        gameEngine.play.applyStaleMove(Move.moved(from.content!, selectionCursor.start!, coordinate), animate: animate);
      }

      if (selectionCursor.start == coordinate) {
        // move back to start is like a reset
        selectionCursor.clear();
      }
      else {
        selectionCursor.updateEnd(coordinate);
      }

    }
    return true;
  }

  bool _handleOccupiedFieldForOrder(Coordinate coordinate, BuildContext context) {
    final selectionCursor = gameEngine.play.selectionCursor;
    if (selectionCursor.start != null
        && selectionCursor.start != coordinate
        && selectionCursor.end != null) {
      if (selectionCursor.end == coordinate) {
        // click on same chip, do nothing
        return true;
      }
      if (PreferenceService().showChipErrors) {
        toastInfo(context, l10n.error_orderMoveOnOccupied);
      }
      return false;
    }
    else if (selectionCursor.start == coordinate) {
      selectionCursor.clear();
    }
    else {
      selectionCursor.updateStart(coordinate);
      selectionCursor.detectTraceForPossibleOrderMoves(coordinate, gameEngine.play.matrix);
    }
    return true;
  }

  Widget _buildChipStock(BuildContext context, int index) {

    final stockEntries = gameEngine.play.stock.getStockEntries();
    if (stockEntries.length <= index) {
      return const Text("?");
    }
    final entry = stockEntries.toList()[index];
    final isCurrent = gameEngine.play.currentChip == entry.chip;
    final chipText = isCurrent
        ? (gameEngine.play.currentRole == Role.Chaos
        ? l10n.gameHeader_drawnChip
        : l10n.gameHeader_recentlyPlacedChip)
        : l10n.gameHeader_chip;
    final text = gameEngine.play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";
    final tooltipKey = "$_stockChipToolTipKey-$index";
    return SuperTooltip(
        controller: Tooltips().controlTooltip(tooltipKey),
        onShow: () => Tooltips().hideTooltipLater(tooltipKey),
        showBarrier: false,
        hideTooltipOnTap: true,
        content: Text(
          "$chipText ${entry.chip.getChipName(l10n)}\n${entry.amount} ${l10n.left}",
          softWrap: true,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        child: _buildChipStockItem(entry, text));
  }

  Widget _buildChipStockIndicator(BuildContext context, int index) {
    final stockEntries = gameEngine.play.stock.getStockEntries();
    final entry = stockEntries.toList()[index];
    if (gameEngine.play.currentChip == entry.chip) {
      return const Align(
          alignment: Alignment.topCenter,
          child: Text("▲", style: TextStyle(fontSize: 16),));
    }
    else {
      return Container();
    }
  }

  Padding _buildChipStockItem(StockEntry entry, String text) {
    if (gameEngine.play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(gameEngine.play.dimension > 5 ? gameEngine.play.dimension > 7 ? 0 : 2 : 4),
        child: Container(
            decoration: BoxDecoration(
              color: _getChipColor(entry.chip, null),
              border: Border.all(width: 1),
              borderRadius: const BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            child: _buildChip(entry.chip, text)
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(gameEngine.play.dimension > 5 ? gameEngine.play.dimension > 7 ? 0 : 4 : 8),
      child: _buildChip(entry.chip, text),
    );
  }

  Widget _wrapLastMove(Widget widget, Coordinate where) {
    if (gameEngine.play.opponentCursor.hasStart && gameEngine.play.opponentCursor.start == where && !cellAnimationController.isAnimating) {
      return DottedBorder(
          options: CircularDottedBorderOptions(
            padding: EdgeInsets.zero,
            strokeWidth: 1,
            strokeCap: StrokeCap.butt,
            color: Colors.grey
          ),
          child: widget);
    }
    else if (gameEngine.play.opponentCursor.hasEnd && gameEngine.play.opponentCursor.end == where && !cellAnimationController.isAnimating) {
      return DottedBorder(
          options: CircularDottedBorderOptions(
            padding: EdgeInsets.zero,
            strokeWidth: 3,
            strokeCap: StrokeCap.butt,
            color: Colors.grey
          ),
          child: widget);
    }
    return widget;
  }

  void _showGameDetails(Play play, User user) {

    final currentLocale = Localizations.localeOf(context);
    final languageCode = currentLocale.languageCode;

    SmartDialog.show(builder: (_) {
      List<Widget> children = [
        Text(
          l10n.matchMenu_matchInfo,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          play.header.getReadablePlayId(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const Divider(),
        _buildGameInfoRow(l10n.matchMenu_gameMode, play.header.playMode.getName(l10n)),
        if (play.header.playMode == PlayMode.Classic)
          _buildGameInfoRow(l10n.matchMenu_gameInMatch, play.header.rolesSwapped == true
              ? l10n.matchMenu_gameInMatchSecond
              : l10n.matchMenu_gameInMatchFirst),
        _buildGameInfoRow(l10n.matchMenu_gameSize, "${play.header.playSize.dimension} x ${play.header.playSize.dimension}"),
        _buildGameInfoRow(l10n.matchMenu_gameOpener, "${play.header.getLocalRoleForMultiPlay() == Role.Chaos ? PlayerType.LocalUser.getName(l10n): PlayerType.RemoteUser.getName(l10n)}"),
        if (play.header.playMode == PlayMode.HyleX)
          _buildGameInfoRow(l10n.matchMenu_pointsPerUnorderedChip, play.getChaosPointsPerChip().toString()),

        if (play.header.opponentName != null && play.header.opponentId != null)
          const Divider(),

        if (play.header.opponentName != null)
          _buildGameInfoRow(PlayerType.RemoteUser.getName(l10n), play.header.opponentName!),
        if (play.header.opponentId != null)
          _buildGameInfoRow("${PlayerType.RemoteUser.getName(l10n)} Id", toReadableUserId(play.header.opponentId!)),


        const Divider(),


        _buildGameInfoRow(l10n.matchMenu_startedAt, format(play.startDate, l10n, languageCode)),
        if (play.header.lastTimestamp != null)
          _buildGameInfoRow(l10n.matchMenu_lastActivity, format(play.header.lastTimestamp!, l10n, languageCode)),
        if (play.endDate != null  && play.header.state.isFinal)
          _buildGameInfoRow(l10n.matchMenu_finishedAt, format(play.endDate!, l10n, languageCode)),
        if (play.header.state.toMessage(l10n).length > 20)
          _buildGameInfoWrap(l10n.matchMenu_status, play.header.state.toMessage(l10n))
        else
          _buildGameInfoRow(l10n.matchMenu_status, play.header.state.toMessage(l10n)),

      ];


      return Container(
        height: 500,
        width: 330,
        decoration: BoxDecoration(
          color: DIALOG_BG,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        ),
      );
    });
  }

  Widget _buildGameInfoRow(String key, String value) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key + ":",
            style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      );
  }


  Widget _buildGameInfoWrap(String key, String value) {
    return Wrap(
      children: [
        Text(key + ":  ",
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  void _showFirstGameOfClassicMode(Matrix matrix, Role localRole, int orderPoints) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      isScrollControlled: true,

      builder: (BuildContext context) {

        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, setSheetState) {
          
              final chaosPlayerType = localRole == Role.Chaos ? PlayerType.LocalUser : PlayerType.RemoteUser;
              final orderPlayerType = localRole == Role.Chaos ? PlayerType.RemoteUser : PlayerType.LocalUser;
              return Container(
                height: MediaQuery.sizeOf(context).height / 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column(children: [
                        Text(l10n.gameState_firstGameState),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          buildRoleIndicator(Role.Chaos, playerType: chaosPlayerType, isSelected: false, backgroundColor: Colors.white),
                          buildRoleIndicator(Role.Order, playerType: orderPlayerType, isSelected: false, backgroundColor: Colors.white, points: orderPoints),
                        ],),
                        AspectRatio(aspectRatio: 1, child: _buildChipGrid(_buildReadOnlyBoardGrid))
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        );


      },
    );
  }


}

