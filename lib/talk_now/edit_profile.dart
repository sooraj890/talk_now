import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewProfileScreen extends StatefulWidget {
  final String currentUserId;

  const ViewProfileScreen({required this.currentUserId, super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  String username = '';
  bool _loading = true;
  bool _showPassword = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Try to get username from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('username');
      if (localName != null) {
        setState(() {
          username = localName;
          _nameController.text = localName;
          _loading = false;
        });
      }

      // Then fetch latest name from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          username = data['username'] ?? 'Unknown';
          _nameController.text = username;
          _loading = false;
        });

        // Store it locally
        await prefs.setString('username', username);
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _loading = true);

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .update({'username': newName});

      // Update locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newName);

      setState(() => username = newName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating name: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username field
            Text(
              "Username:",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration:
                  const InputDecoration(border: OutlineInputBorder()),
                ),
            SizedBox(height: 30,),
            // Password display
            Text(
              "Password:",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _showPassword
                      ? "********" // Placeholder
                      : "********",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Note: Actual password cannot be retrieved from Firebase Auth.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        SizedBox(height: 20,),
      Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(onPressed: (){
          _updateName();
        }, child: Text("Update Profile")),
      )
          ],
        ),
      ),
    );
  }
}
