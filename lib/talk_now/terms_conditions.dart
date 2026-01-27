import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Talk Now – Terms & Conditions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            Text(
              "1. Acceptance of Terms",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "By using Talk Now, you agree to follow these terms and conditions. "
                  "If you do not agree, please do not use this application.",
            ),

            SizedBox(height: 16),

            Text(
              "2. User Accounts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Users are responsible for maintaining the confidentiality of their account. "
                  "You must not misuse the app for illegal or harmful activities.",
            ),

            SizedBox(height: 16),

            Text(
              "3. Messages & Content",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Talk Now allows real-time messaging. We do not take responsibility for user-generated content. "
                  "Any abusive or illegal content may result in account suspension.",
            ),

            SizedBox(height: 16),

            Text(
              "4. Privacy",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "We respect your privacy. User data is stored securely using Firebase services. "
                  "We do not sell user data to third parties.",
            ),

            SizedBox(height: 16),

            Text(
              "5. Account Termination",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "We reserve the right to suspend or terminate accounts that violate these terms.",
            ),

            SizedBox(height: 16),

            Text(
              "6. Changes to Terms",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "These terms may be updated from time to time. Continued use of the app means you accept the changes.",
            ),

            SizedBox(height: 24),

            Text(
              "Last updated: January 2026",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
