import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String chatId;

  Map<String, String> contactNicknames = {};

  bool showEmoji = false; // 🔹 added to toggle emoji row

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    final users = [
      widget.currentUserId.toLowerCase(),
      widget.otherUserId.toLowerCase()
    ]..sort();
    chatId = users.join('_');

    _loadNicknames();
  }

  void _loadNicknames() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('nicknames')
        .snapshots()
        .listen((snapshot) async {
      Map<String, String> newMap = {};
      for (var doc in snapshot.docs) {
        newMap[doc.id] = doc['nickname'];
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('contactNicknames', json.encode(newMap));

      if (mounted) setState(() => contactNicknames = newMap);
    });
  }

  Future<void> _saveNickname(String userId, String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    contactNicknames[userId] = nickname;
    await prefs.setString('contactNicknames', json.encode(contactNicknames));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('nicknames')
        .doc(userId)
        .set({'nickname': nickname});

    setState(() {});
  }

  void _editOtherUserNickname() async {
    final currentName =
        contactNicknames[widget.otherUserId] ?? widget.otherUserId;
    final TextEditingController editController =
    TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Nickname"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: "Enter nickname"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nickname = editController.text.trim();
              if (nickname.isEmpty) return;
              await _saveNickname(widget.otherUserId, nickname);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    controller.clear();
    _scrollToBottom();
  }

  String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final displayName =
        contactNicknames[widget.otherUserId] ?? widget.otherUserId;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Row(
            children: [
              Expanded(child: Text(displayName)),
              IconButton(
                  onPressed: _editOtherUserNickname, icon: const Icon(Icons.edit))
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 5,),
        child: Column(
          children: [
            // 🔹 Chat messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 60, color: Colors.lightBlueAccent),
                          SizedBox(height: 10),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Start the conversation',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == widget.currentUserId;
                      final time = formatTime(msg['timestamp'] ?? 0);

                      return Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue[100]
                                  : Colors.cyan.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'],
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔹 Emoji + input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Emoji row (only show when toggled)
                  if (showEmoji)
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: " 😃 😭 ☹️ 🤣 😡 🥰 😎 👋 🙏"
                            .split(" ")
                            .map((emoji) {
                          return GestureDetector(
                            onTap: () {
                              final text = controller.text;
                              final selection = controller.selection;
                              final newText = text.replaceRange(
                                  selection.start, selection.end, emoji);
                              controller.text = newText;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(
                                    offset: selection.start + emoji.length),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Text input + send
                  Padding(
                    padding: keyboardHeight > 0? EdgeInsets.only(bottom: 0):EdgeInsets.only(bottom: 45),
                    child: Row(
                      children: [
                        // 🔹 Emoji toggle button
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {
                            setState(() {
                              showEmoji = !showEmoji;
                            });
                          },
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: TextField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Talk Now...',
                                filled: true,
                                fillColor: Colors.blueGrey.shade900,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            size: 30,
                          ),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

