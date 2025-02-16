import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/achievements.dart';
import 'package:share_plus/share_plus.dart';

import '../model/move.dart';
import '../model/play.dart';
import '../service/BitsService.dart';
import '../service/PreferenceService.dart';
import '../utils.dart';
import 'dialogs.dart';
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
    return MaterialApp(
      title: "Load a match",
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: Builder(builder: (context) {
        return Container(
              color: Theme
                  .of(context)
                  .colorScheme
                  .surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
                child: Column(

                  children: [
                    _buildPlayLine("Game 1"),
                    _buildPlayLine("Game 3"),
                  ],
                ),
              ),
            );
      }),
    );
  }

  Widget _buildPlayLine(String playId) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        child:  Row(
          children: [
            Text(playId),
            IconButton(onPressed: (){}, icon: Icon(Icons.delete))
          ],
        ),),
    );
  }

}
