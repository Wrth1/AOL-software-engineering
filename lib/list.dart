import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testnote/login.dart';

class NotesListPage extends StatefulWidget {
  final Map<int, String> notes;
  final int editingIndex;

  const NotesListPage({super.key, required this.notes, required this.editingIndex});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  dynamic userData;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notes List', 
            style: TextStyle(
              color: Color.fromARGB(255, 30, 29, 29),
              fontWeight: FontWeight.bold
            ),
          ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),

      // BUAT LOGIN TAPI GUE SKILL ISSUE COK ToT
      actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 45.0),
            child: IconButton(
              icon: Icon(_auth.currentUser == null ? Icons.login_rounded : Icons.logout_rounded, color: Colors.black,),
              onPressed: () async {
                if (_auth.currentUser == null){
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),  
                    ),
                  );
                } else{
                  await GoogleSignIn().disconnect();
                  await _auth.signOut();
                }
              },
            ),
          ),
          if (_auth.currentUser != null)
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
          child: ListView.builder(
            itemCount: widget.notes.length,
            itemBuilder: (context, index) {
              final noteKey = widget.notes.keys.elementAt(index);
              final noteValue = widget.notes.values.elementAt(index);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Menambahkan padding vertikal dan horizontal
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(right: 16.0), // Menambahkan padding kanan untuk teks
                    child: Text(noteValue),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: 8.0), // Menambahkan padding kiri untuk ikon sampah
                    child: IconButton(
                      icon: const Icon(Icons.delete_rounded),
                      onPressed: () {
                        // Handle delete button press
                        _deleteNoteAtIndex(context, noteKey);
                      },
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context, noteKey);
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),




  
    bottomNavigationBar: BottomAppBar(
      elevation: 0, // Menghapus efek bayangan
      shape: CircularNotchedRectangle(),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Membuat ikon berjarak
          children: [
            IconButton(
              icon: Icon(
                Icons.add_box_outlined,
                size: 30,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context, -1);
              },
            ),
            Text('New-note', style: TextStyle(fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    ),
  );
}

  void _deleteNoteAtIndex(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note', style: TextStyle(fontWeight: FontWeight.bold),),
          content: const Text('Are you sure you want to delete this note?', style: TextStyle(fontWeight: FontWeight.bold),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeNoteAtIndex(index);
              },
              child: Text('Delete', style: TextStyle(color: const Color.fromARGB(255, 254, 43, 43), fontWeight: FontWeight.bold),),
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

String getUsername() {
    if (userData != null) {
      return userData['username'];
    } else {
      return 'loading...';
    }
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'idx', widget.notes.keys.map((el) => el.toString()).toList());
    await prefs.setStringList('notes', widget.notes.values.toList());
  }
}