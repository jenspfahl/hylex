
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../service/MessageService.dart';

class RemoteTestWidget extends StatefulWidget {
  Function(SerializedMessage)? messageHandler;
  RemoteTestWidget({
    super.key, this.messageHandler
  });

  @override
  State<StatefulWidget> createState() {
    return _RemoteTestWidgetState();
  }
}

class _RemoteTestWidgetState extends State<RemoteTestWidget> {
  late PlaySize playSize;
  late PlayMode playMode;
  late PlayOpener playOpener;
  final User remoteUser = User("RemoteTestUser");

  @override
  void initState() {
    super.initState();
    playSize = PlaySize.Size5x5;
    playMode = PlayMode.HyleX;
    playOpener = PlayOpener.InvitedPlayerChooses;
    remoteUser.name = "Remote Test User";

  }
  @override
  Widget build(BuildContext context) {


    List<Widget> children = [
      const Text(""),
      const Text(
        "Simulate remote player invitation",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const Divider(),
      _buildChoseParam("PlaySize", () => playSize, (x) => playSize = x, PlaySize.values),
      _buildChoseParam("PlayMode", () => playMode, (x) => playMode = x, PlayMode.values),
      _buildChoseParam("PlayOpener", () => playOpener, (x) => playOpener = x, PlayOpener.values),

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

  Row _buildChoseParam<T extends Enum>(String paramName, T Function() getValue, Function(T) setValue, List<T> values) {
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

  void _sendMessage({required bool share}) {
    final remoteHeader = PlayHeader.multiPlayInvitor(playSize, playMode, playOpener);
    final message = MessageService().sendRemoteOpponentInvitation(remoteHeader, remoteUser, null, share: share);
    if (!share && widget.messageHandler != null) {
      widget.messageHandler!(message);
    }
  }

}