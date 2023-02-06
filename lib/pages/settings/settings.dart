import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final preference = SharedPreferences.getInstance();

  final List<String> _labels = ["NickName", "About me"];
  late final List<TextEditingController> _controllers =
      List.generate(2, (index) => TextEditingController());

  @override
  initState() {
    super.initState();
    preference.then((value) {
      final nickName = value.getString("nickname");
      final aboutMe = value.getString("aboutMe");

      _controllers[0].text = nickName ?? "";
      _controllers[1].text = aboutMe ?? "";
    });
  }

  Future uploadFile() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
          child: Column(
        children: [
          const Text("Settings"),
          ..._labels
              .map((e) => TextField(
                    controller: _controllers[_labels.indexOf(e)],
                    decoration: InputDecoration(
                      labelText: e,
                    ),
                  ))
              .toList(),
          TextButton(onPressed: () {}, child: const Text("carlos")),
        ],
      )),
    );
  }
}
