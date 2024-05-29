import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testnote/list.dart';
import 'package:testnote/login.dart';
import 'package:url_launcher/url_launcher.dart';

class NotepadHomePage extends StatefulWidget {
  const NotepadHomePage({super.key});

  @override
  State<NotepadHomePage> createState() => _NotepadHomePageState();
}

class _NotepadHomePageState extends State<NotepadHomePage> {
  Map<int, String> notes = {};
  int editingIndex = -1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _noteController = QuillController(
      readOnly: false,
      keepStyleOnNewLine: false,
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0));
  final FirebaseFirestore db = FirebaseFirestore.instance;
  dynamic userData;
  dynamic notesDocRef;
  dynamic notesListener;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (editingIndex != -1) {
        _noteController.clear();
      }
      if (user == null) {
        notesListener?.cancel();
        notesDocRef = null;
        userData = null;
        editingIndex = -1;
      } else {
        getLoginData();
      }
      _loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          key: const Key('notes_list_button'),
          onTap: () async {
            await selectNotesFromList(context);
          },
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(
                Icons.folder_copy_outlined,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            // Open the link when the title is clicked
            launchUrl(Uri(
              scheme: 'https',
              host: 'binusianorg-my.sharepoint.com',
              path:
                  '/personal/bill_elim_binus_ac_id/_layouts/15/guestaccess.aspx',
              queryParameters: {
                'share': 'EkEQg25whCZKtZOdahpRq5kBQybA6nFJ-an02U60GhuOdg',
                'e': 'pW9qBv',
              },
            ));
          },
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              "Notease - v0.5.0 | 4 April 2024",
              style: TextStyle(
                color: Color.fromARGB(255, 30, 29, 29),
                fontWeight: FontWeight.bold,
              ),
            ),

          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(
          //     Icons.share_rounded,
          //     color: Colors.black,
          //   ),
          //   onPressed: () {
          //     // Handle Share button
          //   },
          // ),
          IconButton(
            key: const Key('save_note_button'),
            icon: const Icon(Icons.save_rounded, color: Colors.black),
            onPressed: () {
              // Handle save button press
              _addNote();
            },
          ),
          IconButton(
            key: const Key('log_button'),
            icon: Icon(_auth.currentUser == null ? Icons.login : Icons.logout),
            onPressed: () async {
              if (_auth.currentUser == null) {
                // Navigate to the login page
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              } else {
                try {
                  await GoogleSignIn().disconnect();
                } on Exception catch (e) {
                  // TODO
                }
                await _auth.signOut();
              }
            },
          ),
          if (_auth.currentUser != null) // Check if the username is not empty
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                getUsername(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _noteController,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _noteController,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                showSubscript: false,
                showSuperscript: false,
                showFontFamily: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> selectNotesFromList(BuildContext context) async {
    int oldEditingIndex = editingIndex;
    editingIndex = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NotesListPage(notes: notes, editingIndex: editingIndex),
          ),
        ) ??
        oldEditingIndex;
    if (editingIndex != -1) {
      _noteController.document =
          Document.fromJson(jsonDecode(notes[editingIndex]!));
    } else if (oldEditingIndex != editingIndex) {
      _noteController.clear();
    }
    setState(() {});
  }

  String getUsername() {
    if (userData != null) {
      return userData['username'];
    } else {
      return 'loading...';
    }
  }

  void getLoginData() {
    final currentUser = _auth.currentUser;
    if (userData == null && currentUser != null) {
      setState(() {});
      final docRef = db.collection("users").doc(currentUser.uid);
      docRef.get().then(
        (DocumentSnapshot doc) {
          notesDocRef = db.collection("notes").doc(_auth.currentUser?.uid);
          if (doc.exists == false) {
            docRef.set({
              'username': currentUser.email,
            });
            notesDocRef.set({
              'notes': {'0': r'[{"insert":"Hello, World!\n"}]'},
            });
            userData = {
              'username': currentUser.email,
            };
          } else {
            userData = doc.data() as Map<String, dynamic>;
          }
          notesListener = notesDocRef.snapshots().listen(
            (event) {
              _loadNotes();
            },
            onError: (error) {
              print("Listen failed: $error");
            },
          );
          editingIndex = -1;
        },
        onError: (e) => print("Error getting document: $e"),
      );
    }
  }

  void _addNote() async {
    if (editingIndex == -1) {
      editingIndex = notes.isEmpty ? 0 : notes.keys.reduce(max) + 1;
    }
    notes[editingIndex] =
        jsonEncode(_noteController.document.toDelta().toJson());

    if (_auth.currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'idx', notes.keys.map((el) => el.toString()).toList());
      await prefs.setStringList('notes', notes.values.toList());
    } else {
      notesDocRef.update({
        'notes.$editingIndex':
            jsonEncode(_noteController.document.toDelta().toJson()),
      }).then(
        (value) {},
        onError: (e) => print("Error saving note: $e"),
      );
    }
    setState(() {});
  }

  void _loadNotes() async {
    dynamic idx;
    dynamic savedNotes;
    if (notesDocRef == null) {
      final prefs = await SharedPreferences.getInstance();
      idx = prefs.getStringList('idx');
      savedNotes = prefs.getStringList('notes');
    } else {
      notesDocRef.get().then(
        (DocumentSnapshot doc) {
          dynamic savedNotesData = doc.data();
          if (savedNotesData != null) {
            savedNotesData = savedNotesData as Map<String, dynamic>;
            idx = savedNotesData['notes'].keys.toList().cast<String>();
            savedNotes = savedNotesData['notes'].values.toList().cast<String>();
            for (var i = 0; i < idx.length; i++) {
              notes[int.parse(idx[i])] = savedNotes[i];
            }
          }
        },
        onError: (e) => print("Error getting notes: $e"),
      );
    }
    notes.clear();
    if (savedNotes != null && idx != null) {
      for (var i = 0; i < idx.length; i++) {
        notes[int.parse(idx[i])] = savedNotes[i];
      }
    }
    setState(() {});
  }

  // void popup(String text) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Note Updated'),
  //         content: Text(text),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}
