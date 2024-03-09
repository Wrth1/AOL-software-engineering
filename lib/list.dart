import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesListPage extends StatefulWidget {
  final Map<int, String> notes;
  final int editingIndex;

  const NotesListPage({super.key, required this.notes, required this.editingIndex});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes List'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, -1);
            },
            child: const Text('New Note'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.notes.length,
              itemBuilder: (context, index) {
                final noteKey = widget.notes.keys.elementAt(index);
                final noteValue = widget.notes.values.elementAt(index);
                return ListTile(
                  title: Text(noteValue),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Handle delete button press
                      _deleteNoteAtIndex(context, noteKey);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context, noteKey);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNoteAtIndex(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeNoteAtIndex(index);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _removeNoteAtIndex(int index) {
    if (_auth.currentUser == null) {
      setState(() {
        widget.notes.remove(index);
        _saveNotes();
      });
    } else {
      final docRef = db.collection("notes").doc(_auth.currentUser?.uid);
      docRef.update({
        'notes.$index': FieldValue.delete(),
      }).then((value) {
        setState(() {
          widget.notes.remove(index);
        });
      });
    }
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'idx', widget.notes.keys.map((el) => el.toString()).toList());
    await prefs.setStringList('notes', widget.notes.values.toList());
  }
}
