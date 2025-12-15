import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/screens/create_note_screen.dart';
import 'package:notio/widgets/animated_logo.dart';
import 'package:notio/widgets/note_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = [];

  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
  }

  Future<void> _navigateToCreateNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNoteScreen()),
    );

    if (result != null && result is Note) {
      _addNote(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background for a subtle premium feel
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF1A1A2E), // Slight deep indigo tint at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: Row(
                  children: [
                    const AnimatedLogo(size: 32, animate: false),
                    const SizedBox(width: 12),
                    Text(
                      'NOTIO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning 👋',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to write something smart?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _notes.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet. Tap + to create one!',
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final note = _notes[index];
                          return NoteCard(
                            title: note.title.isEmpty ? 'Untitled' : note.title,
                            content: note.content,
                            date:
                                '${note.createdAt.day}/${note.createdAt.month}',
                          );
                        }, childCount: _notes.length),
                      ),
                    ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToCreateNote,
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
