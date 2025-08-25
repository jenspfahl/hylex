import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/ui/pages/start_page.dart';

class HylexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: new StartPage(
        key: globalMessageKey
      ),
    );
  }
}