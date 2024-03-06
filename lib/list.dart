import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesListPage extends StatefulWidget {
  final List<String> notes;

  const NotesListPage({super.key, required this.notes});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
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
