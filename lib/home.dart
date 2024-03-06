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

  final TextEditingController _noteController = TextEditingController();

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
            icon: const Icon(Icons.login),
            onPressed: () {
              // Navigate to the login page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
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
