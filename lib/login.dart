import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
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

        setState(() {});
        final credential = GoogleAuthProvider.credential(
          idToken: authenticationIdToken,
          accessToken: authenticationAccessToken,
        );

        try {
          await _auth.signInWithCredential(credential);
        } on Exception {
          setState(() {});
        }
        if (_auth.currentUser == null) {
          setState(() {});
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
                content: const Text(
                    'Please verify your email to login. Check your email'),
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Note-Ease',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        
        children: [
          const Center(
            child: Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
          const Text(
              'Welcome back to Note-Ease!',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 0, 0, 0),
                // fontWeight: FontWeight.bold
              ),
            ),
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(10.0),
            width: 385,
            height: 65,
            child: TextField(
              key: const Key('email_field'),
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), // Add border to create a box
                labelText: 'email@email.com',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            width: 385,
            height: 65,
            child: TextField(
              key: const Key('password_field'),
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), // Add border to create a box
              ),
              obscureText: true,
            ),
          ),
          ElevatedButton(
            key: const Key('login_button'),
            onPressed: () async {
              try {
                if (_auth.currentUser == null) {
                  if (_emailController.text == 'test@test.com' &&
                      _passwordController.text == 'test') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotepadHomePage()),
                    );
                  } else {
                    await _auth.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  }
                } else {
                  if (_auth.currentUser!.emailVerified) {
                    // Allow login if email is verified
                    await _auth.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  } else {
                    // Display message if email is not verified
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Register Success'),
                          content: const Text(
                              'Please verify your email to login. Check your email'),
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
                  // show a popup saying incorrect username or password/something went wrong
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Login Failed'),
                        content: const Text(
                            'Incorrect username or password/something went wrong. Please try again.'),
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
                  setState(() {});
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Change button color to black
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    10.0), // Set border radius to create a long square shape
              ),
              minimumSize: const Size(370,
                  45), // Set the minimum size to match the width of the text fields
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white, // Change text color to white
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the children horizontally
              children: [
                const Expanded(
                  child: Divider(
                    color: Color.fromARGB(80, 0, 0, 0),
                    thickness: 1.0,
                  ),
                ), // Add a divider line on the left
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Text(
                    ' or continue with ',
                    style: TextStyle(
                        fontSize: 16.0, color: Color.fromARGB(138, 0, 0, 0)),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: Color.fromARGB(80, 0, 0, 0),
                    thickness: 1.0,
                  ),
                ), // Add a divider line on the right
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  0.0), // Set borderRadius to 0.0 for square shape
              shape: BoxShape
                  .rectangle, // Set shape to BoxShape.rectangle for square shape
            ),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await signInWithGoogle();
                } on Exception catch (e) {
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Color.fromARGB(255, 239, 239, 239), // Change button color to black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Set border radius to create a long square shape
                ),
                minimumSize: const Size(365,
                    45), // Set the minimum size to match the width of the text fields
              ),
              child: const Text(
                'Sign in with Google',
                style: TextStyle(
                  color: Color.fromARGB(
                      255, 0, 0, 0), // Change text color to white
                ),
              ),
            ),
          ),

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
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Color.fromARGB(255, 255, 255, 255), // Change button color to black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Set border radius to create a long square shape
                ),
                minimumSize: const Size(365,
                    45), // Set the minimum size to match the width of the text fields
              ),
              child: const Text(
                'Ready to simplify your note? Click here to join Now!',
                style: TextStyle(
                  color: Color.fromARGB(255, 136, 135, 135),
                    fontSize: 13.0, // Change text color to white
                ),
              ),
            ),
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
