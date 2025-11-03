import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {
    //await SystemChrome.setEnabledSystemUIMode(
    //    SystemUiMode.leanBack);
    runApp(HylexApp());
  });
}
