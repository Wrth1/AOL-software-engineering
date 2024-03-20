import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testnote/login.dart'; // Import the login page

class EmailVerificationGate extends StatelessWidget {
  final Widget child;

  const EmailVerificationGate({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      return child;
    } else {
      // Allow access if user is not logged in
      if (user == null) {
        return child;
      } else {
        // If user is logged in but email is not verified, show verification message
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Please verify your email to access this page.',
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: () {
                    // Redirect to login page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: Text('Go to Login'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}

