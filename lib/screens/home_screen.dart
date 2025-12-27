import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/models/tag.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/models/reminder.dart';
import 'package:notio/screens/note_editor_screen.dart';
import 'package:notio/screens/profile_screen.dart';
import 'package:notio/widgets/search_overlay.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/widgets/animated_logo.dart';
import 'package:notio/widgets/note_card.dart';
import 'package:notio/widgets/collaboration_animation.dart';
import 'package:notio/widgets/reminder_selector.dart';
import 'package:notio/services/notification_service.dart';
import 'package:notio/widgets/settings_content.dart';
import 'package:notio/utils/translations.dart'; // Import extensions
import 'package:notio/services/localization_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<Tag> _tags = [];
  UserProfile _userProfile = UserProfile.guest();

  int _selectedIndex = 0;

  // State for Tags and Search
  String? _selectedTagId;
  bool _isTagsExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  // Reminders list (still dummy for now as per plan focus on Tags/Notes persistence first, but keeping structure)
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    NotificationService().init();
  }

  void _loadData() {
    setState(() {
      _notes = StorageService().getNotes();
      _tags = StorageService().getTags();
      _userProfile = StorageService().getUserProfile();
      _reminders = StorageService().getReminders();
    });
  }

  // ... (Save Notes/Tags methods)

  void _saveNotes() {
    StorageService().saveNotes(_notes);
  }

  void _saveTags() {
    StorageService().saveTags(_tags);
  }

  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
    _saveNotes();
  }

  void _saveReminders() {
    StorageService().saveReminders(_reminders);
  }

  // ... (Add Note/Tag methods)

  Future<void> _addReminder() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReminderSelector(
        onReminderCreated: (reminder) {
          setState(() {
            _reminders.add(reminder);
          });
          _saveReminders();
          NotificationService().scheduleReminder(reminder);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Reminder set for ${reminder.time.format(context)}'),
              backgroundColor: const Color(0xFF6C63FF),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _addTag(Tag tag) {
    if (!_tags.any((t) => t.name == tag.name)) {
      setState(() {
        _tags.add(tag);
      });
      _saveTags();
    }
  }

  void _deleteTag(String tagId) {
    setState(() {
      _tags.removeWhere((t) => t.id == tagId);
      // Also remove this tag from all notes? Optional but good for consistency
      // For now, just remove the tag definition.
    });
    _saveTags();
  }

  Future<void> _navigateToCreateNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          availableTags: _tags,
          onTagCreated: _addTag,
          onTagDeleted: _deleteTag,
        ),
      ),
    );

    if (result != null && result is Note) {
      _addNote(result);
    }
  }

  Future<void> _navigateToEditNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          availableTags: _tags,
          onTagCreated: _addTag,
          onTagDeleted: _deleteTag,
        ),
      ),
    );

    if (result != null) {
      if (result == 'DELETE_NOTE') {
        setState(() {
          _notes.removeWhere((n) => n.id == note.id);
        });
        _saveNotes();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      } else if (result is Note) {
        setState(() {
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = result;
          }
        });
        _saveNotes();
      }
    }
  }

  // ... (Methods for UI building)

  void _showCreateTagDialog() {
    // Simple dialog to create tag from Home Screen
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Create New Tag',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Tag Name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTag(
                  Tag(
                    id: const Uuid().v4(),
                    name: controller.text,
                    noteCount: 0,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showWelcomeAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return CollaborationAnimation(
          user: _userProfile,
          onComplete: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes for real-time translation updates
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.currentLocale,
      builder: (context, locale, child) {
        return Scaffold(
          extendBody: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  const Color(0xFF0F0F1A),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  _buildTagsContent(),
                  _buildRemindersContent(),
                  const SettingsContent(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton:
              _selectedIndex == 0 ? _buildFloatingActionButton() : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildHomeContent() {
    // Filter notes based on selection
    final filteredNotes = _selectedTagId == null
        ? _notes
        : _notes.where((n) => n.tags.contains(_selectedTagId)).toList();

    // Also filter by search query if needed (optional implementation detail, but good for UX)
    final displayNotes = _searchController.text.isEmpty
        ? filteredNotes
        : filteredNotes
            .where(
              (n) =>
                  n.title.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ||
                  n.content.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ),
            )
            .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent, // Keep it clean
          title: Row(
            children: [
              GestureDetector(
                onTap: _showWelcomeAnimation,
                child: const AnimatedLogo(size: 32, animate: false),
              ),
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
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  _loadData(); // Refresh on return
                },
                child: Container(
                  padding: const EdgeInsets.all(2), // Border width
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _userProfile.frameIndex == 0
                          ? Colors.transparent
                          : const Color(0xFF00E5FF), // Simplification for now
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 18,
                    child: _userProfile.avatarIndex == 0
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : Icon(
                            // We need access to the same icon list or just use a generic one if index > 0
                            // For simplicity, let's just use person for 0 and face for others or duplicate list
                            Icons.face,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'hello'.tr}, ${_userProfile.name} 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 20),
                // --- Search Bar ---
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => SearchOverlay(
                          notes: _notes, // Pass all notes
                          onNoteSelected: _navigateToEditNote,
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'searchBar',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            'search_notes'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // --- Tags Section ---
                _buildTagsSection(),
              ],
            ),
          ),
        ),
        displayNotes.isEmpty
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
                        _selectedTagId == null
                            ? 'No notes yet. Tap + to create one!'
                            : 'No notes found with this tag.',
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = displayNotes[index];
                    return NoteCard(
                      title: note.title.isEmpty ? 'Untitled' : note.title,
                      content: note.content,
                      date: '${note.createdAt.day}/${note.createdAt.month}',
                      onTap: () => _navigateToEditNote(note),
                    );
                  }, childCount: displayNotes.length),
                ),
              ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildTagsSection() {
    if (_tags.isEmpty) {
      return _buildEmptyTagsState();
    }

    // Smart logic: toggle between expanded wrap and scrolling list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tags'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'organize_notes'.tr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            IconButton(
              onPressed: _showCreateTagDialog, // Or open full manager
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF6C63FF),
              ),
              tooltip: 'Manage Tags',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isTagsExpanded
              ? Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    ..._tags.map((tag) => _buildTagChip(tag)),
                    if (_tags.length > 6) _buildExpandButton(isExpanded: true),
                  ],
                )
              : SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._tags.take(6).map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildTagChip(tag),
                            ),
                          ),
                      if (_tags.length > 6)
                        _buildExpandButton(isExpanded: false),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExpandButton({required bool isExpanded}) {
    return GestureDetector(
      onTap: () => setState(() => _isTagsExpanded = !isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExpanded ? 'less'.tr : 'more'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selectedTagId == tag.id;
    final tagColor = Color(tag.color);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTagId = isSelected ? null : tag.id; // Toggle
        });
      },
      onLongPress: () => _showTagOptions(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? tagColor.withOpacity(0.2) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? tagColor : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tagColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: tagColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (tag.noteCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${tag.noteCount}',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTagsState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.label_outline, size: 48, color: Colors.grey[800]),
          const SizedBox(height: 8),
          Text("no_tags".tr, style: TextStyle(color: Colors.grey[600])),
          TextButton(
            onPressed: _showCreateTagDialog,
            child: Text("create_first_tag".tr),
          ),
        ],
      ),
    );
  }

  void _showTagOptions(Tag tag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement rename dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.white),
              title: const Text(
                'Change Color',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement color picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Tag',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTag(tag.id);
                if (_selectedTagId == tag.id) {
                  setState(() => _selectedTagId = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsContent() {
    return Column(
      children: [
        _buildHeader('tags'.tr),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tag = _tags[index];
              final tagColor = Color(tag.color);
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E21),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tagColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: tagColor.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tag.noteCount} notes',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSmallIconButton(
                          Icons.edit_outlined,
                        ), // Edit could simply open a dialog to rename
                        const SizedBox(width: 8),
                        _buildSmallIconButton(
                          Icons.delete_outline,
                          onTap: () => _deleteTag(tag.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          child: _buildDottedButton('Create Tag', onTap: _showCreateTagDialog),
        ),
      ],
    );
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    _saveReminders();
    await NotificationService().cancelReminder(reminder);
  }

  Widget _buildRemindersContent() {
    return Column(
      children: [
        _buildHeader('Reminders'),
        Expanded(
          child: _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders set',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _reminders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E21),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reminder.time.format(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildSmallIconButton(Icons.edit_outlined),
                                  const SizedBox(width: 8),
                                  _buildSmallIconButton(
                                    Icons.delete_outline,
                                    isRed: true,
                                    onTap: () => _deleteReminder(reminder),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRelativeDate(reminder.dateTime),
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[800], height: 1),
                          const SizedBox(height: 16),
                          Text(
                            reminder.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (reminder.repeat != 'None')
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFF6C63FF),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reminder.repeat,
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 110),
          child: Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: _addReminder,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8E8AFF), Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x666C63FF),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == tomorrow) return 'Tomorrow';
    return '${date.day} ${_getMonth(date.month)}, ${date.year}';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF6C63FF),
              size: 24,
            ),
            onPressed: () => _onItemTapped(0), // Back to home
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon, {
    bool isRed = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isRed ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF),
        ),
      ),
    );
  }

  Widget _buildDottedButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.local_offer_rounded, 'Tags'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.notifications_rounded, 'Reminders'),
            _buildNavItem(3, Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF6C63FF) : Colors.grey[600];

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
