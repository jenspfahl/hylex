
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../app.dart';
import '../../model/messaging.dart';
import '../../model/user.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$APP_NAME Settings'), elevation: 0),
      body: FutureBuilder(
        future: _loadAllPrefs(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return _buildSettingsList(snapshot.data);
          }
          return Text("Loading...");
        },
      ),
    );
  }

  Widget _buildSettingsList(User user)  {

    return SettingsList(
      lightTheme: SettingsThemeData(
          settingsListBackground: Theme
              .of(context)
              .colorScheme
              .surface,

      ),
      sections: [
        /*SettingsSection(
          title: Text('Common'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Dark theme'),
              initialValue: false,
              onToggle: (bool value) {
                _preferenceService.setBool(PreferenceService.PREF_DARK_MODE, value)
                    .then((_) {
                  setState(() {
                    _darkMode = value;
                    _preferenceService.darkTheme = _darkMode;
                    debugPrint('dartheme=$_darkMode');
                    AppBuilder.of(context)?.rebuild();
                  });
                });
              },
            ),
          ],
        ),*/
        SettingsSection(
          title: Text('Game Settings', style: TextStyle(color: Colors.brown[800])),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Show coordinates'),
              description: const Text('Show coordinates at the x and y axis on the grid'),
              initialValue: PreferenceService().showCoordinates,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_COORDINATES, value);
                setState(() => PreferenceService().showCoordinates = value);
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Show points'),
              description: const Text("Show order points on chips"),
              initialValue: PreferenceService().showPoints,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_POINTS, value);
                setState(() => PreferenceService().showPoints = value);
              },
            ),
            SettingsTile(
              title: user.name.isNotEmpty ? Text("Change your name '${user.name}'") : Text('Set your name'),
              description: const Text("Your name is shown in messages for opponents"),
              onPressed: (value) async {
                showInputDialog(translate('dialogs.yourName'),
                  prefilledText: user.name,
                  maxLength: maxNameLength,
                  okHandler: (name) async {
                    user.name = name;
                    await StorageService().saveUser(user);
                    setState(() {});
                  },
                );
              }
            ),

            const CustomSettingsTile(child: SizedBox(height: 36)),
          ],
        ),

      ],
    );
  }

  Future<User>_loadAllPrefs() async {
    return await StorageService().loadUser() ?? User();
  }

}
