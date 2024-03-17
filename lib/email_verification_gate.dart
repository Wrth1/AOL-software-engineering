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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to the login page
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
