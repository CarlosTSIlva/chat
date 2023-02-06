import 'package:chat/routes/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              GoogleSignIn().disconnect();
              GoogleSignIn().signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SizedBox(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(10.0),
                itemBuilder: (context, index) => Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: Image(
                            image: NetworkImage(
                                snapshot.data?.docs[index].get('photoUrl'))),
                        title: Text(snapshot.data?.docs[index].get('nickname')),
                        subtitle:
                            Text(snapshot.data?.docs[index].get('aboutMe')),
                      ),
                    ),
                  ],
                ),
                itemCount: snapshot.data?.docs.length ?? 0,
              );
            }
          },
        ),
      ),
    );
  }
}
