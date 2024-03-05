import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notease'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              // go to the notes list page
              editingIndex = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesListPage(notes: notes),
                    ),
                  ) ??
                  -1;
              if (editingIndex != -1) {
                _noteController.text = notes[editingIndex];
              } else {
                _noteController.clear();
              }
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
        // popup('Note at index $editingIndex has been updated.');
        editingIndex = -1;
        _noteController.clear();
      } else {
        // Add new note
        notes.add(_noteController.text);
        final newIndex = notes.length - 1;
        // popup('Note at index $newIndex has been added.');
        editingIndex = newIndex;
      }
      // _noteController.clear();
    });
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

class NotesListPage extends StatelessWidget {
  final List<String> notes;

  const NotesListPage({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes List'),
        backgroundColor: const Color.fromARGB(255, 227, 179, 235),
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notes[index]),
            onTap: () {
              Navigator.pop(context, index);
            },
          );
        },
      ),
    );
  }
}
