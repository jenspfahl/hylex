import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/ui/pages/start_page.dart';


const String APP_NAME = 'HyleX';
final HOMEPAGE_SCHEME = 'https://';
final HOMEPAGE = 'hylex.jepfa.de';
final GITHUB_HOMEPAGE = 'github.com';
final GITHUB_HOMEPAGE_PATH = '/jenspfahl/hylex';

var isDebug = kDebugMode;

class HylexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [FlutterSmartDialog.observer],
      debugShowCheckedModeBanner: false,
      builder: FlutterSmartDialog.init(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown,
         // dynamicSchemeVariant: DynamicSchemeVariant.fruitSalad,
          surface: Colors.brown[50]
        ),
      ),
      home: new StartPage(
        key: globalStartPageKey
      ),
    );
  }
}