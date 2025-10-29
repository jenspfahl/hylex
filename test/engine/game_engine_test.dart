import 'package:flutter_test/flutter_test.dart';
import 'package:hyle_x/engine/game_engine.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/model/move.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/model/user.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/PlayStateManager.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/utils/fortune.dart';

void main() {
  StorageService.enableMocking = true;
  MessageService.enableMocking = true;
  
  group("Test game engine single play", () {

    final user = User(generateRandomString(userIdLength));

    test('without AI', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.singlePlay(PlaySize.Size5x5);
      final play = Play.newSinglePlay(
          header, PlayerType.LocalUser, PlayerType.LocalUser);

      final engine = SinglePlayerGameEngine(play, user, null, () {});

      engine.startGame();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      _commitMove(play, Move.placed(play.currentChip!, Coordinate(0, 0)));

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(
          Move.moved(GameChip(1), Coordinate(0, 0), Coordinate(0, 3)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 2);
      expect(engine.isBoardLocked(), false);
    });

    test('with Order AI', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.singlePlay(PlaySize.Size5x5);
      final play = Play.newSinglePlay(
          header, PlayerType.LocalUser, PlayerType.LocalAi);

      final engine = SinglePlayerGameEngine(play, user, null, () {});

      engine.startGame();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      _commitMove(play, Move.placed(play.currentChip!, Coordinate(0, 0)));

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);
    });
  });

  group("Test game engine multi play, invitor perspective", () {

    final localUser = User(generateRandomString(userIdLength));
    final remoteUser = User(generateRandomString(userIdLength));

    test('invitee rejected', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final localPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitor));

      expect(localPlay.header.state, PlayState.RemoteOpponentInvited);

      expect(await PlayStateManager().doAndHandleRejectInvite(localPlay.header), null);

      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});
      engine.startGame();
      
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.header.state, PlayState.InvitationRejected);
      expect(localPlay.currentRound, 1);
      expect(engine.isBoardLocked(), true);
      expect(localPlay.isGameOver(), true);

      expect(() => _commitMove(localPlay, Move.placed(localPlay.currentChip!, Coordinate(0, 0))),
          throwsA(TypeMatcher<Exception>()));

    });

    test('invitor starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final localPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitor));

      expect(localPlay.header.state, PlayState.RemoteOpponentInvited);

      final remoteAcceptMessage = AcceptInviteMessage(
          localPlay.header.playId,
          PlayOpener.Invitor,
          remoteUser.id,
          remoteUser.name,
          null);

      expect(await PlayStateManager().handleInviteAcceptedByRemote(localPlay.header, remoteAcceptMessage), null);

      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      engine.startGame();
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(localPlay.currentRound, 1);
      expect(engine.isBoardLocked(), false);
      expect(localPlay.isGameOver(), false);

      _commitMove(localPlay, Move.placed(localPlay.currentChip!, Coordinate(0, 0)));

      await engine.nextPlayer();
      expect(localPlay.currentRole, Role.Order);
      expect(localPlay.header.state, PlayState.WaitForOpponent);
      expect(localPlay.currentRound, 1);
      expect(engine.isBoardLocked(), true);

    });

    test('invitee starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final localPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee));

      expect(localPlay.header.state, PlayState.RemoteOpponentInvited);

      final remoteAcceptMessage = AcceptInviteMessage(
          localPlay.header.playId,
          PlayOpener.Invitee,
          remoteUser.id,
          remoteUser.name,
          Move.placed(GameChip(0), Coordinate(0, 0)));

      expect(await PlayStateManager().handleInviteAcceptedByRemote(localPlay.header, remoteAcceptMessage), null);

      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      await engine.opponentMoveReceived(remoteAcceptMessage.initialMove!);

      expect(localPlay.currentRole, Role.Order);
      expect(localPlay.currentRound, 1);
      expect(localPlay.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);
      expect(localPlay.isGameOver(), false);

      _commitMove(localPlay, Move.moved(GameChip(1), Coordinate(0, 0), Coordinate(0, 3)));

      await engine.nextPlayer();

      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 2);
      expect(localPlay.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);
      expect(localPlay.isGameOver(), false);

    });

    test('invitor resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final loalPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee));

      expect(loalPlay.header.state, PlayState.RemoteOpponentInvited);

      final remoteAcceptMessage = AcceptInviteMessage(
          loalPlay.header.playId,
          PlayOpener.Invitee,
          remoteUser.id,
          remoteUser.name,
          Move.placed(GameChip(0), Coordinate(0, 0)));

      expect(await PlayStateManager().handleInviteAcceptedByRemote(loalPlay.header, remoteAcceptMessage), null);

      final engine = MultiPlayerGameEngine(loalPlay, localUser, null, () {});

      await engine.opponentMoveReceived(remoteAcceptMessage.initialMove!);

      expect(loalPlay.currentRole, Role.Order);
      expect(loalPlay.currentRound, 1);
      expect(loalPlay.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);
      expect(loalPlay.isGameOver(), false);

      expect(await PlayStateManager().doResign(loalPlay.header, localUser), null);

      expect(loalPlay.header.state, PlayState.Resigned);

      expect(loalPlay.isGameOver(), true);
      expect(loalPlay.getWinnerRole(), Role.Chaos);
      expect(loalPlay.getWinnerPlayer(), PlayerType.RemoteUser);
      expect(engine.isBoardLocked(), true);

    });

    test('invitee resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final localPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee));

      expect(localPlay.header.state, PlayState.RemoteOpponentInvited);

      final remoteAcceptMessage = AcceptInviteMessage(
          localPlay.header.playId,
          PlayOpener.Invitee,
          remoteUser.id,
          remoteUser.name,
          Move.placed(GameChip(0), Coordinate(0, 0)));

      expect(await PlayStateManager().handleInviteAcceptedByRemote(localPlay.header, remoteAcceptMessage), null);

      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      await engine.opponentMoveReceived(remoteAcceptMessage.initialMove!);

      expect(localPlay.currentRole, Role.Order);
      expect(localPlay.currentRound, 1);
      expect(localPlay.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);
      expect(localPlay.isGameOver(), false);

      _commitMove(localPlay, Move.skipped());

      await engine.nextPlayer();

      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 2);
      expect(localPlay.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);
      expect(localPlay.isGameOver(), false);

      expect(await PlayStateManager().handleResignedByRemote(localPlay.header, remoteUser), null);

      expect(localPlay.header.state, PlayState.OpponentResigned);

      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 2);
      expect(engine.isBoardLocked(), true);
      expect(localPlay.isGameOver(), true);
      expect(localPlay.getWinnerRole(), Role.Order);
      expect(localPlay.getWinnerPlayer(), PlayerType.LocalUser);

    });


  });

  group("Test game engine multi play, invitee perspective", () {

    final localPlayId = "local_id";
    final localUser = User(generateRandomString(userIdLength));
    final remoteUser = User(generateRandomString(userIdLength));

    test('invitor starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playOpener = PlayOpener.Invitor;

      final remoteInviteMessage = InviteMessage(
          localPlayId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          remoteUser.id,
          remoteUser.name);

      final localHeader = PlayHeader.multiPlayInvitee(
          remoteInviteMessage, null, PlayState.InvitationPending);

      expect(await PlayStateManager().doAcceptInvite(localHeader, playOpener), null);
      expect(localHeader.state, PlayState.InvitationAccepted_WaitForOpponent);

      final localPlay = Play.newMultiPlay(localHeader);
      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      engine.startGame();
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 1);
      expect(localPlay.isGameOver(), false);
      expect(engine.isBoardLocked(), true);
    });

    test('invitee starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playOpener = PlayOpener.Invitee;

      final remoteInviteMessage = InviteMessage(
          localPlayId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          remoteUser.id,
          remoteUser.name);

      final localHeader = PlayHeader.multiPlayInvitee(
          remoteInviteMessage, null, PlayState.InvitationPending);

      expect(await PlayStateManager().doAcceptInvite(localHeader, playOpener), null);
      expect(localHeader.state, PlayState.InvitationAccepted_ReadyToMove);

      final localPlay = Play.newMultiPlay(localHeader);
      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      engine.startGame();
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 1);
      expect(localPlay.isGameOver(), false);
      expect(engine.isBoardLocked(), false);

      _commitMove(localPlay, Move.placed(localPlay.currentChip!, Coordinate(0, 0)));

      await engine.nextPlayer();

      expect(localHeader.state, PlayState.InvitationAccepted_WaitForOpponent);
      expect(localPlay.currentRole, Role.Order);
      expect(localPlay.currentRound, 1);
      expect(localPlay.isGameOver(), false);
      expect(engine.isBoardLocked(), true);

    });

    test('invitee resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playOpener = PlayOpener.Invitee;

      final remoteInviteMessage = InviteMessage(
          localPlayId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          remoteUser.id,
          remoteUser.name);

      final localHeader = PlayHeader.multiPlayInvitee(
          remoteInviteMessage, null, PlayState.InvitationPending);

      expect(await PlayStateManager().doAcceptInvite(localHeader, playOpener), null);
      expect(localHeader.state, PlayState.InvitationAccepted_ReadyToMove);

      final localPlay = Play.newMultiPlay(localHeader);
      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      engine.startGame();
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 1);
      expect(localPlay.isGameOver(), false);
      expect(engine.isBoardLocked(), false);

      expect(await PlayStateManager().doResign(localHeader, localUser), null);

      expect(localPlay.header.state, PlayState.Resigned);
      expect(localPlay.isGameOver(), true);
      expect(localPlay.getWinnerRole(), Role.Order);
      expect(localPlay.getWinnerPlayer(), PlayerType.RemoteUser);
      expect(engine.isBoardLocked(), true);

    });

    test('invitor resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playOpener = PlayOpener.Invitor;

      final remoteInviteMessage = InviteMessage(
          localPlayId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          remoteUser.id,
          remoteUser.name);

      final localHeader = PlayHeader.multiPlayInvitee(
          remoteInviteMessage, null, PlayState.InvitationPending);

      expect(await PlayStateManager().doAcceptInvite(localHeader, playOpener), null);
      expect(localHeader.state, PlayState.InvitationAccepted_WaitForOpponent);

      final localPlay = Play.newMultiPlay(localHeader);
      final engine = MultiPlayerGameEngine(localPlay, localUser, null, () {});

      engine.startGame();
      expect(localPlay.currentRole, Role.Chaos);
      expect(localPlay.currentRound, 1);
      expect(localPlay.isGameOver(), false);
      expect(engine.isBoardLocked(), true);

      expect(await PlayStateManager().handleResignedByRemote(localHeader, localUser), null);

      expect(localPlay.header.state, PlayState.OpponentResigned);

      expect(localPlay.isGameOver(), true);
      expect(localPlay.getWinnerRole(), Role.Order);
      expect(localPlay.getWinnerPlayer(), PlayerType.LocalUser);
      expect(engine.isBoardLocked(), true);

    });
    

  });

}

_commitMove(Play play, Move move) {
  play.applyStaleMove(move);
  play.commitMove();
}

