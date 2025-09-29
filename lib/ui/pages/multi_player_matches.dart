import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/ui/pages/start_page.dart';

import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../utils/dates.dart';
import '../dialogs.dart';
import 'game_ground.dart';


GlobalKey<MultiPlayerMatchesState> globalMultiPlayerMatchesKey = GlobalKey();

enum SortOrder {BY_PLAY_ID, BY_STATE, BY_LATEST}

class MultiPlayerMatches extends StatefulWidget {

  final User user;

  const MultiPlayerMatches(this.user, {super.key});

  @override
  State<MultiPlayerMatches> createState() => MultiPlayerMatchesState();
}

class MultiPlayerMatchesState extends State<MultiPlayerMatches> {

  late SortOrder _sortOrder;

  @override
  void initState() {
    super.initState();

    _sortOrder = SortOrder.BY_PLAY_ID;
    PreferenceService().getInt(PreferenceService.PREF_MATCH_SORT_ORDER)
        .then((value) {
          if (value != null) {
            setState(() => _sortOrder = SortOrder.values.firstWhere((p) => p.index == value));
          }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Continue a match'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                globalStartPageKey.currentState?.scanNextMove();
              }),
            IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  showChoiceDialog("Sort list by",
                      firstString: _emphasise("Match ID", _sortOrder == SortOrder.BY_PLAY_ID),
                      firstHandler: () => _triggerSort(SortOrder.BY_PLAY_ID),
                      secondString: _emphasise("Match State", _sortOrder == SortOrder.BY_STATE),
                      secondHandler: () => _triggerSort(SortOrder.BY_STATE),
                      thirdString: _emphasise("Latest", _sortOrder == SortOrder.BY_LATEST),
                      thirdHandler: () => _triggerSort(SortOrder.BY_LATEST),
                  );
                }),
          ],
        ),
        body: FutureBuilder<List<PlayHeader>>(
            future: StorageService().loadAllPlayHeaders(),
            builder: (BuildContext context,
                AsyncSnapshot<List<PlayHeader>> snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final sorted = _sort(snapshot.data!);
                return SingleChildScrollView(
                  child: Container(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: sorted.map(_buildPlayLine).toList(),
                      ),
                    ),
                  ),
                );

              }
              else if (snapshot.hasError) {
                print("loading error: ${snapshot.error}");
                return Center(child: Text("Cannot load stored matches!\n${snapshot.error}"));
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
                    if (playHeader.state == PlayState.InvitationPending) {
                      globalStartPageKey.currentState?.handleReplyToInvitation(playHeader);
                    }
                    else if (playHeader.state == PlayState.InvitationRejected) {
                      final lastMessage = playHeader.commContext.messageHistory.lastOrNull;
                      final opponentRejected = lastMessage != null
                          && lastMessage.channel == Channel.In
                          && lastMessage.serializedMessage.extractOperation() == Operation.RejectInvite;
                      showAlertDialog(opponentRejected
                          ? "Opponent rejected your invitation"
                          : "You rejected opponent's invitation.");
                    }
                    else if (playHeader.isStateShareable()) {
                      showChoiceDialog("Your opponent needs to react to your last message.",
                          firstString: "SHARE IT AGAIN",
                          firstHandler: () {
                            MessageService().sendCurrentPlayState(
                                playHeader, widget.user, context, null);
                          },
                          secondString: "CANCEL",
                          secondHandler: () {});

                    }
                    else {
                      _startMultiPlayerGame(
                          context, playHeader);
                    }

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
                      if (playHeader.lastTimestamp != null) Text("Last move: " + format(playHeader.lastTimestamp!), style: TextStyle(color: Colors.grey[500])),
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
                            visible: playHeader.state.hasGameBoard,
                            child: IconButton(onPressed: (){
                              _startMultiPlayerGame(
                                  context, playHeader);
                            }, icon: Icon(Icons.not_started_outlined)),
                          ),
                          Visibility(
                            visible: isDebug || (playHeader.state == PlayState.InvitationPending || playHeader.isStateShareable()),
                            child: IconButton(onPressed: (){
                              if (playHeader.state == PlayState.InvitationPending) {
                                globalStartPageKey.currentState?.handleReplyToInvitation(playHeader);
                              }
                              else if (playHeader.isStateShareable()) {
                                MessageService().sendCurrentPlayState(
                                    playHeader, widget.user, context, null);
                              }
                              else {
                                showAlertDialog("Nothing to share, take action instead");
                              }
                            }, icon: GestureDetector(
                                child: Icon(Icons.near_me),
                                onLongPress: () => _showMultiPlayTestDialog(playHeader),
                            )),
                          ),
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
    final localRole = playHeader.getLocalRoleForMultiPlay();
    var roleString = "";
    if (localRole != null) {
      roleString = "as ${localRole.name}";
    }
    final sb = StringBuffer("${playHeader.dimension} x ${playHeader.dimension}, Mode: ${playHeader.playMode.name}, $roleString");
    if (playHeader.currentRound > 0) {
      sb.write(", Round ${playHeader.currentRound} of ${playHeader.maxRounds}");
    }
    return sb.toString();
  }

  Future<void> _startMultiPlayerGame(BuildContext context, PlayHeader header) async {
    await showShowLoading("Loading game ...");
    final play = await StorageService().loadPlayFromHeader(header);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              widget.user,
              play ?? Play.newMultiPlay(header));
        })).then((_) {
          // reload when navigating back
          setState(() {
            debugPrint("reload all play header");
          });
    });
  }

  _showMultiPlayTestDialog(PlayHeader playHeader) {
    if (isDebug) {
      SmartDialog.show(
          builder: (_) {
            return RemoteTestWidget(
              rootContext: context,
              playHeader: playHeader,
              messageHandler: (message) {
                globalStartPageKey.currentState?.handleReceivedMessage(
                    message.toUri());
              },
            );
          });
    }
  }

  void playHeaderChanged() {
    setState(() {
      debugPrint("enforce reload of play headers");
    });
  }

  List<PlayHeader> _sort(List<PlayHeader> list) {
    switch (_sortOrder) {
      case SortOrder.BY_PLAY_ID:
        return list.sortedBy((e) => e.getReadablePlayId());
      case SortOrder.BY_STATE:
        return list.sortedBy((e) => (e.state.isFinal.toString() + e.state.name));
      case SortOrder.BY_LATEST:
        return list.sortedBy((e) => e.lastTimestamp?.toIso8601String() ?? e.getReadablePlayId()).reversed.toList();
    }
  }

  _triggerSort(SortOrder sortOrder) {
    setState(() {
      _sortOrder = sortOrder;
    });
    PreferenceService().setInt(PreferenceService.PREF_MATCH_SORT_ORDER, sortOrder.index);
  }

  _emphasise(String text, bool doIt) {
    return doIt ? "✓ $text" : text;
  }

}
