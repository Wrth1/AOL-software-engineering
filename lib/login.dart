import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // bool _isLoggedIn = false;
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

        // Authentication completed, you may use the access token to
        // access user-specific data from Google.
        //
        // At this step, you may want to verify that the nonce
        // from the id token matches the one you generated previously.
        //
        // Example:
        // Signing-in with Firebase Auth credentials using the retrieved
        // id and access tokens.
        // print("signing in...");
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
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // if (mounted) {
        //   setState(() {
        //     _isLoggedIn = true;
        //     _loggedInEmail = user.email ?? '';
        //   });
        // }
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

          // Add a Google sign-in button
          ElevatedButton(
            onPressed: () async {
              try {
                await signInWithGoogle();
              } on Exception catch (e) {
                setState(() {
                  _isError = true;
                  _loggedInEmail = e.toString();
                });
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
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // googleProvider
      //     .addScope('https://www.googleapis.com/auth/contacts.readonly');
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

      // Once signed in, return the UserCredential
      _auth.signInWithPopup(googleProvider);
      return true;
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      // Once signed in, return the UserCredential
      _auth.signInWithCredential(credential);
      return true;
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      final signInArgs = GoogleSignInArgs(
        // The OAuth client id of your Google app.
        clientId:
            '967077780131-g9t7g577rsafrl40ko75k1i5kc435ns6.apps.googleusercontent.com',
        // The URI to your redirect web page.
        redirectUri: 'https://notease-redirect.web.app',
        // Basic scopes to retrieve the user's email and profile details.
        scope: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ].join(' '),
        responseType: 'token id_token',
        // Prompts the user for consent and to select an account.
        prompt: 'select_account consent',
        // Random secure nonce to be checked after the sign-in flow completes.
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
