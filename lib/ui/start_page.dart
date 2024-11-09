import 'dart:convert';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/achievements.dart';

import '../model/play.dart';
import '../service/PreferenceService.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'game_ground.dart';

enum MenuMode {
  None,
  SinglePlay,
  Multiplayer,
  MultiplayerNew,
  More
}


class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  MenuMode _menuMode = MenuMode.None;

  late User _user;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 18, end: 30).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);


    _loadOrInitUser().then((user) => setState(() {
      _user = user;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: Builder(builder: (context) {
        return _buildStartPage(context);
      }),
    );
  }

  Widget _buildStartPage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Container(
                child: _buildGameLogo()
            ),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildCell("Single Play", 0,
                    isMain: true,
                    icon: Icons.person,
                    clickHandler: () => setState(
                                () => _menuMode = _menuMode == MenuMode.SinglePlay
                                    ? MenuMode.None
                                    : MenuMode.SinglePlay)
                ),

                _menuMode == MenuMode.SinglePlay
                    ? _buildCell("New Game", 0,
                    icon: CupertinoIcons.game_controller,
                    clickHandler: () async {
                        if (context.mounted) {

                          final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_PLAY);
                          confirmOrDo(json != null, 'Starting a new game will delete an ongoing game.', () {
                            _selectPlayerGroundSize(context);
                          });
                        }
                    }
                )
                    : _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("Send Invite", 3, icon: Icons.near_me)
                    : _buildEmptyCell(),

                _menuMode == MenuMode.SinglePlay
                    ? _buildCell("Resume", 0,
                  icon: Icons.not_started_outlined,
                  clickHandler: () async {
                    final play = await _loadPlay();
                    if (play != null) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                            return HyleXGround.load(_user, play);
                          }));
                    }
                    else {
                      buildAlertDialog(NotifyType.error, 'No ongoing single play to resume.');
                    }
                  }
                )
                    : _buildEmptyCell(),

                _buildCell("Multiplayer", 2,
                    isMain: true,
                    icon: Icons.group,
                    clickHandler: () => setState(
                          () => _menuMode = _menuMode == MenuMode.Multiplayer
                          ? MenuMode.None
                          : MenuMode.Multiplayer)
                ),

                _menuMode == MenuMode.Multiplayer || _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("New Match", 3,
                    icon: Icons.sports_score,
                    clickHandler: () => setState(
                            () => _menuMode = _menuMode == MenuMode.MultiplayerNew
                            ? MenuMode.Multiplayer
                            : MenuMode.MultiplayerNew))
                    : _buildEmptyCell(),

                _menuMode == MenuMode.Multiplayer || _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("Continue Match", 4,
                  icon: Icons.sports_tennis,
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.More
                    ? _buildCell("How to Play", 1, icon: CupertinoIcons.question_circle_fill)
                    : _buildEmptyCell(),

                _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("Got Invited", 3, icon: Icons.qr_code_2)
                    : _menuMode == MenuMode.More
                    ? _buildCell("Achievements", 1, icon: Icons.leaderboard, clickHandler: () => _buildAchievementDialog())
                    : _buildEmptyCell(),

                _buildCell("More", 1,
                  isMain: true,
                    clickHandler: () => setState(
                            () => _menuMode = _menuMode == MenuMode.More
                            ? MenuMode.None
                            : MenuMode.More)
                ),



              ],

            ),

            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () {

                  }, icon: const Icon(Icons.settings_outlined)),

                  IconButton(onPressed: () {
                    ask('Quit the app?', () {
                          SystemNavigator.pop();
                    });
                  }, icon: const Icon(Icons.exit_to_app_outlined)),

                  IconButton(onPressed: () {

                  }, icon: const Icon(Icons.info_outline)),
            ]),
          ],
        ),
      ),
    );
  }

  void _selectPlayerGroundSize(BuildContext context) {
    buildChoiceDialog(330, 220, 'Which ground size?',
      "5 x 5", () {_selectPlayerModeAndStartGame(context, 5);},
      "7 x 7", () {_selectPlayerModeAndStartGame(context, 7);},
      "9 x 9", () {_selectPlayerModeAndStartGame(context, 9);},
      "11 x 11", () {_selectPlayerModeAndStartGame(context, 11);},
      "13 x 13", () {_selectPlayerModeAndStartGame(context, 13);},
    );
  }

  Widget _buildCell(String label, int colorIdx,
      {Function()? clickHandler, IconData? icon, bool isMain = false}) {
    return GestureDetector(
                onTap: clickHandler ?? () {
                  buildAlertDialog(NotifyType.error, 'Not yet implemented!');
                },
                child: _buildChip(label, 80, isMain ? 15: 13, 5, colorIdx, icon),
              );
  }

  Container _buildEmptyCell() {
    return Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(), left: BorderSide())
                ),
              );
  }

  void _selectPlayerModeAndStartGame(BuildContext context, int dimension) {
    SmartDialog.dismiss();
    buildChoiceDialog(280, 220, 'Which role you will take?',
      "ORDER", () {_startGame(context, Player.Ai, Player.User, dimension);},
      "CHAOS", () {_startGame(context, Player.User, Player.Ai, dimension);},
      "BOTH", () {_startGame(context, Player.User, Player.User, dimension);},
      "NONE", () {_startGame(context, Player.Ai, Player.Ai, dimension);},
    );
  }

  Future<void> _startGame(BuildContext context, Player chaosPlayer, Player orderPlayer, int dimension) async {
    SmartDialog.dismiss();

    SmartDialog.showLoading(msg: "Loading game ...");
    await Future.delayed(const Duration(seconds: 1));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
      return HyleXGround(_user, chaosPlayer, orderPlayer, dimension);
    }));
  }


  Widget _buildChip(String label, double radius, double textSize,
      double padding, int colorIdx, [IconData? icon]) {
    final text = Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    color: Colors.white,
                    fontWeight: icon == null ? FontWeight.bold : null,
                  )
              );
    final content = icon != null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              text,
            ],
          )
        : text;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(), left: BorderSide())
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CircleAvatar(
          backgroundColor: getColorFromIdx(colorIdx),
          radius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildGameLogo() {
    const chipPadding = 1.0;
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip("H", 20, 20, chipPadding, 4),
          _buildChip("Y", 20, 20, chipPadding, 5),
          Text("X",
              style: TextStyle(
                  fontSize: _animation.value,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold))
        ],
      ),
      Row(
        children: [
          _buildChip("L", 20, 20, chipPadding, 6),
          _buildChip("E", 20, 20, chipPadding, 7),
        ],
      ),
    ]);
  }

  Future<User> _loadOrInitUser() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_USER);
    if (json == null) return User();

    final map = jsonDecode(json);
    final user = User.fromJson(map);
    debugPrint("Loaded user: $user");
    return user;
  }

  Future<Play?> _loadPlay() async {
    final json = await PreferenceService().getString(PreferenceService.DATA_CURRENT_PLAY);
    if (json == null) return null;

    final map = jsonDecode(json);
    final play = Play.fromJson(map);
    debugPrint("Loaded play state: $play");
    return play;
  }

  _buildAchievementDialog() {
    SmartDialog.show(builder: (_) {
      List<Widget> children = [
              const Text(
                "Achievements",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              //if (_user.name != null) Text(_user.name!),
              Text("Overall Score: ${_user.achievements.getOverallScore()}",
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text("Overall Won/Lost/Total Count: ${_user.achievements.getOverallWonCount()} / ${_user.achievements.getOverallLostCount()} / ${_user.achievements.getOverallGameCount()}",
                style: const TextStyle(color: Colors.white, fontSize: 13)),

            ];

      children.addAll(_buildStatsForDimension(5));
      children.addAll(_buildStatsForDimension(7));
      children.addAll(_buildStatsForDimension(9));
      children.addAll(_buildStatsForDimension(11));
      children.addAll(_buildStatsForDimension(13));

      children.add(const Divider());
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () => SmartDialog.dismiss(),
                child: const Text("CLOSE")),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () {
                  ask("Reset all stats to zero:", () {
                    _user.achievements.clearAll();
                    //TODO _saveUser();
                    SmartDialog.dismiss();
                    _buildAchievementDialog();
                  });

                },
                child: const Text("RESET")),
          ],
        ),
      );

      return Container(
        height: 600,
        width: 350,
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
      );
    });
  }

  List<Widget> _buildStatsForDimension(int dimension) {
    return [
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$dimension x $dimension", style: const TextStyle(color: Colors.white)),
          const Text("  "),
          const Text("Chaos", style: TextStyle(color: Colors.white)),
          const Text("Order", style: TextStyle(color: Colors.white)),
        ],
      ),
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("High/Total Score:", style: TextStyle(color: Colors.white, fontSize: 12)),
          Text("${_user.achievements.getHighScore(Role.Chaos, dimension)} / ${_user.achievements.getTotalScore(Role.Chaos, dimension)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text("${_user.achievements.getHighScore(Role.Order, dimension)} / ${_user.achievements.getTotalScore(Role.Order, dimension)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Won/Lost/Total Count:", style: TextStyle(color: Colors.white, fontSize: 12)),
          Text("${_user.achievements.getWonGamesCount(Role.Chaos, dimension)} / ${_user.achievements.getLostGamesCount(Role.Chaos, dimension)} / ${_user.achievements.getTotalGameCount(Role.Chaos, dimension)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text("${_user.achievements.getWonGamesCount(Role.Order, dimension)} / ${_user.achievements.getLostGamesCount(Role.Order, dimension)} / ${_user.achievements.getTotalGameCount(Role.Chaos, dimension)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),

    ];
  }
}
