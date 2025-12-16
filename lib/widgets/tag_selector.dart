import 'package:flutter/material.dart';
import 'package:notio/models/tag.dart';

class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onSelectionChanged;
  final Function(String name, int color) onTagCreated;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onSelectionChanged,
    required this.onTagCreated,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;
  int _selectedColor = 0xFF6C63FF;

  // Predefined colors for tags
  final List<int> _colors = [
    0xFF6C63FF, // Indigo
    0xFFFF6B6B, // Red
    0xFF4ECDC4, // Teal
    0xFFFFD93D, // Yellow
    0xFF95A5A6, // Grey
    0xFFD35400, // Orange
    0xFF8E44AD, // Purple
    0xFF2ECC71, // Green
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Tags',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isCreating)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCreating = false;
                    });
                  },
                  child: const Text('Cancel'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isCreating) _buildCreationView() else _buildSelectionView(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSelectionView() {
    final showCreateOption =
        _searchQuery.isNotEmpty &&
        !widget.availableTags.any(
          (t) => t.name.toLowerCase() == _searchQuery.toLowerCase(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search or create tag...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
            minHeight: 100,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                if (showCreateOption)
                  ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text('Create "$_searchQuery"'),
                    backgroundColor: const Color(0xFF6C63FF),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCreating = true;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                  ),
                ..._filteredTags.map((tag) {
                  final isSelected = widget.selectedTagIds.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag.id),
                    backgroundColor: Color(tag.color).withValues(alpha: 0.1),
                    selectedColor: Color(tag.color).withValues(alpha: 0.3),
                    checkmarkColor: Color(tag.color),
                    labelStyle: TextStyle(
                      color: isSelected ? Color(tag.color) : Colors.grey[400],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Color(tag.color)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Tag: $_searchQuery',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Color',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Color(color).withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createTag,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Create Tag',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
