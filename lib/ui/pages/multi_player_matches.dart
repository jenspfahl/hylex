import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/ui/pages/start_page.dart';
import 'package:hyle_x/utils/fortune.dart';

import '../../l10n/app_localizations.dart';
import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../utils/dates.dart';
import '../dialogs.dart';
import 'game_ground.dart';


GlobalKey<MultiPlayerMatchesState> globalMultiPlayerMatchesKey = GlobalKey();

enum SortOrder {BY_PLAY_ID, BY_STATE, BY_LATEST, BY_OPPONENT}

class MultiPlayerMatches extends StatefulWidget {

  final User user;

  const MultiPlayerMatches(this.user, {super.key});

  @override
  State<MultiPlayerMatches> createState() => MultiPlayerMatchesState();
}

class MultiPlayerMatchesState extends State<MultiPlayerMatches> {

  late SortOrder _sortOrder;

  Map<String, bool> _hideGroup = HashMap();

  @override
  void initState() {
    super.initState();

    PlayStateGroup.values.forEach((group) => _hideGroup[group.name] = group.isFinal);

    _sortOrder = SortOrder.BY_STATE;
    PreferenceService().getInt(PreferenceService.PREF_MATCH_SORT_ORDER)
        .then((value) {
          if (value != null) {
            setState(() => _sortOrder = SortOrder.values.firstWhere((p) => p.index == value));
          }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.matchList_title),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                globalStartPageKey.currentState?.scanNextMove(forceShowAllOptions: false);
              }),
            IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  showChoiceDialog(l10n.matchList_sortBy + ":",
                      width: 350,
                      height: 500,
                      firstString: l10n.matchList_sortByCurrentStatusTitle,
                      firstDescriptionString: l10n.matchList_sortByCurrentStatusDesc,
                      firstHandler: () => _triggerSort(SortOrder.BY_STATE),
                      secondString: l10n.matchList_sortByRecentlyPlayedTitle,
                      secondDescriptionString: l10n.matchList_sortByRecentlyPlayedDesc,
                      secondHandler: () => _triggerSort(SortOrder.BY_LATEST),
                      thirdString: l10n.matchList_sortByMatchIdTitle,
                      thirdDescriptionString: l10n.matchList_sortByMatchIdDesc,
                      thirdHandler: () => _triggerSort(SortOrder.BY_PLAY_ID),
                      fourthString: l10n.matchList_sortByOpponentTitle,
                      fourthDescriptionString: l10n.matchList_sortByOpponentDesc,
                      fourthHandler: () => _triggerSort(SortOrder.BY_OPPONENT),
                    highlightButtonIndex: _sortOrder == SortOrder.BY_STATE ? 0 : _sortOrder == SortOrder.BY_LATEST ? 1: _sortOrder == SortOrder.BY_PLAY_ID ? 2 : 3
                  );
                }),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<PlayHeader>>(
              future: StorageService().loadAllPlayHeaders(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PlayHeader>> snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final sorted = _sort(snapshot.data!);
          
                  if (_sortOrder == SortOrder.BY_STATE) {
                    return SingleChildScrollView(
                      child: Container(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              _buildPlayGroupSection(l10n.matchListGroup_actionNeeded, null,
                                  sorted.where((e) => e.state.group == PlayStateGroup.TakeAction).toList(), PlayStateGroup.TakeAction.name),
                              _buildPlayGroupSection(l10n.matchListGroup_waitForOpponent, null,
                                  sorted.where((e) => e.state.group == PlayStateGroup.AwaitOpponentAction).toList(), PlayStateGroup.AwaitOpponentAction.name),
                              _buildPlayGroupSection(l10n.matchListGroup_wonMatches, null,
                                  sorted.where((e) => e.state.group == PlayStateGroup.FinishedAndWon).toList(), PlayStateGroup.FinishedAndWon.name),
                              _buildPlayGroupSection(l10n.matchListGroup_lostMatches, null,
                                  sorted.where((e) => e.state.group == PlayStateGroup.FinishedAndLost).toList(), PlayStateGroup.FinishedAndLost.name),
                              _buildPlayGroupSection(l10n.matchListGroup_rejectedMatches, null,
                                  sorted.where((e) => e.state.group == PlayStateGroup.Other).toList(), PlayStateGroup.Other.name),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  else if (_sortOrder == SortOrder.BY_OPPONENT) {
                    return SingleChildScrollView(
                      child: Container(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: _getOpponentGroups(sorted, l10n),
                          ),
                        ),
                      ),
                    );
                  }
                  else {
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
                }
                else if (snapshot.hasError) {
                  print("loading error: ${snapshot.error}");
                  return Center(child: Text("${l10n.matchList_errorDuringLoading}\n${snapshot.error}"));
                }
                else {
                  return Center(child: Text(l10n.matchList_nothingFound));
                }
              }),
        )
    );

  }

  Widget _buildPlayGroupSection(String title, String? subTitle, List<PlayHeader> groupData, String groupIdentifier) {
    if (groupData.isEmpty) {
      return Container();
    }
    if (_hideGroup[groupIdentifier] == true) {
      title += " (${groupData.length})";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (subTitle != null) Text(subTitle, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  onTap: () {
                    setState(() {
                      _hideGroup[groupIdentifier] = !(_hideGroup[groupIdentifier]??false);
                    });
                  },
                ),
                IconButton(icon: _hideGroup[groupIdentifier] == false ? Icon(Icons.expand_less) : Icon(Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _hideGroup[groupIdentifier] = !(_hideGroup[groupIdentifier]??false);
                    });
                  }),
              ],
            ),
          ),
          if (_hideGroup[groupIdentifier] != true)
            Column(
              children: groupData.map(_buildPlayLine).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildPlayLine(PlayHeader playHeader) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final languageCode = currentLocale.languageCode;

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
                          ? l10n.playState_invitationRejectedByOpponent
                          : l10n.playState_invitationRejectedByYou);
                    }
                    else if (playHeader.isStateShareable()) {
                      showChoiceDialog(l10n.messaging_opponentNeedsToReact,
                          width: 270,
                          firstString: l10n.messaging_shareAgain,
                          firstHandler: () {
                            MessageService().sendCurrentPlayState(
                                playHeader, widget.user, () => context, false);
                          },
                          secondString: MaterialLocalizations.of(context).cancelButtonLabel,
                          secondHandler: () {});

                    }
                    else {
                      _startMultiPlayerGame(
                          context, playHeader);
                    }

                  },
                  onLongPress: () => _showMultiPlayTestDialog(playHeader, widget.user),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: playHeader.state.toColor(),
                            maxRadius: 6,
                          ),
                          Expanded(
                            child: Text(
                                " " + playHeader.getTitle(l10n),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis
                            ),
                          ),
                        ],
                      ),
                      Text(_getHeaderSubLine(playHeader),
                          style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                      Text(_getHeaderBodyLine(playHeader), style: TextStyle(fontStyle: FontStyle.italic)),

                      if (playHeader.lastTimestamp != null) Text("${l10n.matchMenu_lastActivity} " + format(playHeader.lastTimestamp!, l10n, languageCode), style: TextStyle(color: Colors.grey[500])),
                      Text("${playHeader.state.toMessage(l10n)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                            visible: playHeader.state == PlayState.InvitationPending || playHeader.isStateShareable(),
                            child: IconButton(onPressed: ()=> _shareCurrentAction(playHeader, false),
                                icon: GestureDetector(
                                  child: Icon(Icons.near_me),
                                  onLongPress: () => _shareCurrentAction(playHeader, true),
                            )),
                          ),
                          IconButton(onPressed: (){
                            ask(
                                playHeader.state.isFinal
                                    ? l10n.dialog_deleteFinalMatch(playHeader.getReadablePlayId())
                                    : l10n.dialog_deleteOngoingMatch(playHeader.getReadablePlayId()),
                                l10n, () {
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

  void _shareCurrentAction(PlayHeader playHeader, bool showAllOptions) {
    final l10n = AppLocalizations.of(context)!;

    if (playHeader.state == PlayState.InvitationPending) {
      globalStartPageKey.currentState?.handleReplyToInvitation(playHeader);
    }
    else if (playHeader.isStateShareable()) {
      MessageService().sendCurrentPlayState(
          playHeader, widget.user, () => context, showAllOptions);
    }
    else {
      showAlertDialog(l10n.matchList_nothingToShare);
    }
  }

  String _getHeaderSubLine(PlayHeader playHeader) {
    final l10n = AppLocalizations.of(context)!;

    final sb = StringBuffer("${playHeader.dimension} x ${playHeader.dimension}");

    final localRole = playHeader.getLocalRoleForMultiPlay();

    if (localRole != null) {
      sb.write(" ${l10n.as} ${localRole.name}");
    }

    return sb.toString();
  }

  String _getHeaderBodyLine(PlayHeader playHeader) {

    final l10n = AppLocalizations.of(context)!;
    final sb = StringBuffer();

    if (playHeader.playMode == PlayMode.Classic) {
      sb.write("${PlayMode.Classic.getName(l10n)}, ");
    }

    if (playHeader.currentRound > 0) {
      sb.write(l10n.gameHeader_roundOf(playHeader.currentRound, playHeader.maxRounds));
    }
    if (playHeader.playMode == PlayMode.Classic) {
      sb.write(" (${playHeader.rolesSwapped == true
          ? l10n.matchMenu_gameInMatchSecond
          : l10n.matchMenu_gameInMatchFirst})");
    }
    return sb.toString();
  }

  Future<void> _startMultiPlayerGame(BuildContext context, PlayHeader header) async {
    final l10n = AppLocalizations.of(context)!;

    await showShowLoading(l10n.dialog_loadingGame);
    final play = await StorageService().loadPlayFromHeader(header);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              widget.user,
              play ?? Play.newMultiPlay(header));
        },
            settings: RouteSettings(name: PLAY_GROUND))).then((_) {
          // reload when navigating back
          setState(() {
            debugPrint("reload all play header");
          });
    });
  }

  _showMultiPlayTestDialog(PlayHeader playHeader, User user) {
    if (isDebug) {
      SmartDialog.show(
          builder: (_) {
            return RemoteTestWidget(
              rootContext: context,
              playHeader: playHeader,
              localUser: user,
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
        return list.sortedBy((e) => "${(e.state.group.index * 100 + e.state.index)}-${_getReversedTimestamp(e) ?? e.getReadablePlayId()}");
      case SortOrder.BY_LATEST:
        return list.sortedBy((e) => e.lastTimestamp?.toIso8601String() ?? e.getReadablePlayId()).reversed.toList();
      case SortOrder.BY_OPPONENT:
        return list.sortedBy((e) => "${e.opponentName ?? e.opponentId??"---"}-${(100 + e.state.index)}-${_getReversedTimestamp(e) ?? e.getReadablePlayId()}");

    }
  }

  int? _getReversedTimestamp(PlayHeader e) {
    if (e.lastTimestamp == null) {
      return null;
    }
    return 0x7FFFFFFFFFFFFFFF - e.lastTimestamp!.millisecondsSinceEpoch;
  }

  _triggerSort(SortOrder sortOrder) {
    setState(() {
      _sortOrder = sortOrder;
    });
    PreferenceService().setInt(PreferenceService.PREF_MATCH_SORT_ORDER, sortOrder.index);
  }

  List<Widget> _getOpponentGroups(List<PlayHeader> headers, AppLocalizations l10n) {
    
    final groupedByOpponentId = HashMap<String?, List<PlayHeader>>();

    headers.forEach((header) {
      final group = groupedByOpponentId[header.opponentId];
      if (group == null) {
        groupedByOpponentId[header.opponentId] = [header];
      }
      else {
        group.add(header);
      }
    });

    return groupedByOpponentId.entries.map((entry) {
      final opponentId = entry.key;
      final group = groupedByOpponentId[opponentId]??[];
      final opponentName = group.firstOrNull?.opponentName;
      return _buildPlayGroupSection((opponentName ?? "- ${l10n.unknown} -"), opponentId != null ? toReadableId(opponentId) : null, group, opponentId ?? "sdfsdfsdf");
    }).toList();

    
  }


}
