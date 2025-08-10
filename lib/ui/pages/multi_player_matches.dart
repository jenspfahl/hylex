import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/StorageService.dart';

import '../../model/play.dart';
import '../../model/user.dart';
import '../dialogs.dart';
import '../ui_utils.dart';
import 'game_ground.dart';


class MultiPlayerMatches extends StatefulWidget {

  final User user;

  const MultiPlayerMatches(this.user, {super.key});

  @override
  State<MultiPlayerMatches> createState() => _MultiPlayerMatchesState();
}

class _MultiPlayerMatchesState extends State<MultiPlayerMatches> {



  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Continue a match')),
        body: FutureBuilder<List<PlayHeader>>(
            future: StorageService().loadAllPlayHeaders(),
            builder: (BuildContext context,
                AsyncSnapshot<List<PlayHeader>> snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return SingleChildScrollView(
                  child: Container(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: snapshot.data!.map(_buildPlayLine).toList(),
                      ),
                    ),
                  ),
                );

              }
              else if (snapshot.hasError) {
                print("loading error: ${snapshot.error}");
                return Center(child: Text("Cannot load stored matches!"));
              }
              else {
                return Center(child: Text("No stored matches!"));
              }
            })
    );

  }

  Widget _buildPlayLine(PlayHeader playHeader) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      child: Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(), left: BorderSide())
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    buildAlertDialog('Here you will see soon details about this match', type: NotifyType.error);
                  },
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: playHeader.state.toColor(),
                            maxRadius: 6,
                          ),
                          Text(
                              " " + _getHeaderTitleLine(playHeader),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(_getHeaderBodyLine(playHeader), style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                      Text("${playHeader.state.toMessage()}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: [

                          Visibility(
                            visible: playHeader.state == PlayState.WaitForOpponent || playHeader.state == PlayState.ReadyToMove,
                            child: IconButton(onPressed: (){
                              _startMultiPlayerGame(
                                  context, playHeader);
                            }, icon: Icon(Icons.not_started_outlined)),
                          ),
                          IconButton(onPressed: (){
                            MessageService().sendCurrentPlayState(playHeader, widget.user, null);
                          }, icon: Icon(Icons.send)),
                          IconButton(onPressed: (){
                            //TODO send as QR code
                            buildAlertDialog('Showing next move as QR code not yet implemented!', type: NotifyType.error);
                          }, icon: Icon(Icons.qr_code_2)),
                          IconButton(onPressed: (){
                            ask("Are you sure to remove this match ${playHeader.getReadablePlayId()}? You wont be able to continue this match once removed.", () {
                              setState(() {
                                StorageService().deletePlayHeaderAndPlay(playHeader.playId);
                              });
                            });
                          }, icon: Icon(Icons.delete)),
                        ]),
                  )
                ])
            ],
          ),
        ),),
    );
  }


  String _getHeaderTitleLine(PlayHeader playHeader) {
    if (playHeader.opponentName != null) {
      return "${playHeader.getReadablePlayId()} against ${playHeader.opponentName}";
    }
    else {
      return playHeader.getReadablePlayId();
    }
  }

  String _getHeaderBodyLine(PlayHeader playHeader) {
    final actorRole = playHeader.actor.getActorRoleFor(playHeader.playOpener);
    var roleString = "";
    if (actorRole != null) {
      roleString = "as ${actorRole.name}";
    }
    final sb = StringBuffer("${playHeader.dimension} x ${playHeader.dimension}, Mode: ${playHeader.playMode.name}, $roleString");
    if (playHeader.currentRound > 0) {
      sb.write(", Round ${playHeader.currentRound} of ${playHeader.maxRounds}");
    }
    return sb.toString();
  }

  Future<void> _startMultiPlayerGame(BuildContext context, PlayHeader header) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    final play = await StorageService().loadPlayFromHeader(header);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              widget.user,
              play ?? Play.newMultiPlay(header));
        }));
  }

}
