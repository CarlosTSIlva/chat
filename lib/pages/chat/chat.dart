import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChartArgs {
  final String peerId;
  final String currentId;
  final String name;
  ChartArgs(
      {required this.peerId, required this.currentId, required this.name});
}

class Chat extends StatefulWidget {
  final ChartArgs args;

  const Chat({
    super.key,
    required this.args,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  TextEditingController controllerText = TextEditingController();
  ScrollController controllerScroll = ScrollController();
  String groupChatId = '';
  bool isLoading = false;

  File? imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.args.currentId.hashCode <= widget.args.peerId.hashCode) {
      groupChatId = '${widget.args.currentId}-${widget.args.peerId}';
    } else {
      groupChatId = '${widget.args.peerId}-${widget.args.currentId}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.args.name),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .doc(groupChatId)
              .collection(groupChatId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red)));
            } else {
              return Padding(
                padding:
                    EdgeInsets.only(bottom: imageFile != null ? 200 : 48.0),
                child: ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemBuilder: (context, index) => Message(
                      typeMessage: snapshot.data!.docs[index].get("type"),
                      text: snapshot.data!.docs[index].get("content"),
                      type: widget.args.currentId ==
                              snapshot.data!.docs[index].get("idFrom")
                          ? MessageType.sent
                          : MessageType.received),
                  itemCount: snapshot.data?.docs.length ?? 2,
                  reverse: true,
                  controller: controllerScroll,
                ),
              );
            }
          },
        ),
        bottomSheet: SafeArea(
          child: Container(
            height: imageFile != null ? 180 : 55,
            color: Colors.white70,
            child: Column(
              children: [
                const Divider(
                  height: 4,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              imageFile = File(pickedFile.path);
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: imageFile != null
                            ? Stack(
                                children: [
                                  Image.file(
                                    imageFile!,
                                    height: 160,
                                  ),
                                  if (!isLoading)
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.black, width: 2),
                                        ),
                                        child: IconButton(
                                            color: Colors.red,
                                            onPressed: () {
                                              setState(() {
                                                imageFile = null;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                            )),
                                      ),
                                    ),
                                ],
                              )
                            : TextField(
                                controller: controllerText,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message',
                                ),
                              ),
                      ),
                      IconButton(
                        icon: isLoading
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.send),
                        onPressed: () {
                          if (isLoading) {
                            return;
                          }
                          if (imageFile != null) {
                            setState(() {
                              isLoading = true;
                            });
                            Reference reference = FirebaseStorage.instance
                                .ref()
                                .child('images/imageName');
                            UploadTask uploadTask =
                                reference.putFile(imageFile!);

                            uploadTask.then((storageTaskSnapshot) {
                              storageTaskSnapshot.ref
                                  .getDownloadURL()
                                  .then((downloadUrl) {
                                var documentReference = FirebaseFirestore
                                    .instance
                                    .collection('messages')
                                    .doc(groupChatId)
                                    .collection(groupChatId)
                                    .doc(DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString());
                                FirebaseFirestore.instance
                                    .runTransaction((transaction) async {
                                  transaction.set(
                                    documentReference,
                                    {
                                      'idFrom': widget.args.currentId,
                                      'idTo': widget.args.peerId,
                                      'timestamp': DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                      'content': downloadUrl,
                                      'type': 1
                                    },
                                  );
                                });
                                setState(() {
                                  imageFile = null;
                                  isLoading = false;
                                });
                              });
                            }, onError: (err) {
                              setState(() {
                                imageFile = null;
                                isLoading = false;
                              });
                            });

                            return;
                          }

                          var documentReference = FirebaseFirestore.instance
                              .collection('messages')
                              .doc(groupChatId)
                              .collection(groupChatId)
                              .doc(DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString());
                          final String info = (controllerText.text);
                          FirebaseFirestore.instance
                              .runTransaction((transaction) async {
                            transaction.set(
                              documentReference,
                              {
                                'idFrom': widget.args.currentId,
                                'idTo': widget.args.peerId,
                                'timestamp': DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                'content': info,
                                'type': 0
                              },
                            );
                          });
                          controllerScroll.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                          controllerText.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class Message extends StatelessWidget {
  final MessageType type;
  final String text;
  final int typeMessage;
  const Message({
    super.key,
    this.type = MessageType.sent,
    this.typeMessage = 0,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: type.alignment,
      padding: const EdgeInsets.all(10),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: type.color,
        ),
        child: typeMessage == 1
            ? CachedNetworkImage(
                imageUrl: text,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    LinearProgressIndicator(
                        value: downloadProgress.progress ?? 0),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : SizedBox(
                child: Text(text),
              ),
      ),
    );
  }
}

enum MessageType { sent, received }

extension MessageTypeExtension on MessageType {
  bool get isSent => this == MessageType.sent;
  bool get isReceived => this == MessageType.received;

  get alignment => isSent ? Alignment.centerRight : Alignment.centerLeft;

  get color => isSent ? Colors.grey : Colors.blue;
}
