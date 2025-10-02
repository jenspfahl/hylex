
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/dialogs.dart';

import '../../../model/common.dart';
import '../../../model/messaging.dart';
import '../../../model/move.dart';
import '../../../model/play.dart';
import '../../../model/user.dart';
import '../../../service/MessageService.dart';


class RemoteTestWidget extends StatefulWidget {

  PlayHeader? playHeader;
  Function(SerializedMessage)? messageHandler;
  BuildContext rootContext;

  RemoteTestWidget({
    super.key, this.playHeader, this.messageHandler, required this.rootContext
  });

  @override
  State<StatefulWidget> createState() {
    return _RemoteTestWidgetState();
  }
}

class _RemoteTestWidgetState extends State<RemoteTestWidget> {
  late List<Operation> allowedRemoteOperations;
  late Operation operation;
  late User remoteUser;


  late PlaySize playSize = PlaySize.Size5x5;
  late PlayMode playMode = PlayMode.HyleX;
  late PlayOpener playOpener = PlayOpener.InviteeChooses;

  Play? localPlay;

  Role role = Role.Chaos;
  Coordinate from = Coordinate(0, 0);
  Coordinate to = Coordinate(0, 0);
  GameChip? chip;
  bool skip = false;

  @override
  void initState() {
    super.initState();

    remoteUser = User("RemoteTestUser");
    remoteUser.name = "Remote Test User";
    
    final localPlayHeader = widget.playHeader;
    if (localPlayHeader == null) {
      allowedRemoteOperations = [Operation.SendInvite];
    }
    else {

      final localPlayState = localPlayHeader.state;

      if (localPlayState == PlayState.RemoteOpponentInvited) {
        allowedRemoteOperations = [Operation.AcceptInvite, Operation.RejectInvite];
      }
      else if (localPlayState == PlayState.InvitationPending) {
        allowedRemoteOperations = [];
      }
      else if (!localPlayState.isFinal) {
        allowedRemoteOperations = [Operation.Move, Operation.Resign];

        final opponentRole = localPlayHeader.getLocalRoleForMultiPlay()?.opponentRole;
        if (opponentRole != null) {
          role = opponentRole;
        }
        StorageService().loadPlayFromHeader(localPlayHeader)
            .then((localPlay) {
              setState(() {
                if (localPlay != null) {
                  this.localPlay = localPlay;
                  chip = localPlay.currentChip;
                }
              });
        });
      }
      else  {
        allowedRemoteOperations = [];

      }
    }

    operation = allowedRemoteOperations.firstOrNull ?? Operation.SendInvite;
  }
  
  @override
  Widget build(BuildContext context) {

    String header = "Remote player simulation";
    String subHeader = [playOpener, playMode, playSize].toString();
    if (widget.playHeader != null) {
      header += " for ${widget.playHeader!.getReadablePlayId()}";
      subHeader = widget.playHeader.toString();
      subHeader += " ${widget.playHeader!.getLocalRoleForMultiPlay()}";
    }
    List<Widget> children = [
      const Text(""),
      Text(
        header,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      const Divider(),
      Text(
        subHeader,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      const Divider(),
      _buildChoseParam(
          "Operation",
              () => operation,
              (x) => operation = x,
          Operation.values,
          allowedRemoteOperations),
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
                _checkAndSendRemoteMessage(share: false, context: widget.rootContext);
              },
              child: const Text("APPLY")),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightGreenAccent),
              onPressed: () {
                SmartDialog.dismiss();
                _checkAndSendRemoteMessage(share: true, context: widget.rootContext);
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
      home: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: DIALOG_BG,
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
      ),
    );
  }

  String _createHeadlineText(Operation operation) {
    switch (operation) {

      case Operation.SendInvite:
        return "Simulate the remote player sends an invitation.";
      case Operation.AcceptInvite:
        return "Simulate the remote player accepts your invitation.";
      case Operation.RejectInvite:
        return "Simulate the remote player rejects your invitation.";
      case Operation.Move:
        return "Simulate the remote player moves a chip in current play.";
      case Operation.Resign:
        return "Simulate the remote player resigns current play.";
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
        _buildChoseParam("PlaySize", () => playSize, (x) => playSize = x, PlaySize.values, PlaySize.values),
        _buildChoseParam("PlayMode", () => playMode, (x) => playMode = x, PlayMode.values, PlayMode.values),
        _buildChoseParam("PlayOpener", () => playOpener, (x) => playOpener = x, PlayOpener.values, PlayOpener.values),

      ],
    );
  }


  Widget _buildAcceptInviteParams() {
    return Column(
      children: [
        _buildChoseParam(
            "PlayOpener",
                () => playOpener,
                (x) => playOpener = x,
            PlayOpener.values,
            [PlayOpener.Invitee, PlayOpener.Invitor]),
        _buildMoveParams()
      ],
    );
  }

  Widget _buildRejectInviteParams() {
    return const Text("");
  }
  Widget _buildMoveParams() {
    final remoteRole = widget.playHeader?.getLocalRoleForMultiPlay()?.opponentRole;
    final roleChooser = _buildChoseParam(
        "Role", 
            () => role,
            (x) => role = x, 
        Role.values,
        [remoteRole??Role.Chaos]
    );

    if (role == Role.Chaos) {
      return Column(
        children: [
          roleChooser,
          _buildChips("Chip to place", () => chip, (x) => chip = x),
          _buildCoordinate("Coordinate to place", true, () => to, (x) => to = x),
        ],
      );
    }
    else {
      return Column(
        children: [
          roleChooser,
          _buildBoolParam("Skip", () => skip, (b) => skip = b),
          if (!skip)
            _buildCoordinate(
                "Coordinate to move from",
                false,
                    () => from,
                    (x) => from = x),
          if (!skip)
            _buildCoordinate(
                "Coordinate to move to",
                true,
                    () => to,
                    (x) => to = x
            ),
        ],
      );
    }
  }

  Widget _buildResignationParams() {
    return const Text("");
  }

  Widget _buildChoseParam<T extends Enum>(
      String paramName, 
      T Function() getValue, 
      Function(T) setValue, 
      List<T> values,
      List<T> legalValues,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<T>(
          value: getValue(),
          dropdownColor: DIALOG_BG,
          onChanged: (T? newValue) {
            setState(() {
              if (newValue != null) {
                setValue(newValue);
              }
            });
          },
          items: values.where((e) => !e.name.startsWith("unused")).map((T value) {
            return DropdownMenuItem<T>(
                value: value,
                child: Text(value.name,
                  style: TextStyle(
                      decoration: legalValues.contains(value) ? TextDecoration.none : TextDecoration.lineThrough,
                      color: getValue() == value ? Colors.lightGreenAccent : Colors.white,
                      backgroundColor: DIALOG_BG,
                      decorationColor: getValue() == value ? Colors.lightGreenAccent : Colors.white,
                      decorationThickness: 2.0,
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

  Widget _buildCoordinate(
      String paramName, 
      bool freeCellsAreLegal,
      Coordinate? Function() getValue,
      Function(Coordinate) setValue
      ) {
    final coordinates = _createAllCoordinates(playSize.dimension);
    var legalCoordinates = coordinates;

    if (localPlay != null) {
      if (freeCellsAreLegal) {
        legalCoordinates = localPlay!.matrix.streamFreeSpots().map((s) => s.where).toList();
      }
      else {
        legalCoordinates = localPlay!.matrix.streamOccupiedSpots().map((s) => s.where).toList();
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<Coordinate>(
          value: getValue() ?? coordinates.first,
          dropdownColor: DIALOG_BG,
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
                      decoration: legalCoordinates.contains(coordinate) ? TextDecoration.none : TextDecoration.lineThrough,
                      color: getValue() == coordinate ? Colors.lightGreenAccent : Colors.white,
                      backgroundColor: DIALOG_BG,
                      decorationColor: getValue() == coordinate ? Colors.lightGreenAccent : Colors.white,
                      decorationThickness: 2.0,
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
            );
          }).toList(),
        )
      ],
    );
  }



  Widget _buildChips(
      String paramName, 
      GameChip? Function() getValue, 
      Function(GameChip) setValue, 
) {
    final chipCount = widget.playHeader?.dimension ?? 0;
    final allChips = <GameChip>[];
    for (int i=0; i < chipCount; i++) {
      allChips.add(new GameChip(i));
    }

    var legalChips = <GameChip>[];
    if (widget.playHeader?.getLocalRoleForMultiPlay()?.opponentRole == Role.Chaos) {
      if (widget.playHeader!.state == PlayState.InvitationAccepted_WaitForOpponent) {
        // that means remote user is Chaos and every chip can be drawn
        legalChips.addAll(allChips);
      }
      else if (localPlay != null) {
        final chipsWithStock = localPlay!.stock.getStockEntries()
            .where((e) => e.amount > 0)
            .map((e) => e.chip);
        legalChips.addAll(chipsWithStock);
      }
    }

    final firstValue = getValue() ?? allChips.first;
    setValue(firstValue);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$paramName:",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 14),
        ),
        DropdownButton<GameChip>(
          value: firstValue,
          dropdownColor: DIALOG_BG,
          onChanged: (newValue) {
            setState(() {
              if (newValue != null) {
                setValue(newValue);
              }
            });
          },
          items: allChips.map((chip) {
            return DropdownMenuItem<GameChip>(
                value: chip,
                child: Text(chip.getChipName(),
                  style: TextStyle(
                      decoration: legalChips.contains(chip) == true ? TextDecoration.none : TextDecoration.lineThrough,
                      color: getValue() == chip ? Colors.lightGreenAccent : Colors.white,
                      backgroundColor: DIALOG_BG,
                      decorationColor: getValue() == chip ? Colors.lightGreenAccent : Colors.white,
                      decorationThickness: 2.0,
                      fontWeight: FontWeight.bold, fontSize: 14),
                )
            );
          }).toList(),
        )
      ],
    );
  }

  
  void _checkAndSendRemoteMessage({required bool share, required BuildContext context}) {
    if (localPlay != null) {
      final result = localPlay!.validateMove(_createMove());
      if (result != null) {
        showChoiceDialog(result, 
            firstString: "IGNORE", 
            firstHandler: () => _sendRemoteMessage(share, context),
            secondString: "CANCEL", 
            secondHandler: () => SmartDialog.dismiss());
        return;
      }
      else {
        _sendRemoteMessage(share, context);
      }
    }
    else {
      _sendRemoteMessage(share, context);
    }
  }

  void _sendRemoteMessage(bool share, BuildContext context) {
    final remoteHeader = widget.playHeader != null
        ? createRemoteFromLocalHistory(widget.playHeader!)
        : PlayHeader.multiPlayInvitor(playSize, playMode, playOpener);

    debugPrint("Remote header:\n$remoteHeader");
    try {
      SerializedMessage message = _createRemoteMessage(remoteHeader, share, context);
      if (!share && widget.messageHandler != null) {
        widget.messageHandler!(message);
      }
    } on Exception catch(e) {
      print(e);
      showAlertDialog("An error occurred: ${e.toString()}");
    }
  }

  SerializedMessage _createRemoteMessage(PlayHeader remoteHeader, bool share, BuildContext context) {
    switch(operation) {

      case Operation.SendInvite:
        return MessageService().sendRemoteOpponentInvitation(remoteHeader, remoteUser, context, null, share: share);
      case Operation.AcceptInvite:
        return MessageService().sendInvitationAccepted(remoteHeader, remoteUser, _createMove(), context, null, share: share);
      case Operation.RejectInvite:
        return MessageService().sendInvitationRejected(remoteHeader, remoteUser, context, null, share: share);
      case Operation.Move:
        return MessageService().sendMove(remoteHeader, remoteUser, _createMove(), context, null, share: share);
      case Operation.Resign:
        return MessageService().sendResignation(remoteHeader, remoteUser, context, null, share: share);
      default: throw Exception("$operation not supported");
    }
  }

  Move _createMove() {
    if (chip != null && role == Role.Chaos) {
      return Move.placed(chip!, to);
    }
    else if (role == Role.Order) {
      return Move(skipped: skip || from == to, from: from, to: to, chip: chip);
    }
    else {
      throw Exception("Illegal move data for $role, $chip, $from, $to");
    }
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

  PlayHeader createRemoteFromLocalHistory(PlayHeader localPlayHeader) {

    final playHeader = PlayHeader.internal(
        localPlayHeader.playId,
        localPlayHeader.playSize,
        localPlayHeader.playMode,
        PlayState.Initialised,
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