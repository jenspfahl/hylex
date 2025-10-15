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

  group("Test game engine", () {

    final user = User(generateRandomString(userIdLength));
    final remoteUser = User(generateRandomString(userIdLength));

    test('Test single play no AI', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.singlePlay(PlaySize.Size5x5);
      final play = Play.newSinglePlay(header, PlayerType.LocalUser, PlayerType.LocalUser);

      final engine = SinglePlayerGameEngine(play, user, null, () {});

      engine.startGame();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.moved(GameChip(1), Coordinate(0, 0), Coordinate(0, 3)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 2);
      expect(engine.isBoardLocked(), false);

    });

    test('Test single play with Order AI', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.singlePlay(PlaySize.Size5x5);
      final play = Play.newSinglePlay(header, PlayerType.LocalUser, PlayerType.LocalAi);

      final engine = SinglePlayerGameEngine(play, user, null, () {});

      engine.startGame();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.ReadyToMove);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);



    });

    test('Test multi play, invitor perspective, invitee rejected', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitor);
      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.RemoteOpponentInvited);

      final errorMessage = await PlayStateManager().doAndHandleRejectInvite(play.header);
      expect(errorMessage, null);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      engine.startGame();
      expect(play.currentRole, Role.Chaos);
      expect(play.header.state, PlayState.InvitationRejected);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), true);
      expect(play.isGameOver(), true);

      expect(() => play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0))),
          throwsA(TypeMatcher<Exception>()));

    });

    test('Test multi play, invitor perspective, invitor starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitor);
      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.RemoteOpponentInvited);

      final acceptMessage = AcceptInviteMessage(
          play.header.playId,
          PlayOpener.Invitor,
          "1",
          "Remote User",
          null);

      final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(play.header, acceptMessage);
      expect(errorMessage, null);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      engine.startGame();
      expect(play.currentRole, Role.Chaos);
      expect(play.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();
      expect(play.currentRole, Role.Order);
      expect(play.header.state, PlayState.WaitForOpponent);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), true);

    });

    test('Test multi play, invitor perspective, invitee starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee);
      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.RemoteOpponentInvited);

      final acceptMessage = AcceptInviteMessage(
          play.header.playId,
          PlayOpener.Invitee,
          "1",
          "Remote User",
          Move.placed(GameChip(0), Coordinate(0, 0)));

      final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(play.header, acceptMessage);
      expect(errorMessage, null);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      await engine.opponentMoveReceived(acceptMessage.initialMove!);

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.moved(GameChip(1), Coordinate(0, 0), Coordinate(0, 3)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 2);
      expect(play.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);

    });

    test('Test multi play, invitor perspective, invitor resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee);
      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.RemoteOpponentInvited);

      final acceptMessage = AcceptInviteMessage(
          play.header.playId,
          PlayOpener.Invitee,
          "1",
          "Remote User",
          Move.placed(GameChip(0), Coordinate(0, 0)));

      final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(play.header, acceptMessage);
      expect(errorMessage, null);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      await engine.opponentMoveReceived(acceptMessage.initialMove!);

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(play.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);

      expect(await PlayStateManager().doResign(header, user), null);

      expect(play.header.state, PlayState.Resigned);

      expect(play.isGameOver(), true);
      expect(play.getWinnerRole(), Role.Chaos);
      expect(play.getWinnerPlayer(), PlayerType.RemoteUser);
      expect(engine.isBoardLocked(), true);

    });

    test('Test multi play, invitor perspective, invitee resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final invitorPlay = Play.newMultiPlay(PlayHeader.multiPlayInvitor(
          PlaySize.Size5x5, PlayMode.HyleX, PlayOpener.Invitee));

      final inviteePlay = Play.newMultiPlay(PlayHeader.multiPlayInvitee(
          new InviteMessage.fromHeaderAndUser(
              invitorPlay.header, user),
          null,
          PlayState.InvitationAccepted_ReadyToMove
      ));

      expect(invitorPlay.header.state, PlayState.RemoteOpponentInvited);

      final acceptMessage = AcceptInviteMessage(
          invitorPlay.header.playId,
          PlayOpener.Invitee,
          "1",
          "Remote User",
          Move.placed(GameChip(0), Coordinate(0, 0)));

      final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(invitorPlay.header, acceptMessage);
      expect(errorMessage, null);

      final engine = MultiPlayerGameEngine(invitorPlay, user, null, () {});

      await engine.opponentMoveReceived(acceptMessage.initialMove!);

      expect(invitorPlay.currentRole, Role.Order);
      expect(invitorPlay.currentRound, 1);
      expect(invitorPlay.header.state, PlayState.RemoteOpponentAccepted_ReadyToMove);
      expect(engine.isBoardLocked(), false);

      invitorPlay.applyStaleMove(Move.skipped());
      invitorPlay.commitMove();

      await engine.nextPlayer();

      expect(invitorPlay.currentRole, Role.Chaos);
      expect(invitorPlay.currentRound, 2);
      expect(invitorPlay.header.state, PlayState.WaitForOpponent);
      expect(engine.isBoardLocked(), true);

      expect(await PlayStateManager().handleResignedByRemote(invitorPlay.header, remoteUser), null);

      expect(invitorPlay.header.state, PlayState.OpponentResigned);

     // expect(() => engine.nextPlayer(), throwsA(TypeMatcher<Exception>()));

      expect(invitorPlay.currentRole, Role.Chaos); //TODO whyß race condition in nextPlayer()?
      expect(invitorPlay.currentRound, 2);
      expect(engine.isBoardLocked(), true);
      expect(invitorPlay.isGameOver(), true);
      expect(invitorPlay.getWinnerRole(), Role.Chaos);
      expect(invitorPlay.getWinnerPlayer(), PlayerType.RemoteUser);

    });





    test('Test multi play, invitee perspective, invitor starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playId = "ABC";
      final playOpener = PlayOpener.Invitor;

      final inviteMessage = InviteMessage(
          playId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          "invitorUserId",
          "invitorUserName");

      final header = PlayHeader.multiPlayInvitee(
          inviteMessage, null, PlayState.InvitationPending);

      final errorMessage = await PlayStateManager().doAcceptInvite(header, playOpener);
      expect(errorMessage, null);

      final play = Play.newMultiPlay(header);
      expect(play.header.state, PlayState.InvitationAccepted_WaitForOpponent);

    });

    test('Test multi play, invitee perspective, invitee starts', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playId = "ABC";
      final playOpener = PlayOpener.Invitee;

      final inviteMessage = InviteMessage(
          playId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          "invitorUserId",
          "invitorUserName");

      final header = PlayHeader.multiPlayInvitee(
          inviteMessage, null, PlayState.InvitationPending);

      final errorMessage = await PlayStateManager().doAcceptInvite(header, playOpener);
      expect(errorMessage, null);

      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.InvitationAccepted_ReadyToMove);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      engine.startGame();
      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), true);

    });

    test('Test multi play, invitee perspective, invitee resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playId = "ABC";
      final playOpener = PlayOpener.Invitee;

      final inviteMessage = InviteMessage(
          playId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          "invitorUserId",
          "invitorUserName");

      final header = PlayHeader.multiPlayInvitee(
          inviteMessage, null, PlayState.InvitationPending);

      final errorMessage = await PlayStateManager().doAcceptInvite(header, playOpener);
      expect(errorMessage, null);

      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.InvitationAccepted_ReadyToMove);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      engine.startGame();
      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.isGameOver(), false);
      expect(engine.isBoardLocked(), false);


      expect(await PlayStateManager().doResign(header, user), null);

      expect(play.header.state, PlayState.Resigned);

      expect(play.isGameOver(), true);
      expect(play.getWinnerRole(), Role.Order);
      expect(play.getWinnerPlayer(), PlayerType.RemoteUser);
      expect(engine.isBoardLocked(), true);

    });

    test('Test multi play, invitee perspective, invitor resigns', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final playId = "ABC";
      final playOpener = PlayOpener.Invitee;

      final inviteMessage = InviteMessage(
          playId,
          PlaySize.Size5x5,
          PlayMode.HyleX,
          playOpener,
          "invitorUserId",
          "invitorUserName");

      final header = PlayHeader.multiPlayInvitee(
          inviteMessage, null, PlayState.InvitationPending);

      final errorMessage = await PlayStateManager().doAcceptInvite(header, playOpener);
      expect(errorMessage, null);

      final play = Play.newMultiPlay(header);

      expect(play.header.state, PlayState.InvitationAccepted_ReadyToMove);

      final engine = MultiPlayerGameEngine(play, user, null, () {});

      engine.startGame();
      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(play.isGameOver(), false);
      expect(engine.isBoardLocked(), false);


      expect(await PlayStateManager().doResign(header, user), null);

      expect(play.header.state, PlayState.Resigned);

      expect(play.isGameOver(), true);
      expect(play.getWinnerRole(), Role.Order);
      expect(play.getWinnerPlayer(), PlayerType.RemoteUser);
      expect(engine.isBoardLocked(), true);

    });
    

  });

}

