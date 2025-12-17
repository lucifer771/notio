import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notio/utils/constants.dart';
import 'package:notio/widgets/cross_platform_image.dart';

class AvatarSelectorSheet extends StatefulWidget {
  final int selectedAvatarIndex;
  final int selectedFrameIndex;
  final String? currentImagePath;
  final Function(int) onAvatarSelected;
  final Function(int) onFrameSelected;
  final Function(String?) onImagePicked;

  const AvatarSelectorSheet({
    super.key,
    required this.selectedAvatarIndex,
    required this.selectedFrameIndex,
    this.currentImagePath,
    required this.onAvatarSelected,
    required this.onFrameSelected,
    required this.onImagePicked,
  });

  @override
  State<AvatarSelectorSheet> createState() => _AvatarSelectorSheetState();
}

class _AvatarSelectorSheetState extends State<AvatarSelectorSheet> {
  final ImagePicker _picker = ImagePicker();

  // Frame Colors Mock
  final List<Color> _frameColors = [
    Colors.transparent, // None
    const Color(0xFF00E5FF), // Neon Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF00FF), // Cyberpunk
    const Color(0xFF6C63FF), // Purple
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onImagePicked(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customize Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Photo Actions ---
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickImage,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 16),
              if (widget.currentImagePath != null) ...[
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Remove Photo',
                    onTap: () => widget.onImagePicked(null),
                    color: Colors.redAccent,
                    isOutlined: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // --- Predefined Avatars ---
          const Text(
            'Choose Avatar',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.avatars.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final isSelected = widget.selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () => widget.onAvatarSelected(index),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withOpacity(0.2)
                          : const Color(0xFF0A0E21),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: const Color(0xFF6C63FF), width: 2)
                          : null,
                    ),
                    child: Icon(
                      AppConstants.avatars[index],
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // --- Frames ---
          const Text(
            'Choose Frame',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _frameColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final color = _frameColors[index];
                final isSelected = widget.selectedFrameIndex == index;
                return GestureDetector(
                  onTap: () => widget.onFrameSelected(index),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E21),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (color == Colors.transparent
                                  ? Colors.grey[800]!
                                  : color),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: color != Colors.transparent
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          border: Border.all(
            color: isOutlined ? color.withOpacity(0.5) : color.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
