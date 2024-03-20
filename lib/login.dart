import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:testnote/home.dart';
import 'package:url_launcher/url_launcher.dart';

import 'register.dart'; // Import the RegisterPage class

class GoogleSignInArgs {
  const GoogleSignInArgs(
      {required this.clientId,
      required this.redirectUri,
      required this.scope,
      required this.responseType,
      required this.prompt,
      required this.nonce});

  /// The OAuth client id of your Google app.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid.
  final String clientId;

  // The authentication scopes.
  ///
  /// See https://developers.google.com/identity/protocols/oauth2/scopes.
  final String scope;

  /// The authentication response types (e.g. token, id_token, code).
  final String responseType;

  /// A list of prompts to present the user.
  final String prompt;

  /// Cryptographic nonce used to prevent replay attacks.
  ///
  /// It may be required when using an id_token as a response type.
  /// The response from Google should include the same nonce inside the id_token.
  final String nonce;

  /// The URL where the user will be redirected after
  /// completing the authentication in the browser.
  final String redirectUri;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isError = false;
  String _loggedInEmail = '';
  late StreamSubscription<Uri> listener;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      listener = AppLinks().uriLinkStream.listen((uri) async {
        if (uri.scheme != 'notease') return;
        if (uri.path != '/google-auth') return;

        final authenticationIdToken = uri.queryParameters['id_token'];
        final authenticationAccessToken = uri.queryParameters['access_token'];

        setState(() {
          _loggedInEmail = "Signing you in...";
        });
        final credential = GoogleAuthProvider.credential(
          idToken: authenticationIdToken,
          accessToken: authenticationAccessToken,
        );

        await _auth.signInWithCredential(credential);
        if (_auth.currentUser == null) {
          setState(() {
            _loggedInEmail = "Something went wrong!";
          });
        }
      });
    }
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        if (user.emailVerified) {
          // Allow the user to log in
          // Navigator.pop(context); // Close the login page
          // Navigate to the user account screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NotepadHomePage()),
          );
        } else {
        // Display a message indicating that the email is not verified
          await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Email Not Verified'),
                content: const Text('Please verify your email to login.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        // Log out the user
        await _auth.signOut();
      }
        if (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows) {
          listener.cancel();
        }
        Navigator.pop(context);
      }
    });
  }

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
      if (_auth.currentUser == null) {
        _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        if (_auth.currentUser!.emailVerified) {
          // Allow login if email is verified
          _auth.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } else {
          // Display message if email is not verified
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Email Not Verified'),
                content: const Text('Please verify your email to login.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _loggedInEmail = 'Error: ${e.toString()}';
        });
      }
    }
  },
  child: const Text('Login'),
),
          if (_isError) Text(_loggedInEmail) else const Text('Not logged in'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await signInWithGoogle();
              } on Exception catch (e) {
                if (mounted) {
                  setState(() {
                    _isError = true;
                    _loggedInEmail = e.toString();
                  });
                }
              }
            },
            child: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
      _auth.signInWithPopup(googleProvider);
      return true;
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      _auth.signInWithCredential(credential);
      return true;
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      final signInArgs = GoogleSignInArgs(
        clientId:
            '967077780131-g9t7g577rsafrl40ko75k1i5kc435ns6.apps.googleusercontent.com',
        redirectUri: 'https://notease-redirect.web.app',
        scope: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ].join(' '),
        responseType: 'token id_token',
        prompt: 'select_account consent',
        nonce: generateNonce(),
      );
      final authUri = Uri(
        scheme: 'https',
        host: 'accounts.google.com',
        path: '/o/oauth2/v2/auth',
        queryParameters: {
          'scope': signInArgs.scope,
          'response_type': signInArgs.responseType,
          'redirect_uri': signInArgs.redirectUri,
          'client_id': signInArgs.clientId,
          'nonce': signInArgs.nonce,
          'prompt': signInArgs.prompt,
        },
      );
      await launchUrl(authUri);
      throw Exception("Check your browser to login!");
    }
    throw UnimplementedError("Error!");
  }

  String generateNonce({int length = 32}) {
    const characters =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();

    return List.generate(
      length,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }
}
