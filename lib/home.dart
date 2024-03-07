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
  dynamic data;
  late DocumentReference notesDocRef;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _loadNotes();
      } else {
        getLoginData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notease'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              editingIndex = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesListPage(notes: notes),
                    ),
                  ) ??
                  -1;
              setState(() {
                // go to the notes list page
                if (editingIndex != -1) {
                  _noteController.text = notes[editingIndex]!;
                } else {
                  _noteController.clear();
                }
              });
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
                data = null;
                editingIndex = -1;
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

  String getUsername() {
    if (data != null) {
      return data['username'];
    } else {
      getLoginData();
      return 'loading...';
    }
  }

  void getLoginData() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {});
      final docRef = db.collection("users").doc(currentUser.uid);
      docRef.get().then(
        (DocumentSnapshot doc) {
          notesDocRef = db.collection("notes").doc(_auth.currentUser?.uid);
          notesDocRef.snapshots().listen((event) {
            _loadNotes();
          });
          data = doc.data() as Map<String, dynamic>;
          editingIndex = -1;
          _loadNotes();
        },
        onError: (e) => print("Error getting document: $e"),
      );
    }
  }

  void _addNote() {
    if (_auth.currentUser == null) {
      setState(() {
        if (editingIndex != -1) {
          // Update existing note
          notes[editingIndex] = _noteController.text;
        } else {
          // Add new note
          final int newIndex;
          if (notes.isEmpty) {
            newIndex = 0;
          } else {
            newIndex = notes.keys.reduce(max) + 1;
          }
          // notes.add(_noteController.text);
          notes[newIndex] = _noteController.text;
          editingIndex = newIndex;
        }
        _saveNotes();
      });
    } else {
      if (editingIndex != -1) {
        notes[editingIndex] = _noteController.text;
        notesDocRef.update({
          'notes.$editingIndex': _noteController.text,
        }).then(
          (value) {
            setState(() {});
          },
          onError: (e) => popup("Error saving note: $e"),
        );
      } else {
        final int newIndex;
        if (notes.isEmpty) {
          newIndex = 0;
        } else {
          newIndex = notes.keys.reduce(max) + 1;
        }
        // notes.add(_noteController.text);
        notes[newIndex] = _noteController.text;
        editingIndex = newIndex;
        notesDocRef.update({
          'notes.$editingIndex': _noteController.text,
        }).then(
          (value) {
            setState(() {});
          },
          onError: (e) => popup("Error saving note: $e"),
        );
      }
    }
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'idx', notes.keys.map((el) => el.toString()).toList());
    await prefs.setStringList('notes', notes.values.toList());
  }

  void _loadNotes() async {
    if (_auth.currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getStringList('idx');
      final savedNotes = prefs.getStringList('notes');
      if (savedNotes != null && idx != null) {
        notes.clear();
        for (var i = 0; i < idx.length; i++) {
          notes[int.parse(idx[i])] = savedNotes[i];
        }
        setState(() {});
      }
    } else {
      notes = {};
      notesDocRef.get().then(
        (DocumentSnapshot doc) {
          dynamic savedNotes = doc.data() as Map<String, dynamic>;
          if (savedNotes != null) {
            final idx = savedNotes['notes'].keys.toList().cast<String>();
            final savedNotesStrings =
                savedNotes['notes'].values.toList().cast<String>();
            for (var i = 0; i < idx.length; i++) {
              notes[int.parse(idx[i])] = savedNotesStrings[i];
            }
            setState(() {});
          }
        },
        onError: (e) => print("Error getting notes: $e"),
      );
    }
  }

  void popup(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Note Updated'),
          content: Text(text),
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
