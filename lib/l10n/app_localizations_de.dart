// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get close => 'Schließen';

  @override
  String get done => 'Fertig';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String hello(Object name) {
    return 'Hallo $name!';
  }

  @override
  String get winner => 'Gewinner';

  @override
  String get looser => 'Verlierer';

  @override
  String get left => 'übrig';

  @override
  String get accept => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get replyLater => 'Später antworten';

  @override
  String get as => 'als';

  @override
  String get yesterday => 'Gestern';

  @override
  String get today => 'Heute';

  @override
  String get unknown => 'unbekannt';

  @override
  String get startMenu_singlePlay => 'Einfaches Spiel';

  @override
  String get startMenu_multiPlay => 'Mehrspieler';

  @override
  String get startMenu_newGame => 'Neues Spiel';

  @override
  String get startMenu_resumeGame => 'Fortsetzen';

  @override
  String get startMenu_newMatch => 'Neues Match';

  @override
  String get startMenu_continueMatch => 'Match fortsetzen';

  @override
  String get startMenu_sendInvite => 'Einladug senden';

  @override
  String get startMenu_scanCode => 'Code scannen';

  @override
  String get startMenu_more => 'Mehr';

  @override
  String get startMenu_howToPlay => 'Regeln';

  @override
  String get startMenu_achievements => 'Statistiken';

  @override
  String get achievements_all => 'Alle';

  @override
  String get achievements_single => 'Einzel';

  @override
  String get achievements_multi => 'Mehrspieler';

  @override
  String get achievements_overall => 'Gesamt';

  @override
  String get achievements_totalCount => 'Anzahl';

  @override
  String get achievements_totalScore => 'Punkte';

  @override
  String get achievements_high => 'Höchste';

  @override
  String get achievements_won => 'Gewonnen';

  @override
  String get achievements_lost => 'Verloren';

  @override
  String get action_scanOrPasteMessage => 'Scanne den QR-Code deines Gegners. Falls er dir eine Nachricht mit einem App-Link geschickt hat und dieser Link diese App nicht öffnet, kannst du ihn hier einfügen.';

  @override
  String get action_scanMessage => 'QR-Code scannen';

  @override
  String get action_scanMessageError => 'Dieser QR-Code konnte nicht gelesen werden!';

  @override
  String get action_pasteMessage => 'Nachricht einfügen';

  @override
  String get action_pasteMessageHere => 'Gegnerische Nachricht hier einfügen. Der App-Link wird automatisch extrahiert.';

  @override
  String get action_pasteMessageError => 'Aus dieser Nachricht konnte kein App-Link extrahiert werden!';

  @override
  String get dialog_loadingGame => 'Lade Spiel ...';

  @override
  String get dialog_initGame => 'Initialisiere neues Spiel ...';

  @override
  String get dialog_quitTheApp => 'Willst du die App beenden?';

  @override
  String get dialog_aboutDesc1 => 'Ein Entropy-Klon';

  @override
  String dialog_aboutDesc2(Object homepage) {
    return 'Besuche $homepage, um den Code anzusehen, Fehler zu melden und Sterne zu vergeben!';
  }

  @override
  String get dialog_overwriteGame => 'Wenn in neues Einzelspiel begonnen wird, wird das aktuelle Einzelspiel gelöscht.';

  @override
  String get dialog_whichGroundSize => 'Auf welcher Spielfeldgröße möchtest du spielen?';

  @override
  String get dialog_groundSize5 => 'Anfängerlevel, dauert ein paar Minuten';

  @override
  String get dialog_groundSize7 => 'Die ursprüngliche Entropy-Größe';

  @override
  String get dialog_groundSize9 => 'Erweiterte Größe, falls 7 x 7 nicht ausreicht';

  @override
  String get dialog_groundSize11 => 'Professionelles und langes Spiel';

  @override
  String get dialog_groundSize13 => 'Höchster Anspruch! Extrem schwer!';

  @override
  String get dialog_whatRole => 'Welche Rolle möchtest du übernehmen?';

  @override
  String get dialog_whatRoleOrder => 'Der Computer ist Chaos und startet das Spiel.';

  @override
  String get dialog_whatRoleChaos => 'Der Computer ist Order, aber du startest das Spiel.';

  @override
  String get dialog_whatRoleOrderForMultiPlay => 'Dein Gegner ist Chaos und beginnt das Match.';

  @override
  String get dialog_whatRoleChaosForMultiPlay => 'Dein Gegner ist Order, aber du beginnst das Match.';

  @override
  String get dialog_roleBoth => 'Chaos und Order';

  @override
  String get dialog_whatRoleBoth => 'Du spielst beide Rollen, vielleicht mit einem Freund am selben Gerät.';

  @override
  String get dialog_roleNone => 'Keine';

  @override
  String get dialog_whatRoleNone => 'Der Computer spielt allein, du schaust nur zu.';

  @override
  String get dialog_roleInviteeDecides => 'Gegner entscheidet';

  @override
  String get dialog_whatRoleInviteeDecides => 'Dein Gegner entscheidet, ob er Order oder Chaos ist und damit das Spiel beginnt.';

  @override
  String get dialog_whatKindOfMatch => 'Welche Spielart möchtest du spielen?';

  @override
  String get dialog_whatKindOfMatchHylexStyle => 'Sowohl Order als auch Chaos können Punkte erzielen. Der Spieler mit den meisten Punkten gewinnt. Das Match endet nach einem Spiel.';

  @override
  String get dialog_whatKindOfMatchClassicStyle => 'Nur Order kann Punkte erzielen. Ein Match besteht aus zwei einzelnen Spielen. Nach dem ersten Spiel tauschen die Spieler die Rollen. Der Spieler mit den meisten Punkten gewinnt.';

  @override
  String get dialog_whoToStart => 'Wer soll anfangen? Der, der angängt, ist Chaos.';

  @override
  String get dialog_whoToStartMe => 'Ich';

  @override
  String get dialog_whoToStartTheOther => 'Mein Gegner';

  @override
  String get dialog_yourName => 'Wie lautet dein Name? Dein Gegner wird diesen Namen sehen. Bitte wähle einen kurzen Namen.';

  @override
  String get dialog_resetAchievements => 'Möchtest du wirklich alle Erfolge auf Null zurücksetzen?';

  @override
  String get dialog_restartGame => 'Möchtest du dieses Spiel neu starten? Der aktuelle Spielstand geht dabei verloren.';

  @override
  String get dialog_skipMove => 'Willst du deinen Zug wirklich auslassen?';

  @override
  String dialog_askForRematchAgain(Object playId) {
    return 'Du hast bereits Revanche angefordert, siehe $playId.';
  }

  @override
  String get dialog_askAgain => 'Frag erneut';

  @override
  String dialog_undoLastMove(Object recentRole) {
    return 'Möchtest du den letzten Zug von $recentRole rückgängig machen?';
  }

  @override
  String dialog_undoLastTwoMoves(Object currentRole, Object recentRole) {
    return 'Möchtest du den letzten Zug von $recentRole rückgängig machen? Dadurch wird auch der vorherige Zug von $currentRole rückgängig gemacht.';
  }

  @override
  String get dialog_undoCompleted => 'Letzen Zug rückgängig gemacht';

  @override
  String get dialog_wantToResign => 'Willst du aufgeben? Dann wirst du dieses Spiel verlieren.';

  @override
  String dialog_deleteFinalMatch(Object playId) {
    return 'Möchtest du das Match $playId wirklich entfernen? Dies kann nicht rückgängig gemacht werden!';
  }

  @override
  String dialog_deleteOngoingMatch(Object playId) {
    return 'Möchtest du das Match $playId wirklich entfernen? Nach dem Entfernen kannst du es nicht mehr weiterspielen!';
  }

  @override
  String dialog_matchCreated(Object playId) {
    return 'Neues Match $playId erstellt.';
  }

  @override
  String get dialog_goToMatch => 'Gehe zu Match';

  @override
  String get gameTitle_againstComputer => 'Einzelspiel';

  @override
  String get gameTitle_alternate => 'Abwechselndes Einzelspiel';

  @override
  String get gameTitle_automatic => 'Automatisches Spiel';

  @override
  String gameTitle_playAgainstOpponent(Object opponent, Object playId) {
    return '$playId gegen $opponent';
  }

  @override
  String get submitButton_submitMove => 'Zug einreichen';

  @override
  String get submitButton_skipMove => 'Zug überspringen';

  @override
  String get submitButton_shareAgain => 'Erneut senden';

  @override
  String get submitButton_restart => 'Spiel neu starten';

  @override
  String get submitButton_swapRoles => 'Rollen tauschen und fortfahren';

  @override
  String get submitButton_rematch => 'Revanche fordern';

  @override
  String gameHeader_roundOf(Object round, Object totalRounds) {
    return 'Runde $round von $totalRounds';
  }

  @override
  String gameHeader_round(Object round) {
    return 'Runde $round';
  }

  @override
  String get gameHeader_rolesSwapped => 'Rollen getauscht';

  @override
  String get gameHeader_currentPlayer => 'Aktueller Spieler';

  @override
  String get gameHeader_waitingPlayer => 'Wartender Spieler';

  @override
  String gameHeader_chaosChipCount(Object count) {
    return 'Ein ungeordneter Spielstein zählt $count';
  }

  @override
  String get gameHeader_drawnChip => 'Gezogener Spielstein';

  @override
  String get gameHeader_recentlyPlacedChip => 'Zuletzt abgelegter Spielstein';

  @override
  String get gameHeader_chip => 'Spielstein';

  @override
  String get playMode_hylex => 'HyleX-Stil';

  @override
  String get playMode_classic => 'Klassischer Stil';

  @override
  String get player_localUser => 'Du';

  @override
  String get player_localAi => 'Computer';

  @override
  String get player_remoteUser => 'Gegner';

  @override
  String move_placedChip(Object chip, Object where, Object who) {
    return '$who hat $chip auf $where gelegt';
  }

  @override
  String move_movedChip(Object chip, Object from, Object to, Object who) {
    return '$who hat $chip von $from nach $to verschoben';
  }

  @override
  String move_skipped(Object who) {
    return '$who hat den Zug ausgesetzt';
  }

  @override
  String get color_red => 'Rot';

  @override
  String get color_yellow => 'Gelb';

  @override
  String get color_green => 'Grün';

  @override
  String get color_cyan => 'Cyan';

  @override
  String get color_blue => 'Blau';

  @override
  String get color_pink => 'Rosa';

  @override
  String get color_grey => 'Grau';

  @override
  String get color_brown => 'Braun';

  @override
  String get color_olive => 'Olivgrün';

  @override
  String get color_moss => 'Moosgrün';

  @override
  String get color_teal => 'Türkis';

  @override
  String get color_indigo => 'Indigo';

  @override
  String get color_purple => 'Lila';

  @override
  String get gameState_gameStarted => 'Spielbeginn';

  @override
  String get gameState_gameOver => 'Spielende';

  @override
  String gameState_gameOverWinner(Object who) {
    return 'Spielende! $who hat das Spiel gewonnen!';
  }

  @override
  String gameState_gameOverLooser(Object who) {
    return 'Spielende! $who hat das Spiel verloren!';
  }

  @override
  String get gameState_gameOverOpponentResigned => 'Spielende! Du hast dieses Spiel gewonnen, weil dein Gegner aufgegeben hat!';

  @override
  String get gameState_gameOverYouResigned => 'Spielende! Du hast dieses Spiel verloren, weil du aufgegeben hast!';

  @override
  String gameState_waitingForRemoteOpponent(Object name) {
    return 'Warte auf Gegners ($name) Zug ...';
  }

  @override
  String gameState_waitingForPlayerToMove(Object name) {
    return 'Warte darauf, dass $name zieht ...';
  }

  @override
  String gameState_waitingForPlayerToPlace(Object chip, Object name) {
    return 'Warte darauf, dass $name $chip ablegt...';
  }

  @override
  String get gameState_firstGameFinishedOfTwo => 'Das erste Spiel ist beendet, die Rollen werden getauscht und der Gegner spielt Chaos!';

  @override
  String get gameState_firstGameState => 'Ergebnis des ersten Spiels';

  @override
  String get gameState_gamePaused => 'Spiel wurde pausiert';

  @override
  String get hint_swapRoles => 'Erstes Spiel des Matches beendet. Zeit, die Rollen zu tauschen!';

  @override
  String get hint_orderToMove => 'Jetzt ist Order an der Reihe, einen Spielstein zu verschieben oder auszusetzen!';

  @override
  String hint_chaosToPlace(Object chip) {
    return 'Jetzt ist Chaos an der Reihe, $chip abzulegen!';
  }

  @override
  String get error_chaosHasToPlace => 'Chaos muss einen Spielstein ablegen, bevor es weitergeht!';

  @override
  String get error_chaosAlreadyPlaced => 'Du hast bereits einen Spielstein abgelegt.';

  @override
  String get error_noMoreStock => 'Kein Spielstein mehr verfügbar.';

  @override
  String get error_onlyRemoveRecentlyPlacedChip => 'Du kannst nur den zuletzt abgelegten Spielstein entfernen!';

  @override
  String get error_orderHasToSelectAChip => 'Bitte wähle zuerst den Spielstein aus, den du bewegen möchtest.';

  @override
  String get error_orderMoveInvalid => 'Der Spielstein kann nur horizontal oder vertikal durch freie Felder verschoben werden.';

  @override
  String get error_orderMoveOnOccupied => 'Du kannst den ausgewählten Spielstein nicht auf ein belegtes Feld verschieben.';

  @override
  String get error_illegalCharsForUserName => 'Der Name darf nur aus lateinischen Buchstaben, Ziffern, Leerzeichen und Bindestrichen bestehen!';

  @override
  String get error_cannotExtractUrl => 'Es kann kein HyleX App-Link aus dem geteilten Text extrahiert werden';

  @override
  String get error_cannotParseUrl => 'Der angegebene HyleX App-Link konnte nicht gelesen werden.';

  @override
  String error_alreadyReactedToInvite(Object playId) {
    return 'Du hast bereits auf diese Einladung reagiert. Siehe $playId.';
  }

  @override
  String error_matchMotFound(Object playId) {
    return 'Spiel $playId wurde nicht gefunden oder bereits entfernt.';
  }

  @override
  String error_matchAlreadyFinished(Object playId) {
    return 'Spiel $playId ist bereits beendet.';
  }

  @override
  String get error_nothingToResume => 'Kein laufendes Einzelspiel, das fortgesetzt werden könnte';

  @override
  String get error_cannotReactToOwnInvitation => 'Diese Einladung wurde von dir selber erstellt, du kannst nicht darauf antworten!';

  @override
  String get error_cameraPermissionNeeded => 'Kamera-Berechtigung erforderlich, um QR-Codes scannen zu können!';

  @override
  String get error_linkAlreadyProcessed => 'Dieser Link wurde bereits verarbeitet.';

  @override
  String get error_linkIntendedForOpponent => 'Dieser Link war für deinen Gegner gedacht, nicht für dich!';

  @override
  String get error_linkIsNotTheLatest => 'Dieser Link ist nicht der letzte des Matches.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settings_commonSettings => 'Allgemeine Einstellungen';

  @override
  String get settings_gameSettings => 'Spieleinstellungen';

  @override
  String get settings_animateMoves => 'Spielzüge animieren';

  @override
  String get settings_animateMovesDescription => 'Spielzüge wie Verschieben order Ablegen von Spielsteinen werden animiert.';

  @override
  String get settings_showCoordinates => 'Koordinaten anzeigen';

  @override
  String get settings_showCoordinatesDescription => 'Koordinaten auf der X- und Y-Achse im Spielfeld anzeigen.';

  @override
  String get settings_showPointsForOrder => 'Punkte für Order anzeigen';

  @override
  String get settings_showPointsForOrderDescription => 'Zeigt die Punkte pro Spielstein an, die Order bisher erreicht hat.';

  @override
  String get settings_showHints => 'Hinweise anzeigen';

  @override
  String get settings_showHintsDescription => 'Zeigt Hinweise an, die helfen, was als Nächstes im Spiel zu tun ist.';

  @override
  String get settings_showMoveErrors => 'Fehler beim Spielzug anzeigen';

  @override
  String get settings_showMoveErrorsDescription => 'Zeigt einen Fehler an, wenn Spielsteine falsch verschoben oder plaziert werden.';

  @override
  String get settings_multiplayerSettings => 'Multiplayer-Einstellungen';

  @override
  String settings_changeYourName(Object name) {
    return 'Ändere deinen Namen \'$name\'';
  }

  @override
  String get settings_setYourName => 'Lege deinen Namen fest';

  @override
  String get settings_setOrChangeYourNameDescription => 'Dein Name wird in Nachrichten an deine Gegner angezeigt.';

  @override
  String get settings_showLanguageSelectorForMessages => 'Nachrichten in verschiedenen Sprachen senden';

  @override
  String get settings_showLanguageSelectorForMessagesDescription => 'Wenn deine Gegner eine andere Sprache sprechen, aktiviere diese Option, um eine Sprachauswahl beim Senden-Button anzuzeigen.';

  @override
  String get settings_signMessages => 'Nachrichten signieren';

  @override
  String get settings_signMessagesDescription => 'Nachrichten, die du in Mehrspieler-Spielen sendest, werden kryptographisch signiert.';

  @override
  String get settings_signMessagesExplanation => 'Signiere deine Nachrichten mit deinem öffentlichen Schlüssel, wenn du sicherstellen möchtest, dass deine Nachrichten nicht manipuliert werden und um zu beweisen, dass sie von dir stammen. Dies kann wichtig sein, wenn du deine Spielzüge mit der Öffentlichkeit teilest.';

  @override
  String get settings_signMessages_Never => 'Nie';

  @override
  String get settings_signMessagesDescription_Never => 'Nachrichten werden NICHT signiert.';

  @override
  String get settings_signMessages_OnDemand => 'Auf Anfrage';

  @override
  String get settings_signMessagesDescription_OnDemand => 'Nachrichten werden nur bei Bedarf signiert und vor jedem Senden wird danach gefragt.';

  @override
  String get settings_signMessages_Always => 'Immer';

  @override
  String get settings_signMessagesDescription_Always => 'Nachrichten werden signiert, ohne danach zu fragen.';

  @override
  String get settings_backupAndRestore => 'Sichern und Wiederherstellen';

  @override
  String get settings_backupAll => 'Alles in einer Datei sichern';

  @override
  String get settings_backupAllDescription => 'Ihre Spieleridentität, alle laufenden und abgeschlossenen Spiele sowie alle Erfolge werden in einer Sicherungsdatei gespeichert.';

  @override
  String get settings_restoreFromFile => 'Aus einer Sicherungsdatei wiederherstellen';

  @override
  String get settings_restoreFromFileDescription => 'Zum Beispiel kannst du nach einer Neuinstallation der App eine zuvor erstellte Sicherungsdatei importieren.';

  @override
  String get settings_restoreFromFileConfirmation => 'Beim Wiederherstellen aus einer Datei werden alle aktuellen Daten überschrieben! Fortfahren?';

  @override
  String get settings_sharePublicKey => 'Öffentlichen Schlüssel teilen';

  @override
  String get settings_sharePublicKeyDescription => 'Wenn du deine Nachricht signierest, kann es erforderlich sein, deinen öffentlichen Schlüssel mit anderen zu teilen.';

  @override
  String get settings_sharePublicKeyChooseFormat => 'Wähle ein Format zum Teilen des öffentlichen Schlüssels:';

  @override
  String get settings_sharePublicKeyChooseFormat_JWK => 'Im JWK-Format';

  @override
  String get settings_sharePublicKeyChooseFormat_PEM => 'Im PEM-Format';

  @override
  String get matchMenu_matchInfo => 'Spielinfos';

  @override
  String get matchMenu_showFirstGame => 'Ergebnis des ersten Spiels';

  @override
  String get matchMenu_showSendOptions => 'An Gegner senden ..';

  @override
  String get matchMenu_showReadingOptions => 'Nachricht von Gegner lesen ..';

  @override
  String get matchMenu_redoLastMessage => 'Repariere Spielstand ..';

  @override
  String get matchMenu_redoLastMessageConfirmation => 'Falls etwas schiefgelaufen ist und du das Spiel nicht wie erwartet fortsetzen kannst, kannst du hier den aktuellen Zustand reparieren. Wenn du fortfährst, wird dein aktueller, aber noch nicht gesendeter Zug und der letzte Zug deines Gegners rückgängig gemacht, sodass du ihn erneut lesen musst. Soll der Spielstand repariert werden?';

  @override
  String get matchMenu_gameMode => 'Modus';

  @override
  String get matchMenu_gameInMatch => 'Spiel im Match';

  @override
  String get matchMenu_gameInMatchFirst => 'Erstes Spiel';

  @override
  String get matchMenu_gameInMatchSecond => 'Zweites Spiel';

  @override
  String get matchMenu_gameSize => 'Spielgröße';

  @override
  String get matchMenu_gameOpener => 'Eröffner';

  @override
  String get matchMenu_pointsPerUnorderedChip => 'Punkte pro nicht geordnetem Spielstein';

  @override
  String get matchMenu_startedAt => 'Spielbeginn';

  @override
  String get matchMenu_lastActivity => 'Letzte Aktivität am';

  @override
  String get matchMenu_finishedAt => 'Spielende';

  @override
  String get matchMenu_status => 'Spielstatus';

  @override
  String get matchList_title => 'Deine Matches';

  @override
  String get matchList_nothingFound => 'Keine gespeicherten Spielstände vorhanden!';

  @override
  String get matchList_errorDuringLoading => 'Gespeicherte Spielstände können nicht geladen werden!';

  @override
  String get matchList_nothingToShare => 'Du musst erst auf die letzte Nachricht reagieren!';

  @override
  String get matchList_sortBy => 'Matches sortieren nach';

  @override
  String get matchList_sortByCurrentStatusTitle => 'Spielstatus';

  @override
  String get matchList_sortByCurrentStatusDesc => 'Sortiert und gruppiert nach dem aktuellen Status';

  @override
  String get matchList_sortByRecentlyPlayedTitle => 'Zuletzt gespielt';

  @override
  String get matchList_sortByRecentlyPlayedDesc => 'Das zuletzt gespielte Match steht oben';

  @override
  String get matchList_sortByMatchIdTitle => 'Match-ID';

  @override
  String get matchList_sortByMatchIdDesc => 'Alphabetisch sortiert nach der Match-ID, um Matches schneller zu finden';

  @override
  String get matchList_sortByOpponentTitle => 'Gegner';

  @override
  String get matchList_sortByOpponentDesc => 'Alphabetisch sortiert und gruppiert nach dem Namen der Gegner';

  @override
  String get matchListGroup_actionNeeded => 'Aktion erforderlich';

  @override
  String get matchListGroup_waitForOpponent => 'Warte auf Gegner';

  @override
  String get matchListGroup_wonMatches => 'Gewonnene Matches';

  @override
  String get matchListGroup_lostMatches => 'Verlorene Matches';

  @override
  String get matchListGroup_rejectedMatches => 'Abgelehnte Match-Einladungen';

  @override
  String get messaging_sendYourMove => 'Sende deine Anfrage oder deinen Zug an deinen Gegner.';

  @override
  String get messaging_sendYourMoveAsMessage => 'Als Nachricht';

  @override
  String messaging_sendYourMoveAsMessageInLanguage(Object language) {
    return 'Verwendete Sprache: $language';
  }

  @override
  String get messaging_sendYourMoveAsQrCode => 'Als QR-Code';

  @override
  String get messaging_rememberDecision => 'Merke meine Entscheidung für dieses Match.';

  @override
  String get messaging_signMessages => 'Signiere meine Nachrichten für dieses Match.';

  @override
  String get messaging_scanQrCodeFromOpponent => 'Lass deinen Gegner diesen QR-Code scannen.';

  @override
  String messaging_scanQrCodeFromOpponentWithName(Object name) {
    return 'Lass deinen Gegner $name diesen QR-Code scannen.';
  }

  @override
  String get messaging_opponentNeedsToReact => 'Dein Gegner muss zuerst auf deine letzte Nachricht reagieren.';

  @override
  String get messaging_shareAgain => 'Sende sie erneut';

  @override
  String messaging_invitationMessage_Invitor(Object dimension, Object opponent, Object playMode) {
    return '$opponent hat dich zu einem $playMode $dimension x $dimension Match eingeladen. Du spielst Order, also beginnt dein Gegner.';
  }

  @override
  String messaging_invitationMessage_Invitee(Object dimension, Object opponent, Object playMode) {
    return '$opponent hat dich zu einem $playMode $dimension x $dimension Match eingeladen. Du spielst Chaos, also beginnst du.';
  }

  @override
  String messaging_invitationMessage_InviteeChooses(Object dimension, Object opponent, Object playMode) {
    return '$opponent hat dich zu einem $playMode $dimension x $dimension Match eingeladen. Du kannst wählen, welche Rolle du spielen möchtest.';
  }

  @override
  String messaging_matchAccepted(Object playId) {
    return 'Das Match $playId wurde angenommen :)';
  }

  @override
  String messaging_matchDeclined(Object playId) {
    return 'Das Match $playId wurde abgelehnt :(';
  }

  @override
  String messaging_opponentResigned(Object opponent, Object playId) {
    return 'Dein Gegner $opponent hat das Match $playId aufgegeben, du gewinnst!';
  }

  @override
  String messaging_inviteMessage(Object dimension, Object name) {
    return 'Ich ($name) möchte dich zu einem HyleX-Match (${dimension}x$dimension) einladen. Klicke auf den Link, um meine Einladung in der App zu beantworten (HyleX-App erforderlich).';
  }

  @override
  String messaging_inviteMessageWithoutName(Object dimension) {
    return 'Ich möchte dich zu einem HyleX-Match einladen. Klicke auf den Link, um meine Einladung in der App zu beantworten (HyleX-App erforderlich).';
  }

  @override
  String messaging_acceptInvitation(Object opponentRole, Object role) {
    return 'Ich nehme deine Einladung an. Ich spiele $role, du spielst $opponentRole.';
  }

  @override
  String get messaging_rejectInvitation => 'Es tut mir leid, ich muss die Einladung leider ablehnen. Vielleicht ein anderes Mal.';

  @override
  String messaging_nextMove(Object role, Object round) {
    return 'Das ist mein Zug in Runde $round als $role.';
  }

  @override
  String messaging_resign(Object round) {
    return 'Puh, ganz schön schwierig! Ich gebe in Runde $round auf.';
  }

  @override
  String get playState_initialised => 'Neues Spiel';

  @override
  String get playState_remoteOpponentInvited => 'Einladung gesendet';

  @override
  String get playState_invitationPending => 'Einladung wartet auf Antwort';

  @override
  String get playState_remoteOpponentAccepted_ReadyToMove => 'Einladung wurde vom Gegner angenommen, bitte führe deinen ersten Zug aus';

  @override
  String get playState_invitationAccepted_ReadyToMove => 'Einladung angenommen, bitte führe den ersten Zug aus';

  @override
  String get playState_invitationAccepted_WaitForOpponent => 'Einladung angenommen, warte auf den ersten Zug des Gegners';

  @override
  String get playState_invitationRejected => 'Einladung abgelehnt';

  @override
  String get playState_invitationRejectedByYou => 'Du hast die Einladung abgelehnt';

  @override
  String get playState_invitationRejectedByOpponent => 'Dein potentieller Gegner hat deine Einladung abgelehnt';

  @override
  String get playState_readyToMove => 'Du bist am Zug!';

  @override
  String get playState_waitForOpponent => 'Warte auf den Zug des Gegners';

  @override
  String get playState_firstGameFinished_ReadyToSwap => 'Erstes Spiel beendet: Du bist am Zug, um das zweite Spiel zu starten!';

  @override
  String get playState_firstGameFinished_WaitForOpponent => 'Erstes Spiel beendet: Warte auf den ersten Zug des Gegners für das zweite Spiel';

  @override
  String get playState_lost => 'Spiel verloren';

  @override
  String get playState_won => 'Spiel gewonnen';

  @override
  String get playState_resigned => 'Du hast aufgegeben :(';

  @override
  String get playState_opponentResigned => 'Gegner hat aufgegeben, du gewinnst';

  @override
  String get playState_closed => 'Spiel beendet';

  @override
  String get intro_page1Title => 'Der ewige Kampf zwischen Chaos und Ordnung';

  @override
  String get intro_page1Part1 => 'Ein Spieler verursacht Chaos (Chaos) ...';

  @override
  String get intro_page1Part2 => '... der andere bringt es in Ordnung (Order).';

  @override
  String get intro_page2Title => 'Die Rolle von Chaos';

  @override
  String get intro_page2Part1 => 'Chaos zieht zufällig Spielsteine aus dem Vorrat und platziert sie so chaotisch wie möglich.';

  @override
  String get intro_page3Title => 'Die Rolle von Order';

  @override
  String get intro_page3Part1 => 'Order versucht, die von Chaos gesetzten Spielsteine in eine horizontale oder vertikale symmetrische Anordnung, sogenannte Palindrome, zu bringen.';

  @override
  String get intro_page4Title => 'Die Rolle von Order';

  @override
  String get intro_page4Part1 => 'Order kann jeden gesetzten Spielstein horizontal oder vertikal durch leere Felder verschieben. Order kann auch den aktuellen Zug aussetzen.';

  @override
  String get intro_page5Title => 'Spielende';

  @override
  String get intro_page5Part1 => 'Chaos erhält Punkte für jeden Spielstein außerhalb eines Palindroms ...';

  @override
  String get intro_page5Part2 => '... das sind in diesem Beispiel 20 Punkte pro Spielstein, also insgesamt 40.';

  @override
  String get intro_page6Title => 'Spielende';

  @override
  String get intro_page6Part1 => 'Order erhält Punkte für jeden Spielstein, der Teil eines Palindroms ist...';

  @override
  String get intro_page6Part2 => '... was 6 Punkte ergibt, da es zwei Palindrome sind (grün-grün und rot-grün-grün-rot).';

  @override
  String get intro_page7Title => 'Spielende';

  @override
  String get intro_page7Part1 => 'Das Spiel ist beendet, wenn alle Spielsteine gesetzt wurden ...';

  @override
  String get intro_page7Part2 => '... und der Spieler mit den meisten Punkten gewinnt.';
}
