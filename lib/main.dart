import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyle_x/ui/start_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const StartPage());
  });
}
