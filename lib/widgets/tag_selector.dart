import 'package:flutter/material.dart';
import 'package:notio/models/tag.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onSelectionChanged;
  final Function(String name, int color) onTagCreated;
  final Function(String tagId)? onTagDeleted; // New callback

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
    required this.onTagCreated,
    this.onTagDeleted,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _isCreating = false;
  int _selectedColor = 0xFF6C63FF;

  // Modern neon palette
  final List<int> _colors = [
    0xFF6C63FF, // Indigo
    0xFFFF6B6B, // Red
    0xFF4ECDC4, // Teal
    0xFFFFD93D, // Yellow
    0xFF95A5A6, // Grey
    0xFFD35400, // Orange
    0xFF8E44AD, // Purple
    0xFF2ECC71, // Green
    0xFFE91E63, // Pink
    0xFF00E5FF, // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Tag> get _filteredTags {
    if (_searchQuery.isEmpty) return widget.availableTags;
    return widget.availableTags
        .where(
          (tag) => tag.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _toggleTag(String id) {
    final newSelection = List<String>.from(widget.selectedTagIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _createTag() {
    if (_searchQuery.isNotEmpty) {
      widget.onTagCreated(_searchQuery, _selectedColor);
      _searchController.clear();
      setState(() {
        _isCreating = false;
        // Reset color to default or random? Keep default for consistency
        _selectedColor = 0xFF6C63FF;
      });
    }
  }

  void _confirmDelete(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E).withOpacity(0.95),
        title: const Text('Delete Tag?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${tag.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              widget.onTagDeleted?.call(tag.id);
              Navigator.pop(context); // Close Dialog
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism container
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Manage ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextSpan(
                          text: 'Tags',
                          style: TextStyle(
                            color: const Color(0xFF6C63FF).withOpacity(0.9),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isCreating)
                    TextButton(
                      onPressed: () {
                        setState(() => _isCreating = false);
                      },
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: const Text('Cancel'),
                    )
                  else
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.white70),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _isCreating ? _buildCreationView() : _buildSelectionView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    final showCreateOption = _searchQuery.isNotEmpty &&
        !widget.availableTags.any(
          (t) => t.name.toLowerCase() == _searchQuery.toLowerCase(),
        );

    return Column(
      key: const ValueKey('selection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Search Field
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: const Color(0xFF6C63FF),
            decoration: InputDecoration(
              hintText: 'Search or create...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon:
                  Icon(Icons.search, color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tags Grid
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
            minHeight: 120,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (showCreateOption) _buildCreateChip(),
                if (_filteredTags.isEmpty && !showCreateOption)
                  _buildEmptyState(),
                ..._filteredTags.map((tag) => _buildTagChip(tag)),
              ].animate(interval: 50.ms).fade().scale(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.label_off_outlined,
              size: 40, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            'No tags found',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateChip() {
    return GestureDetector(
      onTap: () {
        setState(() => _isCreating = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 10,
              ),
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            Text(
              'Create "$_searchQuery"',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = widget.selectedTagIds.contains(tag.id);
    final color = Color(tag.color);

    return GestureDetector(
      onTap: () => _toggleTag(tag.id),
      onLongPress: () => _confirmDelete(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              tag.name,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationView() {
    return Column(
      key: const ValueKey('creation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.new_label_outlined, color: Color(0xFF6C63FF)),
              const SizedBox(width: 12),
              Text(
                _searchQuery,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose a Color',
          style: TextStyle(
              color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _colors
              .map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Color(color).withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              })
              .toList()
              .animate(interval: 50.ms)
              .scale(curve: Curves.easeOutBack),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _createTag,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(_selectedColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Color(_selectedColor).withOpacity(0.5),
            ),
            child: const Text(
              'Create Tag',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate().slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
      ],
    );
  }
}
