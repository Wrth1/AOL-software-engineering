import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:testnote/login.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocks();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCMQqwKfw81a0Pd7YrA2_JcnOrBsuB2DcY',
        appId: '1:967077780131:web:3a907654affceb5fafbd16',
        messagingSenderId: '967077780131',
        projectId: 'notetestlol',
        authDomain: 'notetestlol.firebaseapp.com',
        storageBucket: 'notetestlol.appspot.com',
        measurementId: 'G-0VMD3XKJ32',
      ),
      name: "TEST",
    );
  });

  group('Login Test', () {
    testWidgets('Initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test');
      await tester.tap(find.byKey(const Key('login_button')));
      // print all the element on the page
      // debugDumpApp();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("notes_list_button")), findsOne);
    });
  });
}
