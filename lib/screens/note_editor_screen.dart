import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notio/models/note.dart';
import 'package:notio/models/tag.dart';
import 'package:notio/widgets/tag_selector.dart';
import 'package:notio/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<Tag> availableTags;
  final Function(Tag) onTagCreated;
  final Function(String)? onTagDeleted; // New Callback

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.availableTags,
    required this.onTagCreated,
    this.onTagDeleted,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

// ... (State class remains the same until _showTagSelector)

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedTagIds;
  late DateTime _currentDate;

  // New V2 Fields
  bool _isPinned = false;
  bool _isLocked = false;
  List<String> _imagePaths = [];
  String? _voicePath;
  Color _textColor = Colors.white;

  // AI & Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final GeminiService _geminiService = GeminiService(); // Use Service
  bool _isGenerating = false;
  String _aiStatus = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedTagIds = List.from(widget.note?.tags ?? []);
    _currentDate = widget.note?.updatedAt ?? DateTime.now();

    _isPinned = widget.note?.isPinned ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _imagePaths = List.from(widget.note?.imagePaths ?? []);
    _voicePath = widget.note?.voicePath;
    if (widget.note?.textColor != null) {
      _textColor = Color(widget.note!.textColor!);
    }

    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // No need for explicit dirty check if we save on exit/done always,
  // but let's keep the logic simple: Save on "Done" or Back.

  void _saveNote() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      tags: _selectedTagIds,
      type: widget.note?.type ?? NoteType.text,
      isPinned: _isPinned,
      isLocked: _isLocked,
      imagePaths: _imagePaths,
      voicePath: _voicePath,
      textColor: _textColor.value,
    );

    Navigator.pop(context, note);
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Note?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context, 'DELETE_NOTE');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  // --- Voice Typing ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              // Append logic
              if (val.recognizedWords.isNotEmpty && val.finalResult) {
                final currentText = _contentController.text;
                final space =
                    currentText.isNotEmpty && !currentText.endsWith(' ')
                        ? ' '
                        : '';
                _contentController.text =
                    '$currentText$space${val.recognizedWords}';
                _contentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _contentController.text.length),
                );
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- Realtime Streaming AI ---
  Future<void> _performAIMagic(String promptType) async {
    final text = _contentController.text;
    if (text.isEmpty && promptType != 'Generate Idea') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Write something first!')));
      return;
    }

    setState(() {
      _isGenerating = true;
      _aiStatus = 'Thinking...';
    });

    try {
      String prompt = '';
      bool replace = false;

      switch (promptType) {
        case 'Fix Grammar':
          prompt =
              'Fix grammar and spelling, keep same language. Return ONLY the fixed text: "$text"';
          replace = true;
          break;
        case 'Professional Rewrite':
          prompt = 'Rewrite this ensuring a professional tone: "$text"';
          replace = true;
          break;
        case 'Summarize':
          prompt = 'Summarize this in bullet points: "$text"';
          break;
        case 'Continue Writing':
          prompt = 'Continue writing creatively from here: "$text"';
          break;
        case 'Generate Idea':
          prompt = 'Generate a creative note idea about productivity.';
          break;
      }

      print('AI Magic Started: $promptType');
      print('Prompt: $prompt');

      // Use Streaming API via Service
      print('Creating Stream...');
      final stream = _geminiService.generateStream(prompt);
      print('Stream Created. Listening for chunks...');

      if (replace) {
        _contentController.text = ''; // Clear for replacement
      } else {
        if (_contentController.text.isNotEmpty) {
          _contentController.text += '\n\n';
        }
      }

      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          print('Chunk received: $chunk');
          setState(() {
            _aiStatus = 'Writing...';
            _contentController.text += chunk;
            // Scroll to bottom/end
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: _contentController.text.length),
            );
          });
        }
      }
      print('AI Magic Completed Successfully');
    } catch (e) {
      print('AI ERROR CAUGHT: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
    } finally {
      print('AI IsGenerating set to false');
      setState(() => _isGenerating = false);
    }
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: TagSelector(
          availableTags: widget.availableTags,
          selectedTagIds: _selectedTagIds,
          onSelectionChanged: (ids) {
            setState(() {
              _selectedTagIds = ids;
            });
          },
          onTagCreated: (name, color) {
            final newTag = Tag(
              id: const Uuid().v4(),
              name: name,
              noteCount: 0,
              color: color,
            );
            widget.onTagCreated(newTag);
            setState(() {
              _selectedTagIds.add(newTag.id);
            });
          },
          onTagDeleted: (tagId) {
            setState(() {
              _selectedTagIds.remove(tagId);
            });
            widget.onTagDeleted?.call(tagId);
          },
        ),
      ),
    );
  }

  void _showAIMagicSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Transparent to show blurred container
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFD700),
                    size: 28,
                  ).animate(onPlay: (loop) => loop.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                      ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI Magic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Real-time intelligent writing assistance.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildModernMagicTile(
                'Fix Grammar',
                'Corrects spelling & grammar',
                Icons.spellcheck,
                Colors.blue,
              ),
              _buildModernMagicTile(
                'Professional Rewrite',
                'Formal & polished tone',
                Icons.work_outline,
                Colors.amber,
              ),
              _buildModernMagicTile(
                'Summarize',
                'Create concise bullet points',
                Icons.summarize_outlined,
                Colors.purple,
              ),
              _buildModernMagicTile(
                'Continue Writing',
                'Let AI finish your thought',
                Icons.edit_note_outlined,
                Colors.green,
              ),
              _buildModernMagicTile(
                'Generate Idea',
                'Get a creative note idea',
                Icons.lightbulb_outline,
                Colors.cyan,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernMagicTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          Navigator.pop(context);
          _performAIMagic(title);
        },
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colors = [
          Colors.white,
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.yellowAccent,
          Colors.greenAccent,
          Colors.blueAccent,
          Colors.purpleAccent,
          Colors.pinkAccent,
        ];
        return Container(
          padding: const EdgeInsets.all(24),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎨 Choose Font Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _textColor = colors[index]);
                        Navigator.pop(context); // Close color picker
                        Navigator.pop(context); // Close options menu
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: _textColor == colors[index] ? 3 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors[index].withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme
      isScrollControlled: true, // Fix overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Note Options',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Font Colors Option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      title: const Text(
                        'Change Font Color',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      trailing: CircleAvatar(
                        backgroundColor: _textColor,
                        radius: 10,
                      ),
                      onTap: () => _showColorPicker(),
                    ),

                    _buildOptionTile(Icons.label_outline, 'Add Tag', () {
                      Navigator.pop(context);
                      _showTagSelector();
                    }),
                    _buildOptionTile(
                      _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      _isPinned ? 'Unpin Note' : 'Pin Note',
                      () {
                        setState(() => _isPinned = !_isPinned);
                        setModalState(() {});
                      },
                      isActive: _isPinned,
                    ),
                    _buildOptionTile(
                      _isLocked ? Icons.lock : Icons.lock_open,
                      _isLocked ? 'Unlock Note' : 'Lock Note',
                      () {
                        setState(() => _isLocked = !_isLocked);
                        setModalState(() {});
                      },
                      isActive: _isLocked,
                    ),
                    _buildOptionTile(Icons.image_outlined, 'Add Image', () {
                      Navigator.pop(context);
                      _pickImage();
                    }),
                    _buildOptionTile(Icons.mic_none, 'Add Voice Memo', () {}),
                    _buildOptionTile(Icons.share_outlined, 'Export', () {}),
                    _buildOptionTile(Icons.delete_outline, 'Delete', () {
                      Navigator.pop(context);
                      _deleteNote();
                    }, color: Colors.redAccent),
                    const SizedBox(height: 20), // Extra padding for safe area
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6C63FF).withOpacity(0.2)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? (isActive ? const Color(0xFF6C63FF) : Colors.white),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tags for display
    final displayedTags = widget.availableTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: _saveNote,
        ),
        actions: [
          if (_isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.push_pin, color: Color(0xFF6C63FF), size: 20),
            ),
          if (_isLocked)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.lock, color: Color(0xFF6C63FF), size: 20),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveNote,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags Row
                        if (displayedTags.isNotEmpty)
                          Container(
                            height: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: displayedTags.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final tag = displayedTags[index];
                                return Chip(
                                  label: Text(
                                    tag.name,
                                    style: TextStyle(
                                      color: Color(tag.color),
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Color(
                                    tag.color,
                                  ).withOpacity(0.15),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.all(0),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Color(tag.color),
                                  ),
                                  onDeleted: () => setState(
                                    () => _selectedTagIds.remove(tag.id),
                                  ),
                                );
                              },
                            ),
                          ),

                        TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Title',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentDate.day}/${_currentDate.month}/${_currentDate.year}  ${_currentDate.hour}:${_currentDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image Attachments
                        if (_imagePaths.isNotEmpty)
                          SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imagePaths.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          _imagePaths[index],
                                          height: 150,
                                          width: 150,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_imagePaths[index]),
                                          height: 150,
                                          width: 150,
                                          fit: BoxFit.cover,
                                        ),
                                );
                              },
                            ),
                          ),
                        if (_imagePaths.isNotEmpty) const SizedBox(height: 16),

                        TextField(
                          controller: _contentController,
                          style: TextStyle(
                            color: _textColor.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Start writing...',
                            hintStyle: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161622),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _isListening
                          ? _buildToolbarIcon(
                              Icons.mic_none,
                              _listen,
                              color: Colors.redAccent,
                            )
                              .animate(
                                onPlay: (loop) => loop.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 1000.ms,
                              )
                          : _buildToolbarIcon(Icons.mic_none, _listen),
                      _buildToolbarIcon(Icons.auto_awesome, () {
                        _showAIMagicSheet();
                      }, color: const Color(0xFFFFD700)),
                      _buildToolbarIcon(Icons.image_outlined, _pickImage),
                      _buildToolbarIcon(
                        Icons.local_offer_outlined,
                        _showTagSelector,
                      ),
                      _buildToolbarIcon(Icons.more_horiz, _showNoteOptions),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI Loading Overlay
          if (_isGenerating)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _aiStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.5, end: 0),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF6C63FF), size: 24),
      ),
    );
  }
}
