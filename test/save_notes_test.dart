import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_test/flutter_quill_test.dart';
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
      // print(find.byType(QuillEditor)); 
      await tester.quillEnterText(find.byType(QuillEditor).first, 'Note 1 Testing Yes\n');
      await tester.tap(find.byKey(const Key('save_note_button')));
      // erase the content of note
      // await tester.quillUpdateEditingValue(find.byType(QuillEditor), 'a');
      await tester.tap(find.byKey(const Key('notes_list_button')));
      await tester.pumpAndSettle();
      // Print all text on the page
      final textFinder = find.byType(QuillEditor);
      final texts = tester.widgetList<QuillEditor>(textFinder);
      bool found = false;
      for (final text in texts) {
        if (text.configurations.controller.document.toPlainText() == 'Note 1 Testing Yes\n') {
          found = true;
        }
      }
      expect(found, true);
      // final textFinder = find.byType(Text);
      // final texts = tester.widgetList<Text>(textFinder);
      // for (final text in texts) {
      //   print(text.data);
      // }
      // expect(find.text('Note 1 Testing Yes'), findsOneWidget);
    });
  });
}
