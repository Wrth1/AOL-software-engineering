import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testnote/list.dart';
import 'package:testnote/login.dart';

class NotepadHomePage extends StatefulWidget {
  const NotepadHomePage({super.key});

  @override
  State<NotepadHomePage> createState() => _NotepadHomePageState();
}

class _NotepadHomePageState extends State<NotepadHomePage> {
  Map<int, String> notes = {};
  int editingIndex = -1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _noteController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  dynamic userData;
  dynamic notesDocRef;
  dynamic notesListener;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
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
        title: const Text('Notease - v0.1'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              await selectNotesFromList(context);
            },
          ),
          IconButton(
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
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Enter your note',
              ),
              onSubmitted: (note) {
                _addNote();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote();
        },
        child: Icon(editingIndex == -1 ? Icons.add : Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      _noteController.text = notes[editingIndex]!;
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
          notesListener = notesDocRef.snapshots().listen(
            (event) {
              _loadNotes();
            },
            onError: (error) {
              print("Listen failed: $error");
            },
          );
          userData = doc.data() as Map<String, dynamic>;
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
    notes[editingIndex] = _noteController.text;

    if (_auth.currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'idx', notes.keys.map((el) => el.toString()).toList());
      await prefs.setStringList('notes', notes.values.toList());
    } else {
      notesDocRef.update({
        'notes.$editingIndex': _noteController.text,
      }).then(
        (value) {},
        onError: (e) => print("Error saving note: $e"),
      );
    }
    setState(() {});
  }

  void _loadNotes() async {
    if (notesDocRef == null) {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getStringList('idx');
      final savedNotes = prefs.getStringList('notes');
      notes.clear();
      if (savedNotes != null && idx != null) {
        for (var i = 0; i < idx.length; i++) {
          notes[int.parse(idx[i])] = savedNotes[i];
        }
      }
    } else {
      notesDocRef.get().then(
        (DocumentSnapshot doc) {
          dynamic savedNotes = doc.data() as Map<String, dynamic>;
          notes.clear();
          if (savedNotes != null) {
            final idx = savedNotes['notes'].keys.toList().cast<String>();
            final savedNotesStrings =
                savedNotes['notes'].values.toList().cast<String>();
            for (var i = 0; i < idx.length; i++) {
              notes[int.parse(idx[i])] = savedNotesStrings[i];
            }
          }
        },
        onError: (e) => print("Error getting notes: $e"),
      );
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
