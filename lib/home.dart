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
  List<String> notes = [];
  int editingIndex = -1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _noteController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  dynamic data;

  @override
  void initState() {
    super.initState();
    _loadNotes();
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
                  _noteController.text = notes[editingIndex];
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
                final currentUser = _auth.currentUser;
                if (currentUser != null) {
                  final docRef =
                      db.collection("users").doc(_auth.currentUser?.uid);
                  docRef.get().then(
                    (DocumentSnapshot doc) {
                      data = doc.data() as Map<String, dynamic>;
                      setState(() {
                        editingIndex = -1;
                        _loadNotes();
                      });
                    },
                    onError: (e) => print("Error getting document: $e"),
                  );
                }
              } else {
                await _auth.signOut();
                setState(() {
                  editingIndex = -1;
                  _loadNotes();
                });
              }
            },
          ),
          if (_auth.currentUser != null &&
              data != null) // Check if the username is not empty
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                data['username'],
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

  void _addNote() {
    setState(() {
      if (editingIndex != -1) {
        // Update existing note
        notes[editingIndex] = _noteController.text;
        // editingIndex = -1;
        // _noteController.clear();
      } else {
        // Add new note
        notes.add(_noteController.text);
        final newIndex = notes.length - 1;
        editingIndex = newIndex;
      }
      _saveNotes();
    });
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notes', notes);
  }

  void _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes');
    if (savedNotes != null) {
      setState(() {
        notes = savedNotes;
      });
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
