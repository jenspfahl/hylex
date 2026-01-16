import 'package:bits/bits.dart';
import 'package:hyle_x/l10n/app_localizations.dart';
import 'package:hyle_x/l10n/app_localizations_en.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/model/move.dart';
import 'package:hyle_x/model/user.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:test/test.dart';

Future<void> main() async {

  group("Test bits", () {

    test('Test flags', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writer.writeBit(true);
      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");

    });

    test('Test ints', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeInt(writer, 0, 5);
      writeInt(writer, 1, 5);
      writeInt(writer, 2, 5);
      writeInt(writer, 3, 5);
      writeInt(writer, 4, 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 5 * 3);

      expect(readInt(reader, 5), 0);
      expect(readInt(reader, 5), 1);
      expect(readInt(reader, 5), 2);
      expect(readInt(reader, 5), 3);
      expect(readInt(reader, 5), 4);
    });

    test('Test nullable ints', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeNullableInt(writer, 0, 5);
      writeNullableInt(writer, 1, 5);
      writeNullableInt(writer, 2, 5);
      writeNullableInt(writer, 3, 5);
      writeNullableInt(writer, 4, 5);
      writeNullableInt(writer, null, 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 5 * 4 + 1);

      expect(readNullableInt(reader, 5), 0);
      expect(readNullableInt(reader, 5), 1);
      expect(readNullableInt(reader, 5), 2);
      expect(readNullableInt(reader, 5), 3);
      expect(readNullableInt(reader, 5), 4);
      expect(readNullableInt(reader, 5), null);
    });

    test('Test enums', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeEnum(writer, Operation.values, Operation.Move);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 4);

      expect(readEnum(reader, Operation.values), Operation.Move);
    });

    test('Test nullable enums', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeNullableEnum(writer, Operation.values, null as Operation?);
      writeNullableEnum(writer, Operation.values, Operation.Move);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 5 + 1);

      expect(readNullableEnum(reader, Operation.values), null);
      expect(readNullableEnum(reader, Operation.values), Operation.Move);
    });

    test('Test version', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeVersion(writer, 1);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 4);

      expect(readVersion(reader), 1);
    });

    test('Test round', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeRound(writer, 25, 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 5);

      expect(readRound(reader, 5), 25);
    });

    test('Test chip', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeChip(writer, GameChip(3), 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 3);

      expect(readChip(reader, 5), GameChip(3));
    });

    test('Test coordinate', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeCoordinate(writer, Coordinate(4,1), 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 1 * 5);

      expect(readCoordinate(reader, 5), Coordinate(4,1));
    });

    test('Test move', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeMove(writer, Move.skipped(), 5);
      writeMove(writer, Move.placed(GameChip(3), Coordinate(4, 1)), 5);
      writeMove(writer, Move.movedForMessaging(Coordinate(4, 1), Coordinate(0, 1)), 5);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 2 + 9 + 11);

      expect(readMove(reader, 5), Move.skipped());
      expect(readMove(reader, 5), Move.placed(GameChip(3), Coordinate(4, 1)));
      expect(readMove(reader, 5), Move.movedForMessaging(Coordinate(4, 1), Coordinate(0, 1)));
    });

    test('Test Strings', () {
      final buffer = BitBuffer();

      final writer = buffer.writer();
      writeString(writer, "", maxNameLength);
      writeString(writer, "aBcDeFgHiJkLmNoPqRsTuVwXyZ-_/345xxx", maxNameLength);

      print(" b64: ${buffer.toBase64()}");
      print(" size: ${buffer.getSize()}");
      print(" free: ${buffer.getFreeBits()}");
      final reader = buffer.reader();

      expect(buffer.getSize(), 6 + 6 + 6 * maxNameLength);

      expect(readString(reader), "");
      expect(readString(reader), "aBcDeFgHiJkLmNoPqRsTuVwXyZ-  345");
    });

  });

  final invitorUser = User();
  final inviteeUser = User();

  await invitorUser.awaitKeys();
  await inviteeUser.awaitKeys();

  group("Test messaging", () {

    final invitorContext = CommunicationContext();
    final invitorUserId = invitorUser.id;
    final invitorUserName = "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz";

    final inviteeContext = CommunicationContext();
    final inviteeUserId = inviteeUser.id;
    final inviteePlayerName = "Remote opponent name";
    
    final playId = generateRandomString(playIdLength);
    final playSize = PlaySize.Size7x7;
    final playMode = PlayMode.HyleX;
    final playOpener = PlayOpener.Invitor;

    test('Test send invitation', () async {

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
          invitationMessage.serializeWithContext(invitorContext, invitorUser.userSeed));


      // receive invite
      final deserializedInviteMessage = (await serializedInvitationMessage
          .deserialize(inviteeContext, null, _l10n()))
          .$1 as InviteMessage;

      inviteeContext.registerReceivedMessage(serializedInvitationMessage);

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
    
    
    test('Test accept invitation', () async {

      print("----- accept invite --------");

      // accept and respond to invite
      final playOpenerDecision = PlayOpener.Invitee;
      final move = Move.placed(GameChip(1), Coordinate(3, 5));
      
      final acceptInviteMessage = AcceptInviteMessage(
        playId,
        playSize,
        playOpenerDecision,
        inviteeUserId,
        inviteePlayerName,
        move,
      );

      final serializedAcceptInviteMessage = _send(acceptInviteMessage.serializeWithContext(inviteeContext, "seed"));


      // receive accept invite
      final deserializedAcceptInviteMessage = (await serializedAcceptInviteMessage.deserialize(invitorContext, null, _l10n())).$1 as AcceptInviteMessage;

      invitorContext.registerReceivedMessage(serializedAcceptInviteMessage);

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

    test('Test first invitor move', () async {

      print("----- first invitor move --------");

      // first order move from invitor player
      final round = 1;
      final move = Move.movedForMessaging(Coordinate(3, 5), Coordinate(0, 5));

      final firstInvitorPlayerMoveMessage = MoveMessage(
        playId,
        playSize,
        round,
        move,
      );

      final serializedMoveMessage = _send(firstInvitorPlayerMoveMessage.serializeWithContext(invitorContext, "seed"));

      final deserializedMoveMessage = (await serializedMoveMessage.deserialize(inviteeContext, null, _l10n())).$1 as MoveMessage;

      inviteeContext.registerReceivedMessage(serializedMoveMessage);

      print("playId: ${deserializedMoveMessage.playId}");
      print("round: ${deserializedMoveMessage.round}");
      print("move: ${deserializedMoveMessage.move}");
      print("-------------");

      expect(deserializedMoveMessage.playId, playId);
      expect(deserializedMoveMessage.round, round);
      expect(deserializedMoveMessage.move, move);
    });
  });

  group("Test messaging with signing", () {

    final invitorContext = CommunicationContext();
    final invitorUserId = invitorUser.id;
    final invitorUserName = "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz";

    final inviteeContext = CommunicationContext();
    final inviteeUserId = inviteeUser.id;
    final inviteePlayerName = "Remote opponent name";

    final playId = generateRandomString(playIdLength);
    final playSize = PlaySize.Size7x7;
    final playMode = PlayMode.HyleX;
    final playOpener = PlayOpener.Invitor;

    test('Test send invitation', () async {

      print("----- send signed invitation --------");


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
          invitationMessage.serializeWithContext(invitorContext, invitorUser.userSeed));

      await serializedInvitationMessage
          .signMessage(invitorUserId, invitorUser.userSeed);

      print("auth sig: ${serializedInvitationMessage.auth}");

      // receive invite
      final deserializedInviteMessage = (await serializedInvitationMessage
          .deserialize(inviteeContext, invitorUserId, _l10n()))
          .$1 as InviteMessage;

      inviteeContext.registerReceivedMessage(serializedInvitationMessage);

      expect(deserializedInviteMessage.playId, playId);
      expect(deserializedInviteMessage.playSize, playSize);
      expect(deserializedInviteMessage.playMode, playMode);
      expect(deserializedInviteMessage.playOpener, playOpener);
      expect(deserializedInviteMessage.invitorUserId, invitorUserId);
      expect(deserializedInviteMessage.invitorUserName,
          normalizeString(invitorUserName, maxNameLength));

    });

    test('Test accept invitation', () async {

      print("----- accept signed invite --------");

      // accept and respond to invite
      final playOpenerDecision = PlayOpener.Invitee;
      final move = Move.placed(GameChip(1), Coordinate(3, 5));

      final acceptInviteMessage = AcceptInviteMessage(
        playId,
        playSize,
        playOpenerDecision,
        inviteeUserId,
        inviteePlayerName,
        move,
      );

      final serializedAcceptInviteMessage = _send(acceptInviteMessage.serializeWithContext(inviteeContext, "seed"));

      await serializedAcceptInviteMessage
          .signMessage(inviteeUserId, inviteeUser.userSeed);

      print("auth sig: ${serializedAcceptInviteMessage.auth}");

      // receive accept invite
      final deserializedAcceptInviteMessage = (await serializedAcceptInviteMessage.deserialize(invitorContext, inviteeUserId, _l10n())).$1 as AcceptInviteMessage;

      invitorContext.registerReceivedMessage(serializedAcceptInviteMessage);

      expect(deserializedAcceptInviteMessage.playId, playId);
      expect(deserializedAcceptInviteMessage.playOpenerDecision, playOpenerDecision);
      expect(deserializedAcceptInviteMessage.inviteeUserId, inviteeUserId);
      expect(deserializedAcceptInviteMessage.inviteeUserName, inviteePlayerName);
      expect(deserializedAcceptInviteMessage.initialMove, move);


    });

  });

  group("Test utils", () {
    test('Test URL extract', () {
      expect(extractAppLinkFromString("https://hx.jepfa.de"), null);
      expect(extractAppLinkFromString("https://hx.jepfa.de/d/"), null);
      expect(extractAppLinkFromString("https://hx.jepfa.de/e/abc/def"), null);
      expect(extractAppLinkFromString("https://hx.jepfa.de/d/abc/def"), Uri.parse("https://hx.jepfa.de/d/abc/def"));
      expect(extractAppLinkFromString("https://hx.jepfa.de/d/abc/def/"), Uri.parse("https://hx.jepfa.de/d/abc/def"));
      expect(extractAppLinkFromString("bla bla https://hx.jepfa.de/d/abc/def/ bla bla"), Uri.parse("https://hx.jepfa.de/d/abc/def"));
      expect(extractAppLinkFromString("bla bla https://hx.jepfa.de/d/abc/def/xyz bla bla"), Uri.parse("https://hx.jepfa.de/d/abc/def/xyz"));
      expect(extractAppLinkFromString("bla bla https://hx.jepfa.de/d/abc/def/xyz/ bla bla"), Uri.parse("https://hx.jepfa.de/d/abc/def/xyz"));
    });

    test('Test SerializedMessage from URL', () {
      expect(SerializedMessage.fromString("https://hx.jepfa.de"), null);
      expect(SerializedMessage.fromString("https://hx.jepfa.de/d/payload/chainSignature"), SerializedMessage("payload", "chainSignature"));
      expect(SerializedMessage.fromString("https://hx.jepfa.de/d/payload/chainSignature/authSigh"), SerializedMessage("payload", "chainSignature", "authSig"));
     });
  });
}

AppLocalizations _l10n() {
  return AppLocalizationsEn();
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

