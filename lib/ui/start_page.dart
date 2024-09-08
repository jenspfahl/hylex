import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'dialogs.dart';
import 'game_ground.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 24, end: 32).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGameLogo(),
              GestureDetector(
                onTap: () async {
                  
                  if (context.mounted) {
                    buildChoiceDialog(330, 220, 'Which ground size?',
                      "5 x 5", () {_selectPlayerModeAndStartGame(context, 5);},
                      "7 x 7", () {_selectPlayerModeAndStartGame(context, 7);},
                      "9 x 9", () {_selectPlayerModeAndStartGame(context, 9);},
                      "11 x 11", () {_selectPlayerModeAndStartGame(context, 11);},
                      "13 x 13", () {_selectPlayerModeAndStartGame(context, 13);},
                    );

                  }
                },
                child: _buildChip("Start New", Colors.red, 60, 16, 10),
              ),
              GestureDetector(
                onTap: () {
                  buildAlertDialog(NotifyType.error, 'Not yet implemented!');
                },
                child: _buildChip("Resume", Colors.lightBlueAccent, 60, 16, 10),
              ),
              GestureDetector(
                onTap: () {
                  buildChoiceDialog(180, 180, 'Leave the game?',
                      "YES", () {
                    SystemNavigator.pop();
                  },  "NO", () {
                    SmartDialog.dismiss();
                  });
                },
                child: _buildChip("Exit", Colors.brown, 40, 16, 10),
              ),
            ],
          ),
        ),
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
      return Hyle9Ground(chaosPlayer, orderPlayer, dimension);
    }));
  }


  Widget _buildChip(String text, Color color, double radius, double textSize,
      double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: CircleAvatar(
        backgroundColor: color,
        radius: radius,
        child: Text(text,
            style: TextStyle(
              fontSize: textSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Widget _buildGameLogo() {
    const chipPadding = 1.0;
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip("H", Colors.redAccent, 30, 20, chipPadding),
          _buildChip("Y", Colors.blueGrey, 30, 20, chipPadding),
          Text("9",
              style: TextStyle(
                  fontSize: _animation.value,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold))
        ],
      ),
      Row(
        children: [
          _buildChip("L", Colors.orangeAccent, 30, 20, chipPadding),
          _buildChip("E", Colors.cyanAccent, 30, 20, chipPadding),
        ],
      ),
    ]);
  }
}
