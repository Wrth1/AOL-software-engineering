import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotepadHomePage(),
    );
  }
}

class NotepadHomePage extends StatefulWidget {
  const NotepadHomePage({super.key});

  @override
  _NotepadHomePageState createState() => _NotepadHomePageState();
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

class NotesListPage extends StatefulWidget {
  final List<String> notes;

  const NotesListPage({Key? key, required this.notes}) : super(key: key);

  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
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
                return ListTile(
                  title: Text(widget.notes[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Handle delete button press
                      _deleteNoteAtIndex(context, index);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context, index);
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
    setState(() {
      // Remove the note at the specified index from the notes list
      widget.notes.removeAt(index);
      _saveNotes();
    });
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notes', widget.notes);
  }
}
