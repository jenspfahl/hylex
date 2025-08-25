
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/service/StorageService.dart';

import '../../../model/common.dart';
import '../../../model/messaging.dart';
import '../../../model/move.dart';
import '../../../model/play.dart';
import '../../../model/user.dart';
import '../../../service/MessageService.dart';


class RemoteTestWidget extends StatefulWidget {

  PlayHeader? playHeader;
  Function(SerializedMessage)? messageHandler;

  RemoteTestWidget({
    super.key, this.playHeader, this.messageHandler
  });

  @override
  State<StatefulWidget> createState() {
    return _RemoteTestWidgetState();
  }
}

class _RemoteTestWidgetState extends State<RemoteTestWidget> {
  Operation operation = Operation.SendInvite;
  List<Operation> allowedOperations = [Operation.SendInvite];

  late PlaySize playSize;
  late PlayMode playMode;
  late PlayOpener playOpener;
  late User remoteUser;
  
  Play? localPlay;
  PlayHeader? remoteHeader;
  
  Role? role;
  Coordinate? from;
  Coordinate? to;
  GameChip? chip;
  bool skip = false;

  @override
  void initState() {
    super.initState();

    remoteUser = User("RemoteTestUser");
    remoteUser.name = "Remote Test User";

    playOpener = PlayOpener.InvitedPlayerChooses;
    playSize = PlaySize.Size5x5;
    playMode = PlayMode.HyleX;
    
    final localPlayHeader = widget.playHeader;
    if (localPlayHeader != null) {
      
      final playState = localPlayHeader.state;
      if (playState == PlayState.InvitationPending) {
        allowedOperations = [Operation.AcceptInvite, Operation.RejectInvite];
        operation = allowedOperations.first;
      }
      else if (playState.isFinal) {
        throw Exception("Unsupported play state");
      }
      else {
        allowedOperations = [Operation.Move, Operation.Resign];
        operation = allowedOperations.first;

        role = localPlayHeader.actor.getActorRoleFor(playOpener)?.opponentRole ?? Role.Chaos;
        StorageService().loadPlayFromHeader(localPlayHeader)
            .then((localPlay) {
              setState(() {
                if (localPlay != null) {
                  this.localPlay = localPlay;
                  chip = localPlay.currentChip;
                }
              });
        });

        remoteHeader = createRemoteFromLocalHistory(localPlayHeader);

      }
    }

  }
  
  @override
  Widget build(BuildContext context) {

    String header = "Remote player simulation";
    if (widget.playHeader != null) {
      header += " for ${widget.playHeader!.getReadablePlayId()}";
    }
    List<Widget> children = [
      const Text(""),
      Text(
        header,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      const Divider(),
      _buildChoseParam("Operation", () => operation, (x) => operation = x, allowedOperations),
      const Divider(),
      Text(
        _createHeadlineText(operation),
        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const Divider(),
      _buildParams(),
    ];

    children.add(const Divider());
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightGreenAccent),
              onPressed: () {
                SmartDialog.dismiss();
                _sendMessage(share: false);
              },
              child: const Text("APPLY")),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightGreenAccent),
              onPressed: () {
                _sendMessage(share: true);
              },
              child: const Text("SHARE")),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightGreenAccent),
              onPressed: () => SmartDialog.dismiss(),
              child: const Text("CLOSE")),
        ],
      ),
    );

    return MaterialApp(
      home: Container(
        height: 300,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  String _createHeadlineText(Operation operation) {
    switch (operation) {

      case Operation.SendInvite:
        return "Simulate remote player sends an invitation.";
      case Operation.AcceptInvite:
        return "Simulate remote player accepts your invitation.";
      case Operation.RejectInvite:
        return "Simulate remote player rejects your invitation.";
      case Operation.Move:
        return "Simulate remote player moves in current play.";
      case Operation.Resign:
        return "Simulate remote player resigns current play.";
      default: throw Exception("$operation not supported");
    }
  }

  Widget _buildParams() {
    switch (operation) {
      case Operation.SendInvite:
        return _buildSendInviteParams();
      case Operation.AcceptInvite:
        return _buildAcceptInviteParams();
      case Operation.RejectInvite:
        return _buildRejectInviteParams();
      case Operation.Move:
        return _buildMoveParams();
      case Operation.Resign:
        return _buildResignationParams();
      default: throw Exception("$operation not supported");
    }
  }


  Widget _buildSendInviteParams() {
    return Column(
      children: [
        _buildChoseParam("PlaySize", () => playSize, (x) => playSize = x, PlaySize.values),
        _buildChoseParam("PlayMode", () => playMode, (x) => playMode = x, PlayMode.values),
        _buildChoseParam("PlayOpener", () => playOpener, (x) => playOpener = x, PlayOpener.values),

      ],
    );
  }


  Widget _buildAcceptInviteParams() {
    return Column(
      children: [
        _buildChoseParam("PlayOpener", () => playOpener, (x) => playOpener = x, [PlayOpener.Invitee, PlayOpener.Invitor]),
        _buildMoveParams()
      ],
    );
  }

  Widget _buildRejectInviteParams() {
    return const Text("");
  }
  Widget _buildMoveParams() {
   final roleChooser = _buildChoseParam("Role", () => role??Role.Chaos, (x) => role = x, Role.values);

    if (role == Role.Chaos) {
      return Column(
        children: [
          roleChooser,
          _buildChips("Chip to place", () => chip, (x) => chip = x, null),
          _buildCoordinate("Coordinate to place", Role.Chaos, () => to, (x) => to = x, null),
        ],
      );
    }
    else {
      return Column(
        children: [
          roleChooser,
          _buildBoolParam("Skip", () => skip, (b) => skip = b),
          if (!skip)
            _buildChips("Chip to move", () => chip, (x) => chip = x, null),
          if (!skip)
            _buildCoordinate("Coordinate to move from", Role.Order, () => from, (x) => from = x, null),
          if (!skip)
            _buildCoordinate("Coordinate to move to", Role.Order, () => to, (x) => to = x, null),
        ],
      );
    }
  }

  Widget _buildResignationParams() {
    return const Text("");
  }

  Widget _buildChoseParam<T extends Enum>(String paramName, T Function() getValue, Function(T) setValue, List<T> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<T>(
          value: getValue(),
          dropdownColor: Colors.black,
          onChanged: (T? newValue) {
            setState(() {
              if (newValue != null) {
                setValue(newValue);
              }
            });
          },
          items: values.where((e) => !e.name.startsWith("unused")).map((T classType) {
            return DropdownMenuItem<T>(
                value: classType,
                child: Text(classType.name,
                  style: TextStyle(
                      color: getValue() == classType ? Colors.lightGreenAccent : Colors.white,
                      backgroundColor: Colors.black,
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildBoolParam(String paramName, bool Function() getValue, Function(bool) setValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        Checkbox(value: getValue(), onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              setValue(newValue);
            });
          }
        })
      ],
    );
  }

  Widget _buildCoordinate(String paramName, Role forRole, Coordinate? Function() getValue, Function(Coordinate) setValue, List<Move>? allowedMoves) {
    final coordinates = _createAllCoordinates(playSize.toDimension());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<Coordinate>(
          value: getValue() ?? coordinates.first,
          dropdownColor: Colors.black,
          onChanged: (newValue) {
            setState(() {
              if (newValue != null) {
                setValue(newValue);
              }
            });
          },
          items: coordinates.map((coordinate) {
            return DropdownMenuItem<Coordinate>(
                value: coordinate,
                child: Text(coordinate.toReadableCoordinates(),
                  style: TextStyle(
                      color: /*getValue() == move ? Colors.lightGreenAccent : */Colors.white,
                      backgroundColor: Colors.black,
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
            );
          }).toList(),
        )
      ],
    );
  }



  Widget _buildChips(String paramName, GameChip? Function() getValue, Function(GameChip) setValue, List<GameChip>? allowedChips) {
    if (allowedChips == null) {
      allowedChips = [];
      final chipCount = widget.playHeader?.dimension ?? 0;
      for (int i=0; i < chipCount; i++) {
        allowedChips.add(new GameChip(i));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<GameChip>(
          value: getValue() ?? allowedChips.first,
          dropdownColor: Colors.black,
          onChanged: (newValue) {
            setState(() {
              if (newValue != null) {
                setValue(newValue);
              }
            });
          },
          items: allowedChips.map((chip) {
            return DropdownMenuItem<GameChip>(
                value: chip,
                child: Text(chip.getChipName(),
                  style: TextStyle(
                      color: getValue() == chip ? Colors.lightGreenAccent : Colors.white,
                      backgroundColor: Colors.black,
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
            );
          }).toList(),
        )
      ],
    );
  }

  
  void _sendMessage({required bool share}) {
    final finalRemoteHeader = remoteHeader ?? PlayHeader.multiPlayInvitor(playSize, playMode, playOpener);
    
    SerializedMessage message = _createMessage(finalRemoteHeader, share);
    if (!share && widget.messageHandler != null) {
      widget.messageHandler!(message);
    }
  }

  SerializedMessage _createMessage(PlayHeader remoteHeader, bool share) {
    switch(operation) {

      case Operation.SendInvite:
        return MessageService().sendRemoteOpponentInvitation(remoteHeader, remoteUser, null, share: share);
      case Operation.AcceptInvite:
        return MessageService().sendInvitationAccepted(remoteHeader, remoteUser, _createMove(), null, share: share);
      case Operation.RejectInvite:
        return MessageService().sendInvitationRejected(remoteHeader, remoteUser, null, share: share);
      case Operation.Move:
        return MessageService().sendMove(remoteHeader, remoteUser, _createMove(), null, share: share);
      case Operation.Resign:
        return MessageService().sendResignation(remoteHeader, remoteUser, null, share: share);
      default: throw Exception("$operation not supported");
    }
  }

  Move _createMove() {
    return Move(skipped: skip, from: from, to: to, chip: chip);
  }

  List<Coordinate> _createAllCoordinates(int dimension) {
    final List<Coordinate> coordinates = [];
    for (int x = 0; x < dimension; x++) {
      for (int y = 0; y < dimension; y++) {
        coordinates.add(Coordinate(x, y));
      }
    }
    
    return coordinates;
    
  }

  PlayHeader? createRemoteFromLocalHistory(PlayHeader localPlayHeader) {

    final playHeader = PlayHeader.internal(
        localPlayHeader.playId,
        playSize,
        playMode,
        PlayState.Initialised, //TODO
        localPlayHeader.currentRound,
        localPlayHeader.actor.opponentActor(),
        playOpener,
        remoteUser.id,
        remoteUser.name);

    final lastLocalMessage = localPlayHeader.commContext.messageHistory.lastOrNull?.serializedMessage;
    playHeader.commContext.predecessorMessage = lastLocalMessage;

    return playHeader;
  }

}