import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/model/move.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:test/test.dart';

void main() {
  group("Test messaging", () {

    final invitorContext = CommunicationContext();
    final invitorUserId = generateRandomString(userIdLength);
    final invitorUserName = "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz";

    final inviteeContext = CommunicationContext();
    final inviteeUserId = generateRandomString(userIdLength);
    final inviteePlayerName = "Remote opponent name";
    
    final playId = generateRandomString(playIdLength);
    final playSize = PlaySize.Size7x7;
    final playMode = PlayMode.HyleX;
    final playOpener = PlayOpener.Invitor;

    test('Test send invitation', () {

      print("----- send invitation --------");


      // send invite
      final invitationMessage = InviteMessage(
          playId,
          playSize,
          playMode,
          playOpener,
          invitorUserId,
          invitorUserName
      );

      final serializedInvitationMessage = _send(
          invitationMessage.serializeWithContext(invitorContext));


      // receive invite
      final deserializedInviteMessage = serializedInvitationMessage
          .deserialize(inviteeContext)
          .$1 as InviteMessage;
      print("playId: ${deserializedInviteMessage.playId}");
      print("playSize: ${deserializedInviteMessage.playSize}");
      print("playMode: ${deserializedInviteMessage.playMode}");
      print("playOpener: ${deserializedInviteMessage.playOpener}");
      print("userId: ${deserializedInviteMessage.invitorUserId}");
      print("invitorName: ${deserializedInviteMessage.invitorUserName}");

      expect(deserializedInviteMessage.playId, playId);
      expect(deserializedInviteMessage.playSize, playSize);
      expect(deserializedInviteMessage.playMode, playMode);
      expect(deserializedInviteMessage.playOpener, playOpener);
      expect(deserializedInviteMessage.invitorUserId, invitorUserId);
      expect(deserializedInviteMessage.invitorUserName,
          normalizeString(invitorUserName, maxNameLength));
      
    });
    
    
    test('Test accept invitation', () {

      print("----- accept invite --------");

      // accept and respond to invite
      final playOpenerDecision = PlayOpener.Invitee;
      final move = Move.placed(GameChip(1), Coordinate(3, 5));
      
      final acceptInviteMessage = AcceptInviteMessage(
        playId,
        playOpenerDecision,
        inviteeUserId,
        inviteePlayerName,
        move,
      );

      final serializedAcceptInviteMessage = _send(acceptInviteMessage.serializeWithContext(inviteeContext));


      // receive accept invite
      final deserializedAcceptInviteMessage = serializedAcceptInviteMessage.deserialize(invitorContext).$1 as AcceptInviteMessage;

      print("playId: ${deserializedAcceptInviteMessage.playId}");
      print("playOpener: ${deserializedAcceptInviteMessage.playOpenerDecision}");
      print("inviteeUserId: ${deserializedAcceptInviteMessage.inviteeUserId}");
      print("inviteeUserName: ${deserializedAcceptInviteMessage.inviteeUserName}");
      print("initialMove: ${deserializedAcceptInviteMessage.initialMove}");

      expect(deserializedAcceptInviteMessage.playId, playId);
      expect(deserializedAcceptInviteMessage.playOpenerDecision, playOpenerDecision);
      expect(deserializedAcceptInviteMessage.inviteeUserId, inviteeUserId);
      expect(deserializedAcceptInviteMessage.inviteeUserName, inviteePlayerName);
      expect(deserializedAcceptInviteMessage.initialMove, move);


    });

    test('Test first invitor move', () {

      print("----- first invitor move --------");

      // first order move from invitor player
      final round = 1;
      final move = Move.movedForMessaging(Coordinate(3, 5), Coordinate(0, 5));

      final firstInvitorPlayerMoveMessage = MoveMessage(
        playId,
        round,
        move,
      );

      final serializedMoveMessage = _send(firstInvitorPlayerMoveMessage.serializeWithContext(invitorContext));

      final deserializedMoveMessage = serializedMoveMessage.deserialize(inviteeContext).$1 as MoveMessage;

      print("playId: ${deserializedMoveMessage.playId}");
      print("round: ${deserializedMoveMessage.round}");
      print("move: ${deserializedMoveMessage.move}");
      print("-------------");

      expect(deserializedMoveMessage.playId, playId);
      expect(deserializedMoveMessage.round, round);
      expect(deserializedMoveMessage.move, move);

    });
  });

}





SerializedMessage _send(SerializedMessage message) {
  print("|");
  print("|");
  print("payload = ${message.payload}");
  print("signature = ${message.signature}");
  print("url = ${message.toUrl()}");
  print("|");
  print("|");
  print("|");
  print("V");

  return message;
}

