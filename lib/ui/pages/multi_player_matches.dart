import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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
              else {
                return Center(child: Text("No matches stored!"));
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: getColorFromIdx(playHeader.state.index),
                    maxRadius: 6,
                  ),
                  Text("  ${playHeader.getReadablePlayId()} against ${playHeader.opponentName}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${playHeader.dimension} x ${playHeader.dimension}, ${playHeader.playMode.name}, TODO your role, Round ${playHeader.currentRound} of ${playHeader.dimension * playHeader.dimension}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${playHeader.getReadableState()}"),
                  IconButton(onPressed: (){
                    _startMultiPlayerGame(
                        context, playHeader);
                    }, icon: Icon(Icons.not_started_outlined)),
                  IconButton(onPressed: (){
                    ask("Are you sure to delete the match ${playHeader.getReadablePlayId()}?", () {
                      setState(() {
                        StorageService().deletePlayHeaderAndPlay(playHeader.playId);
                      });
                    });
                  }, icon: Icon(Icons.delete)),
                ],
              ),
            ],
          ),
        ),),
    );
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
