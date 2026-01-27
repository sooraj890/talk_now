import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:talk_now/talk_now/setting.dart';
import 'chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UsersScreen extends StatefulWidget {
  final String currentUserId;
  final String nameCont;

  UsersScreen({required this.currentUserId, required this.nameCont});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late String currentUsername;
  Map<String, String> contactNicknames = {}; // otherUserId -> nickname
  Map<String, int> unreadCounts = {}; // otherUserId -> unread message count

  int _selectedIndex = 0; // Bottom navigation index

  @override
  void initState() {
    super.initState();
    currentUsername = widget.nameCont;
    _loadNicknames();
    _loadUnreadCounts();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 🔹 Load nicknames from Firestore
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

  // 🔹 Load unread message counts for each contact
  void _loadUnreadCounts() {
    FirebaseFirestore.instance.collection('chats').snapshots().listen((snapshot) {
      Map<String, int> newCounts = {};

      for (var chatDoc in snapshot.docs) {
        final chatId = chatDoc.id;
        final participants = chatId.split('_');

        if (!participants.contains(widget.currentUserId)) continue;

        final otherUserId = participants.first == widget.currentUserId
            ? participants.last
            : participants.first;

        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isEqualTo: otherUserId)
            .where('isRead', isEqualTo: false)
            .snapshots()
            .listen((msgsSnapshot) {
          newCounts[otherUserId] = msgsSnapshot.docs.length;
          if (mounted) setState(() => unreadCounts = newCounts);
        });
      }
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

  void _editContactNickname(String userId, String currentName) async {
    final TextEditingController editController = TextEditingController(
      text: currentName,
    );

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
              await _saveNickname(userId, nickname);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔹 Widget for Chats tab (with search bar)
  Widget _buildChatsTab() {
    String searchQuery = ""; // local search query

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return Column(
          children: [
            // 🔹 Search bar container
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search contacts...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setStateSB(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            const SizedBox(height: 5),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final users = snapshot.data!.docs
                      .where((doc) => doc.id != widget.currentUserId)
                      .where((doc) {
                    final username =
                        (doc.data() as Map<String, dynamic>)['username'] ?? '';
                    final displayName =
                        contactNicknames[doc.id] ?? username;
                    return displayName.toLowerCase().contains(searchQuery);
                  })
                      .toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No contacts found",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView(
                    children: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = data['username'] ?? 'Unknown';
                      final displayName = contactNicknames[doc.id] ?? username;
                      final unread = unreadCounts[doc.id] ?? 0;

                      return ListTile(
                        title: Row(
                          children: [
                            Text(displayName),
                            if (unread > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                currentUserId: widget.currentUserId,
                                otherUserId: doc.id,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => _editContactNickname(doc.id, displayName),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Dummy widget for Settings tab
  Widget _buildSettingsTab() {
    return SettingsScreen(currentUserId: widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [
      _buildChatsTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text("Hello! $currentUsername")),
            ClipOval(
              child: Image.asset(
                "assets/images/logo.png",
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
