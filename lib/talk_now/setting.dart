import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talk_now/talk_now/edit_profile.dart';
import 'package:talk_now/talk_now/takeName.dart';
import 'package:talk_now/talk_now/terms_conditions.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUserId;

  const SettingsScreen({required this.currentUserId, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  goToTerms(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>TermsAndConditionsScreen()));
  }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = value;
    });
    await prefs.setBool('darkMode', darkMode);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase

    // Clear local SharedPreferences if needed
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to Login Screen and remove all previous screens
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TakeName()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          const Divider(),

          // Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewProfileScreen(currentUserId: widget.currentUserId),
                ),
              );
            },
          ),

          Divider(),
          ListTile(
            leading: const Icon(Icons.find_in_page_sharp),
            title: const Text("Terms and conditions"),
            onTap: goToTerms,
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
