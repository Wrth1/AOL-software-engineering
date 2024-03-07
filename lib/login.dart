import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggedIn = false;
  bool _isError = false;
  String _loggedInEmail = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final UserCredential userCredential =
                    await _auth.signInWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                final User? user = userCredential.user;
                setState(() {
                  _isLoggedIn = true;
                  _loggedInEmail = user?.email ?? '';
                  Navigator.pop(context);
                });
              } on Exception catch (e) {
                setState(() {
                  _isError = true;
                  _loggedInEmail = 'Error: ${e.toString()}';
                });
              }
            },
            child: const Text('Login'),
          ),
          if (_isLoggedIn)
            Text('Logged in as $_loggedInEmail')
          else if (_isError)
            Text(_loggedInEmail)
          else
            const Text('Not logged in')
        ],
      ),
    );
  }
}
