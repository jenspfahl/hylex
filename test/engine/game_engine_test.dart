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

    test('Test single play', () async {

      TestWidgetsFlutterBinding.ensureInitialized();

      final header = PlayHeader.singlePlay(PlaySize.Size5x5);
      final play = Play.newSinglePlay(header, PlayerType.LocalUser, PlayerType.LocalUser);

      final engine = SinglePlayerGameEngine(play, user, null, () {});

      engine.startGame();

      expect(play.currentRole, Role.Chaos);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
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
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), true);

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
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.placed(play.currentChip!, Coordinate(0, 0)));
      play.commitMove();

      await engine.nextPlayer();

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

      engine.opponentMoveReceived(acceptMessage.initialMove!);

      expect(play.currentRole, Role.Order);
      expect(play.currentRound, 1);
      expect(engine.isBoardLocked(), false);

      play.applyStaleMove(Move.moved(GameChip(1), Coordinate(0, 0), Coordinate(0, 3)));
      play.commitMove();

      await engine.nextPlayer();

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

    });
    

  });

}

