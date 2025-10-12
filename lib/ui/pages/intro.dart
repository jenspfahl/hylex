import 'dart:async';
import 'dart:collection';

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
import 'package:hyle_x/ui/ui_utils.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../utils/dates.dart';
import '../dialogs.dart';
import 'game_ground.dart';



class Intro extends StatefulWidget {


  State<Intro> createState() => IntroState();
}

class IntroState extends State<Intro> {


  @override
  void initState() {
    super.initState();
  }

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pop();
  }

  Widget _buildImage() {
    return Row(children: [
      CircleAvatar(
        backgroundColor: getColorFromIdx(0),
        maxRadius: 60,
      ),
      CircleAvatar(
        backgroundColor: getColorFromIdx(1),
        maxRadius: 60,
      ),
      CircleAvatar(
        backgroundColor: getColorFromIdx(2),
        maxRadius: 60,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    final backgroundColor = Theme.of(context)
          .colorScheme
          .surface;

    final pageDecoration = PageDecoration(
      titlePadding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      pageColor: backgroundColor,
   //   imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: backgroundColor,
      allowImplicitScrolling: true,
      pages: [
        PageViewModel(
          title: "The eternal fight between Chaos and Order",
          bodyWidget: Align(
            child: Column(
              children: [
                Text("One player causes chaos .. ", style: bodyStyle),
                Align(alignment: Alignment.centerLeft,
                    child: buildRoleIndicator(Role.Chaos, isSelected: false)),
                Text(""),
                Text(" ..  the other counteracts as Order", style: bodyStyle),
                Align(alignment: Alignment.centerRight,
                    child: buildRoleIndicator(Role.Order, isSelected: false)),

              ]
            ),
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "The role of Chaos",
          bodyWidget: Align(
            child: Column(
                children: [
                  Text("Chaos randomly draws chips from the stock and places them as chaotic as possible.", style: bodyStyle),
                  Text(""),
                  Align(alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        _buildGameChip("", dimension: 11, chipColor: getColorFromIdx(1), showCoordinates: false),
                        _buildGameChip("", dimension: 11, chipColor: getColorFromIdx(0), showCoordinates: false),
                        _buildGameChip("", dimension: 11, chipColor: getColorFromIdx(2), showCoordinates: false),
                        _buildGameChip("", dimension: 11, chipColor: getColorFromIdx(1), showCoordinates: false),
                        _buildGameChip("", dimension: 11, chipColor: getColorFromIdx(0), showCoordinates: false),
                      ],)),

                ]
            ),
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "The role of Order",
          bodyWidget: Align(
            child: Column(
                children: [
                  Text("Order wants to move the placed chips into a symmetric order.", style: bodyStyle),
                  Text(""),
                  Align(alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildGameChip("1", dimension: 11, chipColor: getColorFromIdx(0), showCoordinates: false),
                          _buildGameChip("2", dimension: 11, chipColor: getColorFromIdx(1), showCoordinates: false),
                          _buildGameChip("3", dimension: 11, chipColor: getColorFromIdx(2), showCoordinates: false),
                          _buildGameChip("2", dimension: 11, chipColor: getColorFromIdx(1), showCoordinates: false),
                          _buildGameChip("1", dimension: 11, chipColor: getColorFromIdx(0), showCoordinates: false),
                        ],)),

                ]
            ),
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      showBackButton: true,
      back: const Icon(Icons.arrow_back),
      skip: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
    //  controlsMargin: const EdgeInsets.all(16),
     // controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: ShapeDecoration(
        color: backgroundColor,
        shape: const RoundedRectangleBorder(),
      ),
    );
  }

  _buildGameChip(String text, {required int dimension, required Color chipColor, required bool showCoordinates}) {
    return
      Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withAlpha(80), width: 0.5)
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: SizedBox(
            height: dimension * 4,
            width: dimension * 4,
            child: buildGameChip(text, dimension: dimension, chipColor: chipColor, showCoordinates: showCoordinates)),
        ),
      );
  }

}
