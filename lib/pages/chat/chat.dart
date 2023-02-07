import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChartArgs {
  final String peerId;
  final String currentId;
  ChartArgs({required this.peerId, required this.currentId});
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
          title: const Text('Config'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .doc(groupChatId)
              .collection(groupChatId)
              .orderBy('timestamp', descending: true)
              // .limit(_limit)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red)));
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemBuilder: (context, index) => Message(
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
            height: 55,
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
                      // chat input and button to send message
                      Expanded(
                        child: TextField(
                          controller: controllerText,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          setState(() {});
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
                          controllerScroll.animateTo(0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                          controllerText.clear();

                          // listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
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
  const Message({
    super.key,
    this.type = MessageType.sent,
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
        child: SizedBox(
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
