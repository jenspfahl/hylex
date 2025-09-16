import 'dart:math';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app.dart';
import '../../service/PreferenceService.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  final PreferenceService _preferenceService = PreferenceService();

 // bool _notifyAtBreaks = PreferenceService.PREF_NOTIFY_AT_BREAKS.defaultValue;
//  bool _vibrateAtBreaks = PreferenceService.PREF_VIBRATE_AT_BREAKS.defaultValue;



  String _version = 'n/a';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$APP_NAME Settings'), elevation: 0),
      body: FutureBuilder(
        future: _loadAllPrefs(),
        builder: (context, AsyncSnapshot snapshot) => _buildSettingsList(),
      ),
    );
  }

  Widget _buildSettingsList()  {

    return SettingsList(
      lightTheme: SettingsThemeData(
          settingsListBackground: Theme
              .of(context)
              .colorScheme
              .surface
      ),
      sections: [
        SettingsSection(
          title: Text('Common'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Dark theme'),
              initialValue: false,
              onToggle: (bool value) {
                /*_preferenceService.setBool(PreferenceService.PREF_DARK_MODE, value)
                    .then((_) {
                  setState(() {
                    _darkMode = value;
                    _preferenceService.darkTheme = _darkMode;
                    debugPrint('dartheme=$_darkMode');
                    AppBuilder.of(context)?.rebuild();
                  });
                });*/
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text('Game Settings'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Show coordinates'),
              initialValue: false,
              onToggle: (bool value) {
               /* _preferenceService.setBool(PreferenceService.PREF_NOTIFY_AT_BREAKS, value);
                setState(() => _notifyAtBreaks = value);*/
              },
            ),

            SettingsTile(
              title: const Text('Your name'),
              description: const Text("Shown in messages for opponents"),
              onPressed: (value) {
                //TODO ask for name
              }
            ),

            const CustomSettingsTile(child: SizedBox(height: 36)),
          ],
        ),

      ],
    );
  }

  _loadAllPrefs() async {

    final packageInfo = await PackageInfo.fromPlatform();
    _version = packageInfo.version;

   /* final notifyAtBreaks = await _preferenceService.getBool(PreferenceService.PREF_NOTIFY_AT_BREAKS);
    if (notifyAtBreaks != null) {
      _notifyAtBreaks = notifyAtBreaks;
    }*/

  }

}
