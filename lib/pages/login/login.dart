import 'package:chat/routes/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
              final QuerySnapshot result = await FirebaseFirestore.instance
                  .collection('users')
                  .where('id', isEqualTo: firebaseUser.user?.uid)
                  .get();
              final List<DocumentSnapshot> documents = result.docs;
              if (documents.isEmpty) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(firebaseUser.user?.uid)
                    .set({
                  'nickname': firebaseUser.user?.displayName,
                  'photoUrl': firebaseUser.user?.photoURL,
                  'id': firebaseUser.user?.uid
                });
              }

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
