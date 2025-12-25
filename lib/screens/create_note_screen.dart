import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notio/models/note.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateNoteScreen extends StatefulWidget {
  final Note? note;
  const CreateNoteScreen({super.key, this.note});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _currentDate;

  // AI & Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final GeminiService _geminiService = GeminiService(); // Use Service
  bool _isGenerating = false;
  String _aiStatus = '';

  // Note Properties
  bool _isPinned = false;
  bool _isLocked = false;
  List<String> _imagePaths = [];
  String? _voicePath;
  List<String> _tags = [];
  Color _textColor = Colors.white;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.note?.updatedAt ?? DateTime.now();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _isPinned = widget.note?.isPinned ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _imagePaths = List.from(widget.note?.imagePaths ?? []);
    _voicePath = widget.note?.voicePath;
    _tags = List.from(widget.note?.tags ?? []);
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
        if (chunk.text != null) {
          print('Chunk received: ${chunk.text}');
          setState(() {
            _aiStatus = 'Writing...';
            _contentController.text += chunk.text!;
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

  // --- UI Components ---
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
                      )
                      .animate(onPlay: (loop) => loop.repeat(reverse: true))
                      .scale(
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

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Font Colors Option
              ListTile(
                leading: const Icon(
                  Icons.palette_outlined,
                  color: Colors.pinkAccent,
                ),
                title: const Text(
                  'Change Font Color',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: CircleAvatar(backgroundColor: _textColor, radius: 10),
                onTap: () => _showColorPicker(),
              ),

              const Divider(color: Colors.white10),

              // Lock Note
              ListTile(
                leading: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.blueAccent,
                ),
                title: const Text(
                  'Lock Note',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: _isLocked,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {
                    setState(() => _isLocked = val);
                    setSheetState(() {});
                  },
                ),
              ),

              // Pin Note
              ListTile(
                leading: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  'Pin Note',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: _isPinned,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) {
                    setState(() => _isPinned = val);
                    setSheetState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveNote() {
    if (_titleController.text.isEmpty &&
        _contentController.text.isEmpty &&
        widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final newNote = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: _tags,
      isPinned: _isPinned,
      isLocked: _isLocked,
      imagePaths: _imagePaths,
      voicePath: _voicePath,
      textColor: _textColor.value,
    );
    StorageService().saveNote(newNote);
    Navigator.pop(context, newNote);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePaths.add(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
            const Icon(Icons.push_pin, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          if (_isLocked)
            const Icon(Icons.lock, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _saveNote,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentDate.day}/${_currentDate.month}/${_currentDate.year}  ${_currentDate.hour}:${_currentDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      if (_imagePaths.isNotEmpty)
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePaths.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? Image.network(
                                        _imagePaths[index],
                                        height: 160,
                                        width: 160,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_imagePaths[index]),
                                        height: 160,
                                        width: 160,
                                        fit: BoxFit.cover,
                                      ),
                              );
                            },
                          ),
                        ),
                      if (_imagePaths.isNotEmpty) const SizedBox(height: 24),

                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          color: _textColor.withOpacity(0.9),
                          fontSize: 18,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
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
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
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

          // Bottom Toolbar
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _isListening
                      ? _buildToolbarBtn(
                              Icons.mic,
                              Colors.redAccent,
                              () => _listen(),
                            )
                            .animate(
                              onPlay: (loop) => loop.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.2, 1.2),
                              duration: 1000.ms,
                            )
                      : _buildToolbarBtn(
                          Icons.mic,
                          Colors.white,
                          () => _listen(),
                        ),

                  _buildToolbarBtn(
                    Icons.auto_awesome,
                    const Color(0xFFFFD700),
                    () => _showAIMagicSheet(),
                  ),
                  _buildToolbarBtn(
                    Icons.image_outlined,
                    Colors.white,
                    () => _pickImage(),
                  ),
                  _buildToolbarBtn(
                    Icons.more_horiz,
                    Colors.white,
                    () => _showOptionsSheet(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}
