import 'package:chat/routes/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State createState() => LoginState();
}

class LoginState extends State<Login> {
  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const Text('You are not currently signed in.'),
        ElevatedButton(
          onPressed: () async {
            try {
              final GoogleSignInAccount? googleUser =
                  await GoogleSignIn().signIn();

              final GoogleSignInAuthentication? googleAuth =
                  await googleUser?.authentication;

              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth?.accessToken,
                idToken: googleAuth?.idToken,
              );
              final firebaseUser =
                  await FirebaseAuth.instance.signInWithCredential(credential);
              final user = firebaseUser.user!;
              final QuerySnapshot result = await FirebaseFirestore.instance
                  .collection('users')
                  .where('id', isEqualTo: user.uid)
                  .get();
              final List<DocumentSnapshot> documents = result.docs;
              if (documents.isEmpty) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'nickname': user.displayName,
                  'photoUrl': user.photoURL,
                  'id': user.uid
                });
              }
              final preferences = await SharedPreferences.getInstance();
              await preferences.setString('nickname', user.displayName ?? '');
              await preferences.setString('photoUrl', user.photoURL ?? '');
              await preferences.setString(
                'id',
                user.uid,
              );

              if (context.mounted && firebaseUser.user != null) {
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              }

              return;
            } catch (error) {
              print(error);
            }
          },
          child: const Text('SIGN IN'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
