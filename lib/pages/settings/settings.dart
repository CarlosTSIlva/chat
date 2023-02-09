import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
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

  File? imageFile;
  String url =
          "https://www.google.com/url?sa=i&url=https%3A%2F%2Fcommons.wikimedia.org%2Fwiki%2FFile%3ALoading_icon.gif&psig=AOvVaw3P9_OFcXkJJbI1LBXNglgE&ust=1675774601368000&source=images&cd=vfe&ved=0CA8QjRxqFwoTCIDV5oH5gP0CFQAAAAAdAAAAABAD",
      id = "",
      photoUrl = "",
      nickname = "",
      aboutMe = "";
  bool isLoading = false;

  @override
  initState() {
    super.initState();
    preference.then((value) {
      final nickName = value.getString("nickname");
      final aboutMe = value.getString("aboutMe");
      final stringUrl = value.getString("photoUrl");
      final uid = value.getString("id");

      _controllers[0].text = nickName ?? "";
      _controllers[1].text = aboutMe ?? "";
      url = stringUrl ?? "";
      id = uid ?? "";
      setState(() {
        url = stringUrl ?? "";
      });
    });
  }

  _getFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future uploadFile() async {
    final prefs = await SharedPreferences.getInstance();

    if (imageFile == null) {
      FirebaseFirestore.instance.collection('users').doc(id).update({
        'nickname': _controllers[0].text,
        'aboutMe': _controllers[1].text,
      }).then((data) async {
        await prefs.setString('aboutMe', _controllers[1].text);
        await prefs.setString('nickname', _controllers[0].text);
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Update success");
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
      return;
    }
    Reference reference =
        FirebaseStorage.instance.ref().child('images/imageName');

    UploadTask uploadTask = reference.putFile(imageFile!);
    TaskSnapshot storageTaskSnapshot;
    uploadTask.then((value) {
      storageTaskSnapshot = value;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        photoUrl = downloadUrl;
        FirebaseFirestore.instance.collection('users').doc(id).update({
          'nickname': _controllers[0].text,
          'aboutMe': _controllers[1].text,
          'photoUrl': photoUrl
        }).then((data) async {
          await prefs.setString('photoUrl', photoUrl);
          await prefs.setString('aboutMe', _controllers[1].text);
          await prefs.setString('nickname', _controllers[0].text);
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: "Upload success");
        }).catchError((err) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: err.toString());
        });
      }, onError: (err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Center(
              child: InkWell(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: () {
              _getFromGallery();
            },
            child: CircleAvatar(
              radius: 48, // Image radius
              backgroundImage: (imageFile != null
                  ? FileImage(File(imageFile!.path))
                  : NetworkImage(url)) as ImageProvider<Object>?,
            ),
          )),
          const Text("Settings"),
          ..._labels
              .map((e) => TextField(
                    controller: _controllers[_labels.indexOf(e)],
                    decoration: InputDecoration(
                      labelText: e,
                    ),
                  ))
              .toList(),
          Container(
            padding: const EdgeInsets.only(top: 30),
            child: ElevatedButton(
              onPressed: () {
                uploadFile();
              },
              child: const Text("Upload"),
            ),
          )
        ],
      ),
    );
  }
}
