import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}!'**
  String hello(Object name);

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @looser.
  ///
  /// In en, this message translates to:
  /// **'Looser'**
  String get looser;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @replyLater.
  ///
  /// In en, this message translates to:
  /// **'Replay later'**
  String get replyLater;

  /// No description provided for @as.
  ///
  /// In en, this message translates to:
  /// **'as'**
  String get as;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @startMenu_singlePlay.
  ///
  /// In en, this message translates to:
  /// **'Single Play'**
  String get startMenu_singlePlay;

  /// No description provided for @startMenu_multiPlay.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get startMenu_multiPlay;

  /// No description provided for @startMenu_newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get startMenu_newGame;

  /// No description provided for @startMenu_resumeGame.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get startMenu_resumeGame;

  /// No description provided for @startMenu_newMatch.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get startMenu_newMatch;

  /// No description provided for @startMenu_continueMatch.
  ///
  /// In en, this message translates to:
  /// **'Continue Match'**
  String get startMenu_continueMatch;

  /// No description provided for @startMenu_sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get startMenu_sendInvite;

  /// No description provided for @startMenu_scanCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Code'**
  String get startMenu_scanCode;

  /// No description provided for @startMenu_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get startMenu_more;

  /// No description provided for @startMenu_howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get startMenu_howToPlay;

  /// No description provided for @startMenu_achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get startMenu_achievements;

  /// No description provided for @achievements_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achievements_all;

  /// No description provided for @achievements_single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get achievements_single;

  /// No description provided for @achievements_multi.
  ///
  /// In en, this message translates to:
  /// **'Multiplay'**
  String get achievements_multi;

  /// No description provided for @achievements_overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get achievements_overall;

  /// No description provided for @achievements_totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total Count'**
  String get achievements_totalCount;

  /// No description provided for @achievements_totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get achievements_totalScore;

  /// No description provided for @achievements_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get achievements_high;

  /// No description provided for @achievements_won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get achievements_won;

  /// No description provided for @achievements_lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get achievements_lost;

  /// No description provided for @action_scanOrPasteMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan your opponent\'s QR code. If they sent you a message with an app link, and that link doesn\'t open this app, you can paste it here.'**
  String get action_scanOrPasteMessage;

  /// No description provided for @action_scanMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get action_scanMessage;

  /// No description provided for @action_scanMessageError.
  ///
  /// In en, this message translates to:
  /// **'Cannot read this QR code!'**
  String get action_scanMessageError;

  /// No description provided for @action_pasteMessage.
  ///
  /// In en, this message translates to:
  /// **'Paste message'**
  String get action_pasteMessage;

  /// No description provided for @action_pasteMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Paste opponent\'s message here. The app link will be automatically extracted.'**
  String get action_pasteMessageHere;

  /// No description provided for @action_pasteMessageError.
  ///
  /// In en, this message translates to:
  /// **'Cannot extract an app link out of this message!'**
  String get action_pasteMessageError;

  /// No description provided for @dialog_loadingGame.
  ///
  /// In en, this message translates to:
  /// **'Loading game ...'**
  String get dialog_loadingGame;

  /// No description provided for @dialog_initGame.
  ///
  /// In en, this message translates to:
  /// **'Initialising new game ...'**
  String get dialog_initGame;

  /// No description provided for @dialog_quitTheApp.
  ///
  /// In en, this message translates to:
  /// **'Do you want to close the app?'**
  String get dialog_quitTheApp;

  /// No description provided for @dialog_aboutDesc1.
  ///
  /// In en, this message translates to:
  /// **'An Entropy clone'**
  String get dialog_aboutDesc1;

  /// No description provided for @dialog_aboutDesc2.
  ///
  /// In en, this message translates to:
  /// **'Visit {homepage} to view the code, report bugs and give stars!'**
  String dialog_aboutDesc2(Object homepage);

  /// No description provided for @dialog_overwriteGame.
  ///
  /// In en, this message translates to:
  /// **'Starting a new game will delete an ongoing single game.'**
  String get dialog_overwriteGame;

  /// No description provided for @dialog_whichGroundSize.
  ///
  /// In en, this message translates to:
  /// **'What size playing field would you like to play on?'**
  String get dialog_whichGroundSize;

  /// No description provided for @dialog_groundSize5.
  ///
  /// In en, this message translates to:
  /// **'Beginners level, takes a couple of minutes'**
  String get dialog_groundSize5;

  /// No description provided for @dialog_groundSize7.
  ///
  /// In en, this message translates to:
  /// **'The original Entropy size'**
  String get dialog_groundSize7;

  /// No description provided for @dialog_groundSize9.
  ///
  /// In en, this message translates to:
  /// **'Enhanced size, if 7 x 7 is not enough'**
  String get dialog_groundSize9;

  /// No description provided for @dialog_groundSize11.
  ///
  /// In en, this message translates to:
  /// **'Professional and long ongoing game'**
  String get dialog_groundSize11;

  /// No description provided for @dialog_groundSize13.
  ///
  /// In en, this message translates to:
  /// **'Supreme size! Super hard!'**
  String get dialog_groundSize13;

  /// No description provided for @dialog_whatRole.
  ///
  /// In en, this message translates to:
  /// **'What role would you like to take on?'**
  String get dialog_whatRole;

  /// No description provided for @dialog_whatRoleOrder.
  ///
  /// In en, this message translates to:
  /// **'The computer is Chaos and starts the game.'**
  String get dialog_whatRoleOrder;

  /// No description provided for @dialog_whatRoleChaos.
  ///
  /// In en, this message translates to:
  /// **'The computer is Order, but you start the game.'**
  String get dialog_whatRoleChaos;

  /// No description provided for @dialog_whatRoleOrderForMultiPlay.
  ///
  /// In en, this message translates to:
  /// **'Your opponent is Chaos and starts the match.'**
  String get dialog_whatRoleOrderForMultiPlay;

  /// No description provided for @dialog_whatRoleChaosForMultiPlay.
  ///
  /// In en, this message translates to:
  /// **'Your opponent is Order, but you start the match.'**
  String get dialog_whatRoleChaosForMultiPlay;

  /// No description provided for @dialog_roleBoth.
  ///
  /// In en, this message translates to:
  /// **'Chaos and Order'**
  String get dialog_roleBoth;

  /// No description provided for @dialog_whatRoleBoth.
  ///
  /// In en, this message translates to:
  /// **'You play both roles, perhaps with a friend on the same device.'**
  String get dialog_whatRoleBoth;

  /// No description provided for @dialog_roleNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get dialog_roleNone;

  /// No description provided for @dialog_whatRoleNone.
  ///
  /// In en, this message translates to:
  /// **'The computer plays alone, you just observe.'**
  String get dialog_whatRoleNone;

  /// No description provided for @dialog_roleInviteeDecides.
  ///
  /// In en, this message translates to:
  /// **'Opponent decides'**
  String get dialog_roleInviteeDecides;

  /// No description provided for @dialog_whatRoleInviteeDecides.
  ///
  /// In en, this message translates to:
  /// **'Your opponent decide whether they is Order or Chaos, thus starting the game.'**
  String get dialog_whatRoleInviteeDecides;

  /// No description provided for @dialog_whatKindOfMatch.
  ///
  /// In en, this message translates to:
  /// **'What kind of match do you want to play?'**
  String get dialog_whatKindOfMatch;

  /// No description provided for @dialog_whatKindOfMatchHylexStyle.
  ///
  /// In en, this message translates to:
  /// **'Both Order and Chaos can score points. The player with the most points wins. The match ends after one game.'**
  String get dialog_whatKindOfMatchHylexStyle;

  /// No description provided for @dialog_whatKindOfMatchClassicStyle.
  ///
  /// In en, this message translates to:
  /// **'Only Order can score points. A match consists of two games. After the first game, the players swap roles. The player with the most points wins.'**
  String get dialog_whatKindOfMatchClassicStyle;

  /// No description provided for @dialog_whoToStart.
  ///
  /// In en, this message translates to:
  /// **'Who should start? Whoever starts is Chaos.'**
  String get dialog_whoToStart;

  /// No description provided for @dialog_whoToStartMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get dialog_whoToStartMe;

  /// No description provided for @dialog_whoToStartTheOther.
  ///
  /// In en, this message translates to:
  /// **'My opponent'**
  String get dialog_whoToStartTheOther;

  /// No description provided for @dialog_yourName.
  ///
  /// In en, this message translates to:
  /// **'What is your name? Your opponent will see this name. Please choose a short name.'**
  String get dialog_yourName;

  /// No description provided for @dialog_resetAchievements.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to reset all achievements to zero?'**
  String get dialog_resetAchievements;

  /// No description provided for @dialog_restartGame.
  ///
  /// In en, this message translates to:
  /// **'Do you want to restart this game? The current state will be lost.'**
  String get dialog_restartGame;

  /// No description provided for @dialog_skipMove.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to pass your move?'**
  String get dialog_skipMove;

  /// No description provided for @dialog_askForRematchAgain.
  ///
  /// In en, this message translates to:
  /// **'You already asked for a rematch, see {playId}.'**
  String dialog_askForRematchAgain(Object playId);

  /// No description provided for @dialog_askAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get dialog_askAgain;

  /// No description provided for @dialog_undoLastMove.
  ///
  /// In en, this message translates to:
  /// **'Do you want to undo the last move from {recentRole}?'**
  String dialog_undoLastMove(Object recentRole);

  /// No description provided for @dialog_undoLastTwoMoves.
  ///
  /// In en, this message translates to:
  /// **'Do you want to undo the last move from {recentRole}? This will also undo the previous move from {currentRole}.'**
  String dialog_undoLastTwoMoves(Object currentRole, Object recentRole);

  /// No description provided for @dialog_undoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Undo completed'**
  String get dialog_undoCompleted;

  /// No description provided for @dialog_wantToResign.
  ///
  /// In en, this message translates to:
  /// **'Do you want to give up? Then you will lose this game.'**
  String get dialog_wantToResign;

  /// No description provided for @dialog_deleteFinalMatch.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the match {playId}? This cannot be undone!'**
  String dialog_deleteFinalMatch(Object playId);

  /// No description provided for @dialog_deleteOngoingMatch.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the match {playId}? After removal, you will no longer be able to play it!'**
  String dialog_deleteOngoingMatch(Object playId);

  /// No description provided for @gameTitle_againstComputer.
  ///
  /// In en, this message translates to:
  /// **'Single Game'**
  String get gameTitle_againstComputer;

  /// No description provided for @gameTitle_alternate.
  ///
  /// In en, this message translates to:
  /// **'Alternating Single Game'**
  String get gameTitle_alternate;

  /// No description provided for @gameTitle_automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic Game'**
  String get gameTitle_automatic;

  /// No description provided for @gameTitle_playAgainstOpponent.
  ///
  /// In en, this message translates to:
  /// **'{playId} against {opponent}'**
  String gameTitle_playAgainstOpponent(Object opponent, Object playId);

  /// No description provided for @submitButton_submitMove.
  ///
  /// In en, this message translates to:
  /// **'Submit move'**
  String get submitButton_submitMove;

  /// No description provided for @submitButton_skipMove.
  ///
  /// In en, this message translates to:
  /// **'Skip move'**
  String get submitButton_skipMove;

  /// No description provided for @submitButton_shareAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get submitButton_shareAgain;

  /// No description provided for @submitButton_restart.
  ///
  /// In en, this message translates to:
  /// **'Restart game'**
  String get submitButton_restart;

  /// No description provided for @submitButton_swapRoles.
  ///
  /// In en, this message translates to:
  /// **'Swap roles and continue'**
  String get submitButton_swapRoles;

  /// No description provided for @submitButton_rematch.
  ///
  /// In en, this message translates to:
  /// **'Ask for a rematch'**
  String get submitButton_rematch;

  /// No description provided for @gameHeader_roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of {totalRounds}'**
  String gameHeader_roundOf(Object round, Object totalRounds);

  /// No description provided for @gameHeader_round.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String gameHeader_round(Object round);

  /// No description provided for @gameHeader_rolesSwapped.
  ///
  /// In en, this message translates to:
  /// **'Roles swapped'**
  String get gameHeader_rolesSwapped;

  /// No description provided for @gameHeader_currentPlayer.
  ///
  /// In en, this message translates to:
  /// **'Current player'**
  String get gameHeader_currentPlayer;

  /// No description provided for @gameHeader_waitingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Waiting player'**
  String get gameHeader_waitingPlayer;

  /// No description provided for @gameHeader_chaosChipCount.
  ///
  /// In en, this message translates to:
  /// **'One unordered chip counts {count}'**
  String gameHeader_chaosChipCount(Object count);

  /// No description provided for @gameHeader_drawnChip.
  ///
  /// In en, this message translates to:
  /// **'Drawn chip'**
  String get gameHeader_drawnChip;

  /// No description provided for @gameHeader_recentlyPlacedChip.
  ///
  /// In en, this message translates to:
  /// **'Recently placed chip'**
  String get gameHeader_recentlyPlacedChip;

  /// No description provided for @gameHeader_chip.
  ///
  /// In en, this message translates to:
  /// **'Chip'**
  String get gameHeader_chip;

  /// No description provided for @playMode_hylex.
  ///
  /// In en, this message translates to:
  /// **'HyleX Style'**
  String get playMode_hylex;

  /// No description provided for @playMode_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic Style'**
  String get playMode_classic;

  /// No description provided for @player_localUser.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get player_localUser;

  /// No description provided for @player_localAi.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get player_localAi;

  /// No description provided for @player_remoteUser.
  ///
  /// In en, this message translates to:
  /// **'Remote opponent'**
  String get player_remoteUser;

  /// No description provided for @move_placedChip.
  ///
  /// In en, this message translates to:
  /// **'{who} placed {chip} at {where}'**
  String move_placedChip(Object chip, Object where, Object who);

  /// No description provided for @move_movedChip.
  ///
  /// In en, this message translates to:
  /// **'{who} moved {chip} from {from} to {to}'**
  String move_movedChip(Object chip, Object from, Object to, Object who);

  /// No description provided for @move_skipped.
  ///
  /// In en, this message translates to:
  /// **'{who} skipped this move'**
  String move_skipped(Object who);

  /// No description provided for @color_red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get color_red;

  /// No description provided for @color_yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get color_yellow;

  /// No description provided for @color_green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get color_green;

  /// No description provided for @color_cyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get color_cyan;

  /// No description provided for @color_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get color_blue;

  /// No description provided for @color_pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get color_pink;

  /// No description provided for @color_grey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get color_grey;

  /// No description provided for @color_brown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get color_brown;

  /// No description provided for @color_olive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get color_olive;

  /// No description provided for @color_moss.
  ///
  /// In en, this message translates to:
  /// **'Moss'**
  String get color_moss;

  /// No description provided for @color_teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get color_teal;

  /// No description provided for @color_indigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get color_indigo;

  /// No description provided for @color_purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get color_purple;

  /// No description provided for @gameState_gameStarted.
  ///
  /// In en, this message translates to:
  /// **'Game started'**
  String get gameState_gameStarted;

  /// No description provided for @gameState_gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameState_gameOver;

  /// No description provided for @gameState_gameOverWinner.
  ///
  /// In en, this message translates to:
  /// **'Game over! {who} has won this game!'**
  String gameState_gameOverWinner(Object who);

  /// No description provided for @gameState_gameOverLooser.
  ///
  /// In en, this message translates to:
  /// **'Game over! {who} has lost this game!'**
  String gameState_gameOverLooser(Object who);

  /// No description provided for @gameState_gameOverOpponentResigned.
  ///
  /// In en, this message translates to:
  /// **'Game over! You have won this game, because your opponent gave up!'**
  String get gameState_gameOverOpponentResigned;

  /// No description provided for @gameState_gameOverYouResigned.
  ///
  /// In en, this message translates to:
  /// **'Game over! You have lost this game, because you gave up!'**
  String get gameState_gameOverYouResigned;

  /// No description provided for @gameState_waitingForRemoteOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for remote opponent\'s ({name}) turn ...'**
  String gameState_waitingForRemoteOpponent(Object name);

  /// No description provided for @gameState_waitingForPlayerToMove.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to move ...'**
  String gameState_waitingForPlayerToMove(Object name);

  /// No description provided for @gameState_waitingForPlayerToPlace.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to place {chip} ...'**
  String gameState_waitingForPlayerToPlace(Object chip, Object name);

  /// No description provided for @gameState_firstGameFinishedOfTwo.
  ///
  /// In en, this message translates to:
  /// **'The first game is finished, roles will be swapped, so the remote opponent becomes Chaos!'**
  String get gameState_firstGameFinishedOfTwo;

  /// No description provided for @gameState_firstGameState.
  ///
  /// In en, this message translates to:
  /// **'Result of the first game'**
  String get gameState_firstGameState;

  /// No description provided for @gameState_gamePaused.
  ///
  /// In en, this message translates to:
  /// **'Game paused'**
  String get gameState_gamePaused;

  /// No description provided for @hint_swapRoles.
  ///
  /// In en, this message translates to:
  /// **'First game of the match finished, time to swap role!'**
  String get hint_swapRoles;

  /// No description provided for @hint_orderToMove.
  ///
  /// In en, this message translates to:
  /// **'Now it\'s on Order to move a chip or skip!'**
  String get hint_orderToMove;

  /// No description provided for @hint_chaosToPlace.
  ///
  /// In en, this message translates to:
  /// **'Now it\'s on Chaos to place {chip} !'**
  String hint_chaosToPlace(Object chip);

  /// No description provided for @error_chaosHasToPlace.
  ///
  /// In en, this message translates to:
  /// **'Chaos must place a chip before proceeding!'**
  String get error_chaosHasToPlace;

  /// No description provided for @error_chaosAlreadyPlaced.
  ///
  /// In en, this message translates to:
  /// **'You have already placed a chip.'**
  String get error_chaosAlreadyPlaced;

  /// No description provided for @error_noMoreStock.
  ///
  /// In en, this message translates to:
  /// **'No more chips available.'**
  String get error_noMoreStock;

  /// No description provided for @error_onlyRemoveRecentlyPlacedChip.
  ///
  /// In en, this message translates to:
  /// **'You can only remove the most recently placed chip!'**
  String get error_onlyRemoveRecentlyPlacedChip;

  /// No description provided for @error_orderHasToSelectAChip.
  ///
  /// In en, this message translates to:
  /// **'Please select the chip you wish to move first.'**
  String get error_orderHasToSelectAChip;

  /// No description provided for @error_orderMoveInvalid.
  ///
  /// In en, this message translates to:
  /// **'The chip can only be moved horizontally or vertically through empty spaces.'**
  String get error_orderMoveInvalid;

  /// No description provided for @error_orderMoveOnOccupied.
  ///
  /// In en, this message translates to:
  /// **'You cannot move the selected chip to an occupied space.'**
  String get error_orderMoveOnOccupied;

  /// No description provided for @error_illegalCharsForUserName.
  ///
  /// In en, this message translates to:
  /// **'Your name may only consist of Latin letters, numbers, spaces and hyphens!'**
  String get error_illegalCharsForUserName;

  /// No description provided for @error_cannotExtractUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot extract a HyleX App-Link from shared text'**
  String get error_cannotExtractUrl;

  /// No description provided for @error_cannotParseUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot parse the given HyleX App-Link'**
  String get error_cannotParseUrl;

  /// No description provided for @error_alreadyReactedToInvite.
  ///
  /// In en, this message translates to:
  /// **'You already reacted to this invite. See {playId}.'**
  String error_alreadyReactedToInvite(Object playId);

  /// No description provided for @error_matchMotFound.
  ///
  /// In en, this message translates to:
  /// **'Game {playId} was not found or has already been removed.'**
  String error_matchMotFound(Object playId);

  /// No description provided for @error_matchAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'Game {playId} has already finished.'**
  String error_matchAlreadyFinished(Object playId);

  /// No description provided for @error_nothingToResume.
  ///
  /// In en, this message translates to:
  /// **'No ongoing single game that could be continued.'**
  String get error_nothingToResume;

  /// No description provided for @error_cannotReactToOwnInvitation.
  ///
  /// In en, this message translates to:
  /// **'This invitation was made by you, you cannot reply to it!'**
  String get error_cannotReactToOwnInvitation;

  /// No description provided for @error_cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan QR codes!'**
  String get error_cameraPermissionNeeded;

  /// No description provided for @error_linkAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This link has already been processed.'**
  String get error_linkAlreadyProcessed;

  /// No description provided for @error_linkIntendedForOpponent.
  ///
  /// In en, this message translates to:
  /// **'This link was intended for your opponent, not for you!'**
  String get error_linkIntendedForOpponent;

  /// No description provided for @error_linkIsNotTheLatest.
  ///
  /// In en, this message translates to:
  /// **'This link is not the latest of the match.'**
  String get error_linkIsNotTheLatest;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settings_commonSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get settings_commonSettings;

  /// No description provided for @settings_gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get settings_gameSettings;

  /// No description provided for @settings_showCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Show coordinates'**
  String get settings_showCoordinates;

  /// No description provided for @settings_showCoordinatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Show coordinates on the X and Y axes in the playing field.'**
  String get settings_showCoordinatesDescription;

  /// No description provided for @settings_showPointsForOrder.
  ///
  /// In en, this message translates to:
  /// **'Show points for Order'**
  String get settings_showPointsForOrder;

  /// No description provided for @settings_showPointsForOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows the points per chip that Order has achieved so far.'**
  String get settings_showPointsForOrderDescription;

  /// No description provided for @settings_showHints.
  ///
  /// In en, this message translates to:
  /// **'Show hints'**
  String get settings_showHints;

  /// No description provided for @settings_showHintsDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows hints that help guide what to do next in the game.'**
  String get settings_showHintsDescription;

  /// No description provided for @settings_showMoveErrors.
  ///
  /// In en, this message translates to:
  /// **'Show move errors'**
  String get settings_showMoveErrors;

  /// No description provided for @settings_showMoveErrorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows an error if chips are moved or placed incorrectly.'**
  String get settings_showMoveErrorsDescription;

  /// No description provided for @settings_multiplayerSettings.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer Settings'**
  String get settings_multiplayerSettings;

  /// No description provided for @settings_changeYourName.
  ///
  /// In en, this message translates to:
  /// **'Change your name \'{name}\''**
  String settings_changeYourName(Object name);

  /// No description provided for @settings_setYourName.
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get settings_setYourName;

  /// No description provided for @settings_setOrChangeYourNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Your name will be displayed in messages to your opponents.'**
  String get settings_setOrChangeYourNameDescription;

  /// No description provided for @settings_signMessages.
  ///
  /// In en, this message translates to:
  /// **'Sign messages'**
  String get settings_signMessages;

  /// No description provided for @settings_signMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Messages you send in multiplayer games are cryptographically signed.'**
  String get settings_signMessagesDescription;

  /// No description provided for @settings_signMessagesExplanation.
  ///
  /// In en, this message translates to:
  /// **'Sign your messages with your public key if you want to ensure that your messages are not tampered with and to prove that they come from you. This can be important if you share your moves with the public.'**
  String get settings_signMessagesExplanation;

  /// No description provided for @settings_signMessages_Never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settings_signMessages_Never;

  /// No description provided for @settings_signMessagesDescription_Never.
  ///
  /// In en, this message translates to:
  /// **'Messages will NOT be signed.'**
  String get settings_signMessagesDescription_Never;

  /// No description provided for @settings_signMessages_OnDemand.
  ///
  /// In en, this message translates to:
  /// **'On Request'**
  String get settings_signMessages_OnDemand;

  /// No description provided for @settings_signMessagesDescription_OnDemand.
  ///
  /// In en, this message translates to:
  /// **'Messages will only be signed when necessary and will be asked before each send.'**
  String get settings_signMessagesDescription_OnDemand;

  /// No description provided for @settings_signMessages_Always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settings_signMessages_Always;

  /// No description provided for @settings_signMessagesDescription_Always.
  ///
  /// In en, this message translates to:
  /// **'Messages will be signed without asking.'**
  String get settings_signMessagesDescription_Always;

  /// No description provided for @settings_backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get settings_backupAndRestore;

  /// No description provided for @settings_backupAll.
  ///
  /// In en, this message translates to:
  /// **'Back up everything to one file'**
  String get settings_backupAll;

  /// No description provided for @settings_backupAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Your player identity, all current and completed matches, and all achievements will be saved to a backup file.'**
  String get settings_backupAllDescription;

  /// No description provided for @settings_restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get settings_restoreFromFile;

  /// No description provided for @settings_restoreFromFileDescription.
  ///
  /// In en, this message translates to:
  /// **'For example, after reinstalling the app, you can import a previously created backup file.'**
  String get settings_restoreFromFileDescription;

  /// No description provided for @settings_restoreFromFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Restoring from a file will overwrite all current data! Continue?'**
  String get settings_restoreFromFileConfirmation;

  /// No description provided for @settings_sharePublicKey.
  ///
  /// In en, this message translates to:
  /// **'Share your public key'**
  String get settings_sharePublicKey;

  /// No description provided for @settings_sharePublicKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'When signing your messages, you may be required to share your public key with others.'**
  String get settings_sharePublicKeyDescription;

  /// No description provided for @settings_sharePublicKeyChooseFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose a format to share your public key:'**
  String get settings_sharePublicKeyChooseFormat;

  /// No description provided for @settings_sharePublicKeyChooseFormat_JWK.
  ///
  /// In en, this message translates to:
  /// **'In JWK format'**
  String get settings_sharePublicKeyChooseFormat_JWK;

  /// No description provided for @settings_sharePublicKeyChooseFormat_PEM.
  ///
  /// In en, this message translates to:
  /// **'In PEM format'**
  String get settings_sharePublicKeyChooseFormat_PEM;

  /// No description provided for @matchMenu_matchInfo.
  ///
  /// In en, this message translates to:
  /// **'Match info'**
  String get matchMenu_matchInfo;

  /// No description provided for @matchMenu_showFirstGame.
  ///
  /// In en, this message translates to:
  /// **'First game result'**
  String get matchMenu_showFirstGame;

  /// No description provided for @matchMenu_showSendOptions.
  ///
  /// In en, this message translates to:
  /// **'Send to opponent ..'**
  String get matchMenu_showSendOptions;

  /// No description provided for @matchMenu_showReadingOptions.
  ///
  /// In en, this message translates to:
  /// **'Read message from opponent ..'**
  String get matchMenu_showReadingOptions;

  /// No description provided for @matchMenu_redoLastMessage.
  ///
  /// In en, this message translates to:
  /// **'Repair match state ..'**
  String get matchMenu_redoLastMessage;

  /// No description provided for @matchMenu_redoLastMessageConfirmation.
  ///
  /// In en, this message translates to:
  /// **'If something went wrong and you cannot continue the match as expected, you can repair the current state here. When you continue it will revert your current but not yet sent move and the last move from your opponent, so you have to apply it again. Do you want to repair the state now?'**
  String get matchMenu_redoLastMessageConfirmation;

  /// No description provided for @matchMenu_gameMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get matchMenu_gameMode;

  /// No description provided for @matchMenu_gameInMatch.
  ///
  /// In en, this message translates to:
  /// **'Game in match'**
  String get matchMenu_gameInMatch;

  /// No description provided for @matchMenu_gameInMatchFirst.
  ///
  /// In en, this message translates to:
  /// **'First game'**
  String get matchMenu_gameInMatchFirst;

  /// No description provided for @matchMenu_gameInMatchSecond.
  ///
  /// In en, this message translates to:
  /// **'Second game'**
  String get matchMenu_gameInMatchSecond;

  /// No description provided for @matchMenu_gameSize.
  ///
  /// In en, this message translates to:
  /// **'Game size'**
  String get matchMenu_gameSize;

  /// No description provided for @matchMenu_gameOpener.
  ///
  /// In en, this message translates to:
  /// **'Game opener'**
  String get matchMenu_gameOpener;

  /// No description provided for @matchMenu_pointsPerUnorderedChip.
  ///
  /// In en, this message translates to:
  /// **'Points per unordered chip'**
  String get matchMenu_pointsPerUnorderedChip;

  /// No description provided for @matchMenu_startedAt.
  ///
  /// In en, this message translates to:
  /// **'Match started at'**
  String get matchMenu_startedAt;

  /// No description provided for @matchMenu_lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity at'**
  String get matchMenu_lastActivity;

  /// No description provided for @matchMenu_finishedAt.
  ///
  /// In en, this message translates to:
  /// **'Match finished at'**
  String get matchMenu_finishedAt;

  /// No description provided for @matchMenu_status.
  ///
  /// In en, this message translates to:
  /// **'Match state'**
  String get matchMenu_status;

  /// No description provided for @matchList_title.
  ///
  /// In en, this message translates to:
  /// **'Your Matches'**
  String get matchList_title;

  /// No description provided for @matchList_nothingFound.
  ///
  /// In en, this message translates to:
  /// **'No saved matches!'**
  String get matchList_nothingFound;

  /// No description provided for @matchList_errorDuringLoading.
  ///
  /// In en, this message translates to:
  /// **'Cannot load saved matches!'**
  String get matchList_errorDuringLoading;

  /// No description provided for @matchList_nothingToShare.
  ///
  /// In en, this message translates to:
  /// **'You must react to the last message first!'**
  String get matchList_nothingToShare;

  /// No description provided for @matchList_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort matches by'**
  String get matchList_sortBy;

  /// No description provided for @matchList_sortByCurrentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Match status'**
  String get matchList_sortByCurrentStatusTitle;

  /// No description provided for @matchList_sortByCurrentStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Sorted and grouped by Current Status'**
  String get matchList_sortByCurrentStatusDesc;

  /// No description provided for @matchList_sortByRecentlyPlayedTitle.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get matchList_sortByRecentlyPlayedTitle;

  /// No description provided for @matchList_sortByRecentlyPlayedDesc.
  ///
  /// In en, this message translates to:
  /// **'Most recently played match at the top'**
  String get matchList_sortByRecentlyPlayedDesc;

  /// No description provided for @matchList_sortByMatchIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Match ID'**
  String get matchList_sortByMatchIdTitle;

  /// No description provided for @matchList_sortByMatchIdDesc.
  ///
  /// In en, this message translates to:
  /// **'Alphabetically sorted by Match ID for faster match finding'**
  String get matchList_sortByMatchIdDesc;

  /// No description provided for @matchList_sortByOpponentTitle.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get matchList_sortByOpponentTitle;

  /// No description provided for @matchList_sortByOpponentDesc.
  ///
  /// In en, this message translates to:
  /// **'Alphabetically sorted and grouped by the opponent of the matches'**
  String get matchList_sortByOpponentDesc;

  /// No description provided for @matchListGroup_actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get matchListGroup_actionNeeded;

  /// No description provided for @matchListGroup_waitForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Wait for opponent'**
  String get matchListGroup_waitForOpponent;

  /// No description provided for @matchListGroup_wonMatches.
  ///
  /// In en, this message translates to:
  /// **'Won matches'**
  String get matchListGroup_wonMatches;

  /// No description provided for @matchListGroup_lostMatches.
  ///
  /// In en, this message translates to:
  /// **'Lost matches'**
  String get matchListGroup_lostMatches;

  /// No description provided for @matchListGroup_rejectedMatches.
  ///
  /// In en, this message translates to:
  /// **'Declined match invitations'**
  String get matchListGroup_rejectedMatches;

  /// No description provided for @messaging_sendYourMove.
  ///
  /// In en, this message translates to:
  /// **'Send your request or move to your opponent.'**
  String get messaging_sendYourMove;

  /// No description provided for @messaging_sendYourMoveAsMessage.
  ///
  /// In en, this message translates to:
  /// **'As message'**
  String get messaging_sendYourMoveAsMessage;

  /// No description provided for @messaging_sendYourMoveAsMessageInLanguage.
  ///
  /// In en, this message translates to:
  /// **'Used language: {language}'**
  String messaging_sendYourMoveAsMessageInLanguage(Object language);

  /// No description provided for @messaging_sendYourMoveAsQrCode.
  ///
  /// In en, this message translates to:
  /// **'As QR code'**
  String get messaging_sendYourMoveAsQrCode;

  /// No description provided for @messaging_rememberDecision.
  ///
  /// In en, this message translates to:
  /// **'Remember my decision for this match.'**
  String get messaging_rememberDecision;

  /// No description provided for @messaging_signMessages.
  ///
  /// In en, this message translates to:
  /// **'Sign my messages for this match.'**
  String get messaging_signMessages;

  /// No description provided for @messaging_scanQrCodeFromOpponent.
  ///
  /// In en, this message translates to:
  /// **'Let your opponent scan this QR code.'**
  String get messaging_scanQrCodeFromOpponent;

  /// No description provided for @messaging_scanQrCodeFromOpponentWithName.
  ///
  /// In en, this message translates to:
  /// **'Let your opponent {name} scan this QR code.'**
  String messaging_scanQrCodeFromOpponentWithName(Object name);

  /// No description provided for @messaging_opponentNeedsToReact.
  ///
  /// In en, this message translates to:
  /// **'Your opponent must respond to your last message first.'**
  String get messaging_opponentNeedsToReact;

  /// No description provided for @messaging_shareAgain.
  ///
  /// In en, this message translates to:
  /// **'Send message again'**
  String get messaging_shareAgain;

  /// No description provided for @messaging_invitationMessage_Invitor.
  ///
  /// In en, this message translates to:
  /// **'{opponent} has invited you to a {playMode} {dimension} x {dimension} match. You will play Order, so your opponent starts.'**
  String messaging_invitationMessage_Invitor(Object dimension, Object opponent, Object playMode);

  /// No description provided for @messaging_invitationMessage_Invitee.
  ///
  /// In en, this message translates to:
  /// **'{opponent} has invited you to a {playMode} {dimension} x {dimension} match. You will be Chaos, so you start.'**
  String messaging_invitationMessage_Invitee(Object dimension, Object opponent, Object playMode);

  /// No description provided for @messaging_invitationMessage_InviteeChooses.
  ///
  /// In en, this message translates to:
  /// **'{opponent} has invited you to a {playMode} {dimension} x {dimension} match. You can choose which role you want to play.'**
  String messaging_invitationMessage_InviteeChooses(Object dimension, Object opponent, Object playMode);

  /// No description provided for @messaging_matchAccepted.
  ///
  /// In en, this message translates to:
  /// **'The match {playId} has been accepted :)'**
  String messaging_matchAccepted(Object playId);

  /// No description provided for @messaging_matchDeclined.
  ///
  /// In en, this message translates to:
  /// **'The match {playId} has been declined :('**
  String messaging_matchDeclined(Object playId);

  /// No description provided for @messaging_opponentResigned.
  ///
  /// In en, this message translates to:
  /// **'Your opponent {opponent} has resigned from the match {playId}, you win!'**
  String messaging_opponentResigned(Object opponent, Object playId);

  /// No description provided for @messaging_inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'I ({name}) would like to invite you to a HyleX match. Click the link to reply to my invitation in the app (HyleX app required).'**
  String messaging_inviteMessage(Object dimension, Object name);

  /// No description provided for @messaging_inviteMessageWithoutName.
  ///
  /// In en, this message translates to:
  /// **'I would like to invite you to a HyleX match ({dimension}x{dimension}). Click the link to reply to my invitation in the app (HyleX app required).'**
  String messaging_inviteMessageWithoutName(Object dimension);

  /// No description provided for @messaging_acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'I accept your invitation. I will play {role}, you will play {opponentRole}.'**
  String messaging_acceptInvitation(Object opponentRole, Object role);

  /// No description provided for @messaging_rejectInvitation.
  ///
  /// In en, this message translates to:
  /// **'I\'m sorry, I have to decline your invitation. Maybe another time.'**
  String get messaging_rejectInvitation;

  /// No description provided for @messaging_nextMove.
  ///
  /// In en, this message translates to:
  /// **'This is my move for round {round} as {role}.'**
  String messaging_nextMove(Object role, Object round);

  /// No description provided for @messaging_resign.
  ///
  /// In en, this message translates to:
  /// **'Ugh, quite hard! I give up in round {round}.'**
  String messaging_resign(Object round);

  /// No description provided for @playState_initialised.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get playState_initialised;

  /// No description provided for @playState_remoteOpponentInvited.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get playState_remoteOpponentInvited;

  /// No description provided for @playState_invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Invitation awaiting response'**
  String get playState_invitationPending;

  /// No description provided for @playState_remoteOpponentAccepted_ReadyToMove.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted by opponent, please make your first move'**
  String get playState_remoteOpponentAccepted_ReadyToMove;

  /// No description provided for @playState_invitationAccepted_ReadyToMove.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted, please make the first move'**
  String get playState_invitationAccepted_ReadyToMove;

  /// No description provided for @playState_invitationAccepted_WaitForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted, wait for the opponent\'s first move'**
  String get playState_invitationAccepted_WaitForOpponent;

  /// No description provided for @playState_invitationRejected.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get playState_invitationRejected;

  /// No description provided for @playState_invitationRejectedByYou.
  ///
  /// In en, this message translates to:
  /// **'You declined the invitation'**
  String get playState_invitationRejectedByYou;

  /// No description provided for @playState_invitationRejectedByOpponent.
  ///
  /// In en, this message translates to:
  /// **'Your potential opponent declined your invitation'**
  String get playState_invitationRejectedByOpponent;

  /// No description provided for @playState_readyToMove.
  ///
  /// In en, this message translates to:
  /// **'It is your turn!'**
  String get playState_readyToMove;

  /// No description provided for @playState_waitForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Awaiting for opponent\'s move'**
  String get playState_waitForOpponent;

  /// No description provided for @playState_firstGameFinished_ReadyToSwap.
  ///
  /// In en, this message translates to:
  /// **'First game finished: It is your turn to start the second game!'**
  String get playState_firstGameFinished_ReadyToSwap;

  /// No description provided for @playState_firstGameFinished_WaitForOpponent.
  ///
  /// In en, this message translates to:
  /// **'First game finished: Wait for the opponent\'s first move for the second game'**
  String get playState_firstGameFinished_WaitForOpponent;

  /// No description provided for @playState_lost.
  ///
  /// In en, this message translates to:
  /// **'Match lost'**
  String get playState_lost;

  /// No description provided for @playState_won.
  ///
  /// In en, this message translates to:
  /// **'Match won'**
  String get playState_won;

  /// No description provided for @playState_resigned.
  ///
  /// In en, this message translates to:
  /// **'You gave up :('**
  String get playState_resigned;

  /// No description provided for @playState_opponentResigned.
  ///
  /// In en, this message translates to:
  /// **'Opponent gave up, you win'**
  String get playState_opponentResigned;

  /// No description provided for @playState_closed.
  ///
  /// In en, this message translates to:
  /// **'Match ended'**
  String get playState_closed;

  /// No description provided for @intro_page1Title.
  ///
  /// In en, this message translates to:
  /// **'The eternal fight between Chaos and Order'**
  String get intro_page1Title;

  /// No description provided for @intro_page1Part1.
  ///
  /// In en, this message translates to:
  /// **'One player creates Chaos .. '**
  String get intro_page1Part1;

  /// No description provided for @intro_page1Part2.
  ///
  /// In en, this message translates to:
  /// **' ..  the other counteracts as Order.'**
  String get intro_page1Part2;

  /// No description provided for @intro_page2Title.
  ///
  /// In en, this message translates to:
  /// **'The role of Chaos'**
  String get intro_page2Title;

  /// No description provided for @intro_page2Part1.
  ///
  /// In en, this message translates to:
  /// **'Chaos randomly draws chips from the stock and places them as chaotically as possible.'**
  String get intro_page2Part1;

  /// No description provided for @intro_page3Title.
  ///
  /// In en, this message translates to:
  /// **'The Role of Order'**
  String get intro_page3Title;

  /// No description provided for @intro_page3Part1.
  ///
  /// In en, this message translates to:
  /// **'Order tries to arrange the chips placed by Chaos into a horizontal or vertical symmetrical arrangement, so-called palindromes.'**
  String get intro_page3Part1;

  /// No description provided for @intro_page4Title.
  ///
  /// In en, this message translates to:
  /// **'The role of Order'**
  String get intro_page4Title;

  /// No description provided for @intro_page4Part1.
  ///
  /// In en, this message translates to:
  /// **'Order may slide any placed chip horizontally or vertically through empty cells. Order may also skip its current turn.'**
  String get intro_page4Part1;

  /// No description provided for @intro_page5Title.
  ///
  /// In en, this message translates to:
  /// **'End of the game'**
  String get intro_page5Title;

  /// No description provided for @intro_page5Part1.
  ///
  /// In en, this message translates to:
  /// **'Chaos receives points for each chip outside of a Palindrome  ..'**
  String get intro_page5Part1;

  /// No description provided for @intro_page5Part2.
  ///
  /// In en, this message translates to:
  /// **' ..  which is 20 points per chip in this example, so a total of 40.'**
  String get intro_page5Part2;

  /// No description provided for @intro_page6Title.
  ///
  /// In en, this message translates to:
  /// **'End of the game'**
  String get intro_page6Title;

  /// No description provided for @intro_page6Part1.
  ///
  /// In en, this message translates to:
  /// **'Order receives points for each chip that is part of a palindrome...'**
  String get intro_page6Part1;

  /// No description provided for @intro_page6Part2.
  ///
  /// In en, this message translates to:
  /// **'... which results in 6 points, since there are two palindromes (green-green and red-green-green-red).'**
  String get intro_page6Part2;

  /// No description provided for @intro_page7Title.
  ///
  /// In en, this message translates to:
  /// **'End of the game'**
  String get intro_page7Title;

  /// No description provided for @intro_page7Part1.
  ///
  /// In en, this message translates to:
  /// **'The game is over when all chips have been placed ..'**
  String get intro_page7Part1;

  /// No description provided for @intro_page7Part2.
  ///
  /// In en, this message translates to:
  /// **'.. and the player with the most points wins.'**
  String get intro_page7Part2;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
