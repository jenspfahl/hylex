import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/ui/pages/start_page.dart';


const String APP_NAME = 'HyleX';
final HOMEPAGE = 'github.com';
final HOMEPAGE_SCHEME = 'https://';
final HOMEPAGE_PATH = '/jenspfahl/hylex';

class HylexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: new StartPage(
        key: globalStartPageKey
      ),
    );
  }
}