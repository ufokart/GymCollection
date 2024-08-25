import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  String _selectedTheme = 'light';

  ThemeProvider(this._themeData);

  ThemeData get themeData => _themeData;

  String get selectedTheme => _selectedTheme;

  Future<void> setTheme(ThemeData themeData) async {
    _themeData = themeData;
    _selectedTheme =
        themeData.brightness == Brightness.light ? 'light' : 'dark';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', _selectedTheme);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTheme = prefs.getString('theme') ?? 'light';
    _themeData =
        _selectedTheme == 'light' ? ThemeData.light() : ThemeData.dark();
    notifyListeners();
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SETTING",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.wb_sunny), // Icon for Light Theme
            title: Text('Light Theme'),
            trailing: Radio<String>(
              value: 'light',
              groupValue: themeProvider.selectedTheme,
              onChanged: (String? value) {
                if (value != null) {
                  themeProvider.setTheme(ThemeData.light());
                }
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.nights_stay), // Icon for Dark Theme
            title: Text('Dark Theme'),
            trailing: Radio<String>(
              value: 'dark',
              groupValue: themeProvider.selectedTheme,
              onChanged: (String? value) {
                if (value != null) {
                  themeProvider.setTheme(ThemeData.dark());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
