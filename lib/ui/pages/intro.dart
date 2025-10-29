
import 'package:flutter/material.dart';
import 'package:hyle_x/ui/ui_utils.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../model/common.dart';



class Intro extends StatefulWidget {

  State<Intro> createState() => IntroState();
}

class IntroState extends State<Intro> with SingleTickerProviderStateMixin {

  late AnimationController animatedPageController;

  @override
  void initState() {
    super.initState();
    animatedPageController = AnimationController(
        duration: const Duration(seconds: 15 + 4),
        lowerBound: -5,//waiting time to read the text
        upperBound: 15,
        animationBehavior: AnimationBehavior.preserve,
        vsync: this
    );
  }

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pop();
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
      onChange: (_) {
        animatedPageController.reset();
      },
      pages: [
        PageViewModel(
          title: "The eternal fight between Chaos and Order",
          bodyWidget: Align(
            child: Column(
              children: [
                Text("One player causes Chaos .. ", style: bodyStyle),
                Align(alignment: Alignment.centerLeft,
                    child: buildRoleIndicator(Role.Chaos, isSelected: false)),
                Text(""),
                Text(" ..  the other counteracts as Order.", style: bodyStyle),
                Align(alignment: Alignment.centerRight,
                    child: buildRoleIndicator(Role.Order, isSelected: false)),

              ]
            ),
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "The role of Chaos",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-4);
              
              return Column(
                  children: [
                    Text("Chaos randomly draws chips from the stock and places them as chaotic as possible.", style: bodyStyle),
                    Text(""),
                    _buildCellRow(
                        second: _buildGameChip(chipVisibleFrom: 2, chipColor: getColorFromIdx(0)),
                    ),
                    _buildCellRow(
                        third: _buildGameChip(chipVisibleFrom: 4, chipColor: getColorFromIdx(2)),
                    ),
                    _buildCellRow(
                        first: _buildGameChip(chipVisibleFrom: 3, chipColor: getColorFromIdx(1)),
                    ),
                    _buildCellRow(
                        fourth: _buildGameChip(chipVisibleFrom: 1, chipColor: getColorFromIdx(1)),
                        fifth: _buildGameChip(chipVisibleFrom: 5, chipColor: getColorFromIdx(0)),
                    ),
                    _buildCellRow(),
                  ]
              );
            },
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "The role of Order",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-5);

              return Column(
                  children: [
                    Text("Order wants to bring the placed chips into a horizontal or vertical symmetric order, called Palindromes.", style: bodyStyle),
                    Text(""),
                    _buildCellRow(),
                    _buildCellRow(
                      second: _buildGameChip(chipVisibleFrom: 6, chipColor: getColorFromIdx(3)),
                    ),
                    _buildCellRow(
                      first: _buildGameChip(chipVisibleFrom: 4, chipColor: getColorFromIdx(0)),
                      second: _buildGameChip(chipVisibleFrom: 2, chipColor: getColorFromIdx(1)),
                      third: _buildGameChip(chipVisibleFrom: 1, chipColor: getColorFromIdx(2)),
                      fourth: _buildGameChip(chipVisibleFrom: 3, chipColor: getColorFromIdx(1)),
                      fifth: _buildGameChip(chipVisibleFrom: 5, chipColor: getColorFromIdx(0)),
                    ),
                    _buildCellRow(
                      second: _buildGameChip(chipVisibleFrom: 7, chipColor: getColorFromIdx(3)),
                    ),
                    _buildCellRow(),
                  ]
              );
            },
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "The role of Order",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-5);
              final chipBackgroundColor = getColorFromIdx(0).withOpacity(0.2);

              return Column(
                  children: [
                    Text("Order may slide any placed chip horizontally or vertically through empty cells. Order may also skip its current turn.", style: bodyStyle),
                    Text(""),
                    _buildCellRow(
                      first: _buildGameChip(
                        backgroundColor: chipBackgroundColor,
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                    ),
                    _buildCellRow(
                      first: _buildGameChip(
                        backgroundColor: chipBackgroundColor,
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                    ),
                    _buildCellRow(
                      first: _buildGameChip(
                        chipColor: getColorFromIdx(0),
                        backgroundColor: chipBackgroundColor,
                        chipVisibleAt: [-5,-4,-3,-2,-1,0,1,2],
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                      second: _buildGameChip(
                        chipColor: getColorFromIdx(0),
                        backgroundColor: chipBackgroundColor,
                        chipVisibleAt: [3],
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                      third: _buildGameChip(
                        chipColor: getColorFromIdx(0),
                        backgroundColor: chipBackgroundColor,
                        chipVisibleAt: [4],
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                      fourth: _buildGameChip(
                        chipColor: getColorFromIdx(0),
                        backgroundColor: chipBackgroundColor,
                        chipVisibleAt: [5,6,7,8,9,10,11,12,13,14],
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                      fifth: _buildGameChip(
                        chipColor: getColorFromIdx(1),
                      ),
                    ),
                    _buildCellRow(
                      first: _buildGameChip(
                        backgroundColor: chipBackgroundColor,
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                    ),
                    _buildCellRow(
                      first: _buildGameChip(
                        backgroundColor: chipBackgroundColor,
                        backgroundVisibleAt: [2,3,4,5],
                      ),
                    ),
                  ]
              );
            },
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "Who wins?",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-3);

              return Column(
                  children: [
                    Text("Chaos collects points for each chip outside of a Palindrome  ..", style: bodyStyle),
                    Text(""),
                    _buildCellRow(
                      second: _buildGameChip(
                          text: "20",
                          textVisibleFrom: 2,
                          chipColor: getColorFromIdx(3)),
                    ),
                    _buildCellRow(),
                    _buildCellRow(
                      first: _buildGameChip(
                          chipColor: getColorFromIdx(0)),
                      second: _buildGameChip(
                          chipColor: getColorFromIdx(2)),
                      third: _buildGameChip(
                          chipColor: getColorFromIdx(2)),
                      fourth: _buildGameChip(
                          chipColor: getColorFromIdx(0)),
                      fifth: _buildGameChip(
                          text: "20",
                          textVisibleFrom: 2,
                          chipColor: getColorFromIdx(1)),
                    ),
                    _buildCellRow(),
                    _buildCellRow(),
                    Visibility(
                        visible: animatedPageController.value.toInt() > 3,
                        child: Column(children: [
                          Text(""),
                          Text(" ..  which is 20 points per chip in this example, so total 40.", style: bodyStyle),
                          Align(alignment: Alignment.centerLeft,
                              child: buildRoleIndicator(Role.Chaos, points: 40, isSelected: false)),
                        ],)
                    )
                  ]
              );
            },
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "Who wins?",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-3);

              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Whereas Order collects points for each chip which is part of a Palindrome ..", style: bodyStyle),
                    Text(""),
                    _buildCellRow(
                      second: _buildGameChip(
                        chipColor: getColorFromIdx(3),
                      ),
                    ),
                    _buildCellRow(),
                    _buildCellRow(
                      first: _buildGameChip(
                          text: "1",
                          textVisibleFrom: 2,
                          chipColor: getColorFromIdx(0)),
                      second: _buildGameChip(
                          text: "2",
                          textVisibleFrom: 3,
                          chipColor: getColorFromIdx(2)),
                      third: _buildGameChip(
                          text: "2",
                          textVisibleFrom: 3,
                          chipColor: getColorFromIdx(2)),
                      fourth: _buildGameChip(
                          text: "1",
                          textVisibleFrom: 2,
                          chipColor: getColorFromIdx(0)),
                      fifth: _buildGameChip(
                        chipColor: getColorFromIdx(1),
                      ),
                    ),
                    _buildCellRow(),
                    _buildCellRow(),
                    Visibility(
                        visible: animatedPageController.value.toInt() >= 4,
                        child: Column(children: [
                          Text(""),
                          Text(" ..  which makes 6 points, because of two Palindromes (green-green and red-green-green-red).", style: bodyStyle),
                          Align(alignment: Alignment.centerRight,
                              child: buildRoleIndicator(Role.Order, points: 6, isSelected: false)),
                        ],)
                    )
                  ]
              );
            },
          ),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "Who wins?",
          bodyWidget: AnimatedBuilder(
            animation: animatedPageController,
            builder: (BuildContext context, Widget? child) {

              _startAnimation(-3);

              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("The game is over when all chips are placed ..", style: bodyStyle),
                    Text(""),
                    Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCellRow(
                              first: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.3,
                                  chipColor: getColorFromIdx(0)),
                              second: _buildGameChip(
                                  text: "3",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 2.6,
                                  chipColor: getColorFromIdx(2)),
                              third: _buildGameChip(
                                  text: "2",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 0.5,
                                  chipColor: getColorFromIdx(2)),
                              fourth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 2.5,
                                  chipColor: getColorFromIdx(0)),
                              fifth: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 0.3,
                                  chipColor: getColorFromIdx(1)),
                            ),

                            _buildCellRow(
                              first: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 3.0,
                                  chipColor: getColorFromIdx(4)),
                              second: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.7,
                                  chipColor: getColorFromIdx(2)),
                              third: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 2.7,
                                  chipColor: getColorFromIdx(3)),
                              fourth: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 0.9,
                                  chipColor: getColorFromIdx(1)),
                              fifth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 2.8,
                                  chipColor: getColorFromIdx(2)),
                            ),

                            _buildCellRow(
                              first: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.9,
                                  chipColor: getColorFromIdx(1)),
                              second: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 1.1,
                                  chipColor: getColorFromIdx(0)),
                              third: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 2.4,
                                  chipColor: getColorFromIdx(4)),
                              fourth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.0,
                                  chipColor: getColorFromIdx(3)),
                              fifth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 0.6,
                                  chipColor: getColorFromIdx(2)),
                            ),

                            _buildCellRow(
                              first: _buildGameChip(
                                  text: "2",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.1,
                                  chipColor: getColorFromIdx(4)),
                              second: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 2.8,
                                  chipColor: getColorFromIdx(3)),
                              third: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.6,
                                  chipColor: getColorFromIdx(1)),
                              fourth: _buildGameChip(
                                  text: "3",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 0.7,
                                  chipColor: getColorFromIdx(3)),
                              fifth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.3,
                                  chipColor: getColorFromIdx(3)),
                            ),

                            _buildCellRow(
                              first: _buildGameChip(
                                  text: "2",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.0,
                                  chipColor: getColorFromIdx(4)),
                              second: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 2.2,
                                  chipColor: getColorFromIdx(4)),
                              third: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.8,
                                  chipColor: getColorFromIdx(0)),
                              fourth: _buildGameChip(
                                  text: "1",
                                  textVisibleFrom: 4,
                                  chipVisibleFrom: 1.4,
                                  chipColor: getColorFromIdx(0)),
                              fifth: _buildGameChip(
                                  text: "20",
                                  textVisibleFrom: 6,
                                  chipVisibleFrom: 2.0,
                                  chipColor: getColorFromIdx(1)),
                            ),

                          ],
                    ),
                    Visibility(
                        visible: animatedPageController.value.toInt() > 4,
                        child: Column(children: [
                          Text(""),
                          Text(".. and the player with the most points win.", style: bodyStyle),
                          Row(children: [
                            Align(alignment: Alignment.centerLeft,
                                child: buildRoleIndicator(Role.Chaos, points: 120, isSelected: false, backgroundColor: Colors.lightGreenAccent)),
                            Spacer(),
                            Align(alignment: Alignment.centerRight,
                                child: buildRoleIndicator(Role.Order, points: 26, isSelected: false, backgroundColor: Colors.redAccent)),
                          ]),

                        ],)
                    )
                  ]
              );
            },
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
      controlsPadding: const EdgeInsets.symmetric(vertical: 16),
      dotsDecorator: const DotsDecorator(
       // size: Size(10.0, 10.0),
       // activeSize: Size(22.0, 10.0),
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

  void _startAnimation(int startAt) {
    animatedPageController.repeat(min: startAt.toDouble());
  }

  Widget _buildCellRow({
    Widget? first,
    Widget? second,
    Widget? third,
    Widget? fourth,
    Widget? fifth,
  }) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          first ?? _buildGameChip(),
          second ?? _buildGameChip(),
          third ?? _buildGameChip(),
          fourth ?? _buildGameChip(),
          fifth ?? _buildGameChip(),
        ]);
  }

  Widget _buildGameChip(
      {
        Color? chipColor,
        String text = "",
        Color? backgroundColor,
        double? chipVisibleFrom,
        double? textVisibleFrom,
        List<int>? chipVisibleAt,
        List<int>? backgroundVisibleAt,
      }) {

    const dimension = 11;
    final currentStep = animatedPageController.value;

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
            child: Visibility(
              visible: chipVisibleFrom != null ? currentStep >= chipVisibleFrom : true,
              child: buildGameChip(
                  textVisibleFrom != null
                      ? currentStep >= textVisibleFrom
                      ? text
                      : ""
                      : text,
                  dimension: dimension,
                  chipColor: chipVisibleAt != null
                      ? chipVisibleAt.contains(currentStep.toInt()) ? chipColor : null
                      : chipColor,
                  backgroundColor: backgroundVisibleAt != null
                      ? backgroundVisibleAt.contains(currentStep.toInt()) ? backgroundColor : null
                      : backgroundColor),
            )),
        ),
      );
  }

}
