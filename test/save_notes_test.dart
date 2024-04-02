import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:testnote/home.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocks();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Save Notes', () {
    Firebase.initializeApp();
    testWidgets('Initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotepadHomePage()));
      await tester.enterText(
          find.byType(TextField).first, 'Note 1 Testing Yes');
      await tester.tap(find.byKey(const Key('save_note_button')));
      // erase the content of note
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.byKey(const Key('notes_list_button')));
      await tester.pumpAndSettle();
      expect(find.text('Note 1 Testing Yes'), findsOneWidget);
    });
  });
}
