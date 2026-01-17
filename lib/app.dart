import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/ui/pages/start_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';


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
      localizationsDelegates: [
        AppLocalizations.delegate, // use  flutter gen-l10n if you add new languages
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: _ensureEnglishFirst(AppLocalizations.supportedLocales),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown,
          surface: Colors.brown[50]
        ),
      ),
      home: StartPage(
        key: globalStartPageKey
      ),
    );
  }

  Iterable<Locale> _ensureEnglishFirst(List<Locale> supportedLocales) {
    if (supportedLocales.firstOrNull?.languageCode == 'en') {
      return supportedLocales;
    }
    final english = supportedLocales.firstWhere((l) => l.languageCode == 'en');
    return [english]..addAll(supportedLocales.where((l) => l.languageCode != 'en'));
  }
}