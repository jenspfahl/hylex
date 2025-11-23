import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:hyle_x/app.dart';

const DEFAULT_LANGUAGE = 'en';
const SUPPORTED_LANGUAGES = [DEFAULT_LANGUAGE, 'de'];


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {

    var delegate = await LocalizationDelegate.create(
        fallbackLocale: DEFAULT_LANGUAGE,
        supportedLocales: _getSupportedLanguages(''),
    );
    await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]); // bottom to show nav bar if enabled
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.brown[50]
    ));
    runApp(LocalizedApp(delegate, HylexApp()));
  });
}

List<String> _getSupportedLanguages([String? force]) => force != null && force.isNotEmpty ? [force] : SUPPORTED_LANGUAGES;
