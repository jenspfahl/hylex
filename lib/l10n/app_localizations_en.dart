// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ok => 'Ok';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get reset => 'Reset';

  @override
  String hello(Object name) {
    return 'Hello $name!';
  }

  @override
  String get winner => 'Winner';

  @override
  String get looser => 'Looser';

  @override
  String get left => 'left';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get replyLater => 'Replay later';

  @override
  String get as => 'as';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get today => 'Today';

  @override
  String get startMenu_singlePlay => 'Single Play';

  @override
  String get startMenu_multiPlay => 'Multiplayer';

  @override
  String get startMenu_newGame => 'New Game';

  @override
  String get startMenu_resumeGame => 'Resume';

  @override
  String get startMenu_newMatch => 'New Match';

  @override
  String get startMenu_continueMatch => 'Continue Match';

  @override
  String get startMenu_sendInvite => 'Send Invite';

  @override
  String get startMenu_scanCode => 'Scan Code';

  @override
  String get startMenu_more => 'More';

  @override
  String get startMenu_howToPlay => 'How to play';

  @override
  String get startMenu_achievements => 'Achievements';

  @override
  String get achievements_all => 'All';

  @override
  String get achievements_single => 'Single';

  @override
  String get achievements_multi => 'Multiplay';

  @override
  String get achievements_overall => 'Overall';

  @override
  String get achievements_totalCount => 'Total Count';

  @override
  String get achievements_totalScore => 'Total Score';

  @override
  String get achievements_high => 'High';

  @override
  String get achievements_won => 'Won';

  @override
  String get achievements_lost => 'Lost';

  @override
  String get action_scanOrPasteMessage => 'Scan your opponent\'s QR code. If they sent you a message with an app link, and that link doesn\'t open this app, you can paste it here.';

  @override
  String get action_scanMessage => 'Scan QR code';

  @override
  String get action_scanMessageError => 'Cannot read this QR code!';

  @override
  String get action_pasteMessage => 'Paste message';

  @override
  String get action_pasteMessageHere => 'Paste opponent\'s message here. The app link will be automatically extracted.';

  @override
  String get action_pasteMessageError => 'Cannot extract an app link out of this message!';

  @override
  String get dialog_loadingGame => 'Loading game ...';

  @override
  String get dialog_initGame => 'Initialising new game ...';

  @override
  String get dialog_quitTheApp => 'Do you want to close the app?';

  @override
  String get dialog_aboutDesc1 => 'An Entropy clone';

  @override
  String dialog_aboutDesc2(Object homepage) {
    return 'Visit $homepage to view the code, report bugs and give stars!';
  }

  @override
  String get dialog_overwriteGame => 'Starting a new game will delete an ongoing single game.';

  @override
  String get dialog_whichGroundSize => 'What size playing field would you like to play on?';

  @override
  String get dialog_groundSize5 => 'Beginners level, takes a couple of minutes';

  @override
  String get dialog_groundSize7 => 'The original Entropy size';

  @override
  String get dialog_groundSize9 => 'Enhanced size, if 7 x 7 is not enough';

  @override
  String get dialog_groundSize11 => 'Professional and long ongoing game';

  @override
  String get dialog_groundSize13 => 'Supreme size! Super hard!';

  @override
  String get dialog_whatRole => 'What role would you like to take on?';

  @override
  String get dialog_whatRoleOrder => 'The computer is Chaos and starts the game.';

  @override
  String get dialog_whatRoleChaos => 'The computer is Order, but you start the game.';

  @override
  String get dialog_whatRoleOrderForMultiPlay => 'Your opponent is Chaos and starts the match.';

  @override
  String get dialog_whatRoleChaosForMultiPlay => 'Your opponent is Order, but you start the match.';

  @override
  String get dialog_roleBoth => 'Chaos and Order';

  @override
  String get dialog_whatRoleBoth => 'You play both roles, perhaps with a friend on the same device.';

  @override
  String get dialog_roleNone => 'None';

  @override
  String get dialog_whatRoleNone => 'The computer plays alone, you just observe.';

  @override
  String get dialog_roleInviteeDecides => 'Opponent decides';

  @override
  String get dialog_whatRoleInviteeDecides => 'Your opponent decide whether they is Order or Chaos, thus starting the game.';

  @override
  String get dialog_whatKindOfMatch => 'What kind of match do you want to play?';

  @override
  String get dialog_whatKindOfMatchHylexStyle => 'Both Order and Chaos can score points. The player with the most points wins. The match ends after one game.';

  @override
  String get dialog_whatKindOfMatchClassicStyle => 'Only Order can score points. A match consists of two games. After the first game, the players swap roles. The player with the most points wins.';

  @override
  String get dialog_whoToStart => 'Who should start? Whoever starts is Chaos.';

  @override
  String get dialog_whoToStartMe => 'Me';

  @override
  String get dialog_whoToStartTheOther => 'My opponent';

  @override
  String get dialog_yourName => 'What is your name? Your opponent will see this name. Please choose a short name.';

  @override
  String get dialog_resetAchievements => 'Do you really want to reset all achievements to zero?';

  @override
  String get dialog_restartGame => 'Do you want to restart this game? The current state will be lost.';

  @override
  String get dialog_skipMove => 'Do you really want to pass your move?';

  @override
  String dialog_askForRematchAgain(Object playId) {
    return 'You already asked for a rematch, see $playId.';
  }

  @override
  String get dialog_askAgain => 'Ask again';

  @override
  String dialog_undoLastMove(Object recentRole) {
    return 'Do you want to undo the last move from $recentRole?';
  }

  @override
  String dialog_undoLastTwoMoves(Object currentRole, Object recentRole) {
    return 'Do you want to undo the last move from $recentRole? This will also undo the previous move from $currentRole.';
  }

  @override
  String get dialog_undoCompleted => 'Undo completed';

  @override
  String get dialog_wantToResign => 'Do you want to give up? Then you will lose this game.';

  @override
  String dialog_deleteFinalMatch(Object playId) {
    return 'Are you sure you want to remove the match $playId? This cannot be undone!';
  }

  @override
  String dialog_deleteOngoingMatch(Object playId) {
    return 'Are you sure you want to remove the match $playId? After removal, you will no longer be able to play it!';
  }

  @override
  String get gameTitle_againstComputer => 'Single Game';

  @override
  String get gameTitle_alternate => 'Alternating Single Game';

  @override
  String get gameTitle_automatic => 'Automatic Game';

  @override
  String gameTitle_playAgainstOpponent(Object opponent, Object playId) {
    return '$playId against $opponent';
  }

  @override
  String get submitButton_submitMove => 'Submit move';

  @override
  String get submitButton_skipMove => 'Skip move';

  @override
  String get submitButton_shareAgain => 'Send again';

  @override
  String get submitButton_restart => 'Restart game';

  @override
  String get submitButton_swapRoles => 'Swap roles and continue';

  @override
  String get submitButton_rematch => 'Ask for a rematch';

  @override
  String gameHeader_roundOf(Object round, Object totalRounds) {
    return 'Round $round of $totalRounds';
  }

  @override
  String gameHeader_round(Object round) {
    return 'Round $round';
  }

  @override
  String get gameHeader_rolesSwapped => 'Roles swapped';

  @override
  String get gameHeader_currentPlayer => 'Current player';

  @override
  String get gameHeader_waitingPlayer => 'Waiting player';

  @override
  String gameHeader_chaosChipCount(Object count) {
    return 'One unordered chip counts $count';
  }

  @override
  String get gameHeader_drawnChip => 'Drawn chip';

  @override
  String get gameHeader_recentlyPlacedChip => 'Recently placed chip';

  @override
  String get gameHeader_chip => 'Chip';

  @override
  String get playMode_hylex => 'HyleX Style';

  @override
  String get playMode_classic => 'Classic Style';

  @override
  String get player_localUser => 'You';

  @override
  String get player_localAi => 'Computer';

  @override
  String get player_remoteUser => 'Remote opponent';

  @override
  String move_placedChip(Object chip, Object where, Object who) {
    return '$who placed $chip at $where';
  }

  @override
  String move_movedChip(Object chip, Object from, Object to, Object who) {
    return '$who moved $chip from $from to $to';
  }

  @override
  String move_skipped(Object who) {
    return '$who skipped this move';
  }

  @override
  String get color_red => 'Red';

  @override
  String get color_yellow => 'Yellow';

  @override
  String get color_green => 'Green';

  @override
  String get color_cyan => 'Cyan';

  @override
  String get color_blue => 'Blue';

  @override
  String get color_pink => 'Pink';

  @override
  String get color_grey => 'Grey';

  @override
  String get color_brown => 'Brown';

  @override
  String get color_olive => 'Olive';

  @override
  String get color_moss => 'Moss';

  @override
  String get color_teal => 'Teal';

  @override
  String get color_indigo => 'Indigo';

  @override
  String get color_purple => 'Purple';

  @override
  String get gameState_gameStarted => 'Game started';

  @override
  String get gameState_gameOver => 'Game over';

  @override
  String gameState_gameOverWinner(Object who) {
    return 'Game over! $who has won this game!';
  }

  @override
  String gameState_gameOverLooser(Object who) {
    return 'Game over! $who has lost this game!';
  }

  @override
  String get gameState_gameOverOpponentResigned => 'Game over! You have won this game, because your opponent gave up!';

  @override
  String get gameState_gameOverYouResigned => 'Game over! You have lost this game, because you gave up!';

  @override
  String gameState_waitingForRemoteOpponent(Object name) {
    return 'Waiting for remote opponent\'s ($name) turn ...';
  }

  @override
  String gameState_waitingForPlayerToMove(Object name) {
    return 'Waiting for $name to move ...';
  }

  @override
  String gameState_waitingForPlayerToPlace(Object chip, Object name) {
    return 'Waiting for $name to place $chip ...';
  }

  @override
  String get gameState_firstGameFinishedOfTwo => 'The first game is finished, roles will be swapped, so the remote opponent becomes Chaos!';

  @override
  String get gameState_firstGameState => 'Result of the first game';

  @override
  String get gameState_gamePaused => 'Game paused';

  @override
  String get hint_swapRoles => 'First game of the match finished, time to swap role!';

  @override
  String get hint_orderToMove => 'Now it\'s on Order to move a chip or skip!';

  @override
  String hint_chaosToPlace(Object chip) {
    return 'Now it\'s on Chaos to place $chip !';
  }

  @override
  String get error_chaosHasToPlace => 'Chaos must place a chip before proceeding!';

  @override
  String get error_chaosAlreadyPlaced => 'You have already placed a chip.';

  @override
  String get error_noMoreStock => 'No more chips available.';

  @override
  String get error_onlyRemoveRecentlyPlacedChip => 'You can only remove the most recently placed chip!';

  @override
  String get error_orderHasToSelectAChip => 'Please select the chip you wish to move first.';

  @override
  String get error_orderMoveInvalid => 'The chip can only be moved horizontally or vertically through empty spaces.';

  @override
  String get error_orderMoveOnOccupied => 'You cannot move the selected chip to an occupied space.';

  @override
  String get error_illegalCharsForUserName => 'Your name may only consist of Latin letters, numbers, spaces and hyphens!';

  @override
  String get error_cannotExtractUrl => 'Cannot extract a HyleX App-Link from shared text';

  @override
  String get error_cannotParseUrl => 'Cannot parse the given HyleX App-Link';

  @override
  String error_alreadyReactedToInvite(Object playId) {
    return 'You already reacted to this invite. See $playId.';
  }

  @override
  String error_matchMotFound(Object playId) {
    return 'Game $playId was not found or has already been removed.';
  }

  @override
  String error_matchAlreadyFinished(Object playId) {
    return 'Game $playId has already finished.';
  }

  @override
  String get error_nothingToResume => 'No ongoing single game that could be continued.';

  @override
  String get error_cannotReactToOwnInvitation => 'This invitation was made by you, you cannot reply to it!';

  @override
  String get error_cameraPermissionNeeded => 'Camera permission is required to scan QR codes!';

  @override
  String get matchMenu_matchInfo => 'Match info';

  @override
  String get matchMenu_showFirstGame => 'First game result';

  @override
  String get matchMenu_showSendOptions => 'Send to opponent ..';

  @override
  String get matchMenu_showReadingOptions => 'Nachricht von Gegner lesen ..';

  @override
  String get matchMenu_gameMode => 'Mode';

  @override
  String get matchMenu_gameInMatch => 'Game in match';

  @override
  String get matchMenu_gameInMatchFirst => 'First game';

  @override
  String get matchMenu_gameInMatchSecond => 'Second game';

  @override
  String get matchMenu_gameSize => 'Game size';

  @override
  String get matchMenu_gameOpener => 'Game opener';

  @override
  String get matchMenu_pointsPerUnorderedChip => 'Points per unordered chip';

  @override
  String get matchMenu_startedAt => 'Match started at';

  @override
  String get matchMenu_lastActivity => 'Last activity at';

  @override
  String get matchMenu_finishedAt => 'Match finished at';

  @override
  String get matchMenu_status => 'Match state';

  @override
  String get matchList_title => 'Your Matches';

  @override
  String get matchList_nothingFound => 'No saved matches!';

  @override
  String get matchList_errorDuringLoading => 'Cannot load saved matches!';

  @override
  String get matchList_nothingToShare => 'You must react to the last message first!';

  @override
  String get matchList_sortBy => 'Sort matches by';

  @override
  String get matchList_sortByCurrentStatusTitle => 'Match status';

  @override
  String get matchList_sortByCurrentStatusDesc => 'Sorted and grouped by Current Status';

  @override
  String get matchList_sortByRecentlyPlayedTitle => 'Last played';

  @override
  String get matchList_sortByRecentlyPlayedDesc => 'Most recently played match at the top';

  @override
  String get matchList_sortByMatchIdTitle => 'Match ID';

  @override
  String get matchList_sortByMatchIdDesc => 'Alphabetically sorted by Match ID for faster match finding';

  @override
  String get matchListGroup_actionNeeded => 'Action required';

  @override
  String get matchListGroup_waitForOpponent => 'Wait for opponent';

  @override
  String get matchListGroup_wonMatches => 'Won matches';

  @override
  String get matchListGroup_lostMatches => 'Lost matches';

  @override
  String get matchListGroup_rejectedMatches => 'Declined match invitations';

  @override
  String get messaging_sendYourMove => 'Send your request or move to your opponent.';

  @override
  String get messaging_sendYourMoveAsMessage => 'As message';

  @override
  String get messaging_sendYourMoveAsQrCode => 'As QR code';

  @override
  String get messaging_rememberDecision => 'Remember my decision for this match.';

  @override
  String get messaging_signMessages => 'Sign my messages for this match.';

  @override
  String get messaging_scanQrCodeFromOpponent => 'Let your opponent scan this QR code.';

  @override
  String messaging_scanQrCodeFromOpponentWithName(Object name) {
    return 'Let your opponent $name scan this QR code.';
  }

  @override
  String get messaging_opponentNeedsToReact => 'Your opponent must respond to your last message first.';

  @override
  String get messaging_shareAgain => 'Send message again';

  @override
  String messaging_invitationMessage_Invitor(Object dimension, Object opponent, Object playMode) {
    return '$opponent has invited you to a $playMode $dimension x $dimension match. You will play Order, so your opponent starts.';
  }

  @override
  String messaging_invitationMessage_Invitee(Object dimension, Object opponent, Object playMode) {
    return '$opponent has invited you to a $playMode $dimension x $dimension match. You will be Chaos, so you start.';
  }

  @override
  String messaging_invitationMessage_InviteeChooses(Object dimension, Object opponent, Object playMode) {
    return '$opponent has invited you to a $playMode $dimension x $dimension match. You can choose which role you want to play.';
  }

  @override
  String messaging_matchAccepted(Object playId) {
    return 'The match $playId has been accepted :)';
  }

  @override
  String messaging_matchDeclined(Object playId) {
    return 'The match $playId has been declined :(';
  }

  @override
  String messaging_opponentResigned(Object opponent, Object playId) {
    return 'Your opponent $opponent has resigned from the match $playId, you win!';
  }

  @override
  String messaging_inviteMessage(Object dimension, Object name) {
    return 'I ($name) would like to invite you to a HyleX match. Click the link to reply to my invitation in the app (HyleX app required).';
  }

  @override
  String messaging_inviteMessageWithoutName(Object dimension) {
    return 'I would like to invite you to a HyleX match (${dimension}x$dimension). Click the link to reply to my invitation in the app (HyleX app required).';
  }

  @override
  String messaging_acceptInvitation(Object opponentRole, Object role) {
    return 'I accept your invitation. I will play $role, you will play $opponentRole.';
  }

  @override
  String get messaging_rejectInvitation => 'I\'m sorry, I have to decline your invitation. Maybe another time.';

  @override
  String messaging_nextMove(Object role, Object round) {
    return 'This is my move for round $round as $role.';
  }

  @override
  String messaging_resign(Object round) {
    return 'Ugh, quite hard! I give up in round $round.';
  }

  @override
  String get playState_initialised => 'New game';

  @override
  String get playState_remoteOpponentInvited => 'Invitation sent';

  @override
  String get playState_invitationPending => 'Invitation awaiting response';

  @override
  String get playState_remoteOpponentAccepted_ReadyToMove => 'Invitation accepted by opponent, please make your first move';

  @override
  String get playState_invitationAccepted_ReadyToMove => 'Invitation accepted, please make the first move';

  @override
  String get playState_invitationAccepted_WaitForOpponent => 'Invitation accepted, wait for the opponent\'s first move';

  @override
  String get playState_invitationRejected => 'Invitation declined';

  @override
  String get playState_invitationRejectedByYou => 'You declined the invitation';

  @override
  String get playState_invitationRejectedByOpponent => 'Your potential opponent declined your invitation';

  @override
  String get playState_readyToMove => 'It is your turn!';

  @override
  String get playState_waitForOpponent => 'Awaiting for opponent\'s move';

  @override
  String get playState_firstGameFinished_ReadyToSwap => 'First game finished: It is your turn to start the second game!';

  @override
  String get playState_firstGameFinished_WaitForOpponent => 'First game finished: Wait for the opponent\'s first move for the second game';

  @override
  String get playState_lost => 'Match lost';

  @override
  String get playState_won => 'Match won';

  @override
  String get playState_resigned => 'You gave up :(';

  @override
  String get playState_opponentResigned => 'Opponent gave up, you win';

  @override
  String get playState_closed => 'Match ended';

  @override
  String get intro_page1Title => 'The eternal fight between Chaos and Order';

  @override
  String get intro_page1Part1 => 'One player creates Chaos .. ';

  @override
  String get intro_page1Part2 => ' ..  the other counteracts as Order.';

  @override
  String get intro_page2Title => 'The role of Chaos';

  @override
  String get intro_page2Part1 => 'Chaos randomly draws chips from the stock and places them as chaotically as possible.';

  @override
  String get intro_page3Title => 'The Role of Order';

  @override
  String get intro_page3Part1 => 'Order tries to arrange the chips placed by Chaos into a horizontal or vertical symmetrical arrangement, so-called palindromes.';

  @override
  String get intro_page4Title => 'The role of Order';

  @override
  String get intro_page4Part1 => 'Order may slide any placed chip horizontally or vertically through empty cells. Order may also skip its current turn.';

  @override
  String get intro_page5Title => 'End of the game';

  @override
  String get intro_page5Part1 => 'Chaos receives points for each chip outside of a Palindrome  ..';

  @override
  String get intro_page5Part2 => ' ..  which is 20 points per chip in this example, so a total of 40.';

  @override
  String get intro_page6Title => 'End of the game';

  @override
  String get intro_page6Part1 => 'Order receives points for each chip that is part of a palindrome...';

  @override
  String get intro_page6Part2 => '... which results in 6 points, since there are two palindromes (green-green and red-green-green-red).';

  @override
  String get intro_page7Title => 'End of the game';

  @override
  String get intro_page7Part1 => 'The game is over when all chips have been placed ..';

  @override
  String get intro_page7Part2 => '.. and the player with the most points wins.';
}
