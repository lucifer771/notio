import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/screens/auth_screen.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/utils/constants.dart';
import 'package:notio/widgets/cross_platform_image.dart';
import 'package:notio/widgets/profile/avatar_selector_sheet.dart';
import 'package:notio/widgets/profile/profile_menu_item.dart';
import 'package:notio/widgets/profile/profile_stat_card.dart';
import 'package:notio/widgets/verification_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;
  bool _isEditing = false; // "Edit Mode" tracks UI state
  bool _isLoading = false; // Cloud-ready loading state

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Mock Frame Colors (Logic centralized here for now, could act as "Repository" cache)
  final List<Color> _frameColors = [
    Colors.transparent,
    const Color(0xFF00E5FF),
    const Color(0xFFFFD700),
    const Color(0xFFFF00FF),
    const Color(0xFF6C63FF),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Cloud-Ready: Simulate async fetch (even though local now)
  Future<void> _loadUserProfile() async {
    // In a real cloud app, this would be `await _repository.getUserProfile()`
    final profile = StorageService().getUserProfile();
    setState(() {
      _user = profile;
      _nameController.text = _user.name;
      _usernameController.text = _user.username;
      _bioController.text = _user.bio;
    });
  }

  // Cloud-Ready: Async Save Operation
  Future<void> _saveProfile({bool showMessage = true}) async {
    setState(() => _isLoading = true);

    // Simulate Network Latency
    // await Future.delayed(const Duration(milliseconds: 500));

    final updatedUser = _user.copyWith(
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
    );

    // Persist
    await StorageService().saveUserProfile(updatedUser);

    if (mounted) {
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      }
    }
  }

  // --- Actions ---

  void _openAvatarSelector() {
    if (!_isEditing) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectorSheet(
        selectedAvatarIndex: _user.avatarIndex,
        selectedFrameIndex: _user.frameIndex,
        currentImagePath: _user.profileImagePath,
        onAvatarSelected: (index) {
          setState(() {
            _user = _user.copyWith(
              avatarIndex: index,
              // If selecting a preset, verify if we should clear custom image?
              // For now, let's keep them independent or prioritized.
            );
          });
          // Auto-save purely for immediate feedback or keep in draft?
          // Let's keep in draft until "Save" is pressed for text,
          // but usually avatar changes are instant. Let's make it draft for now.
        },
        onFrameSelected: (index) {
          setState(() => _user = _user.copyWith(frameIndex: index));
        },
        onImagePicked: (path) {
          setState(() => _user = _user.copyWith(profileImagePath: path));
          // If clearing image (path == null), it falls back to avatar
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleAppLock(bool value) async {
    if (value && (_user.password == null || _user.password!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set a password first by signing up'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // Cloud-ready: Optimistic update or wait? Let's wait.
    setState(() => _isLoading = true);
    final updatedUser = _user.copyWith(isAppLockEnabled: value);
    await StorageService().saveUserProfile(updatedUser);
    setState(() {
      _user = updatedUser;
      _isLoading = false;
    });
  }

  void _changePasswordFlow() {
    showDialog(
      context: context,
      builder: (_) => VerificationDialog(
        email: _user.email,
        onVerified: () {
          _showNewPasswordDialog(); // Continue flow
        },
      ),
    );
  }

  void _showNewPasswordDialog() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Set New Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Make sure it's secure and at least 6 characters.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                hintText: 'New Password',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password too short')),
                );
                return;
              }
              // Update Password
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final updatedUser = _user.copyWith(password: passController.text);
              await StorageService().saveUserProfile(updatedUser);
              setState(() {
                _user = updatedUser;
                _isLoading = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    // Cloud-ready: SignOut from Auth Provider
    final guest = UserProfile.guest();
    await StorageService().saveUserProfile(guest);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      extendBodyBehindAppBar: true, // For glassmorphism header
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Glass effect below
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (!_user.isGuest)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit_outlined,
                color: const Color(0xFF6C63FF), // Brand color
              ),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        // Subtle Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1226), // Slightly lighter top
              Color(0xFF0A0E21), // Deep dark bottom
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 100,
            bottom: 40,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // --- Header ---
              _buildProfileHeader(),
              const SizedBox(height: 32),

              // --- Stats Grid ---
              if (!_user.isGuest && !_isEditing) _buildStatsGrid(),

              if (_user.isGuest) _buildGuestPrompt(),

              // --- Editable Fields ---
              if (!_user.isGuest && _isEditing) _buildEditFields(),

              const SizedBox(height: 40),

              // --- Settings Menu ---
              if (!_user.isGuest && !_isEditing) _buildSettingsMenu(),

              const SizedBox(height: 40),

              // --- Action Button ---
              if (_user.isGuest)
                _buildActionButton(
                  'Join Notio Now',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                )
              else if (!_isEditing)
                _buildActionButton(
                  'Sign Out',
                  isDestructive: true,
                  onTap: _logout,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final frameColor = _frameColors[_user.frameIndex];

    return Column(
      children: [
        GestureDetector(
          onTap: _openAvatarSelector,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Frame Glow
              if (frameColor != Colors.transparent)
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: frameColor.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

              // Avatar Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E2C),
                  border: Border.all(
                    color: frameColor == Colors.transparent
                        ? Colors.grey[800]!
                        : frameColor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _user.profileImagePath != null
                      ? CrossPlatformImage(path: _user.profileImagePath!)
                      : Center(
                          child: Icon(
                            AppConstants.avatars[_user.avatarIndex %
                                AppConstants.avatars.length],
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Edit Badge
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Name & Bio (Read-Only View)
        if (!_isEditing) ...[
          Text(
            _user.isGuest ? 'Guest User' : _user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_user.username.isNotEmpty && !_user.isGuest)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '@${_user.username}',
                style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 16),
              ),
            ),
          if (_user.bio.isNotEmpty && !_user.isGuest)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
              child: Text(
                _user.bio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], height: 1.5),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGuestPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock, size: 40, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Unlock Cloud Sync & Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to see your productivity score and sync notes across devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final noteCount = StorageService().getNotes().length;
    final tagCount = StorageService().getTags().length;
    // Simple productivity calc
    final score = ((noteCount * 5) + (tagCount * 2)).clamp(0, 100);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                title: 'Total Notes',
                icon: Icons.description,
                value: '$noteCount',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ProfileStatCard(
                title: 'Tags',
                icon: Icons.tag,
                value: '$tagCount',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfileStatCard(
          title: 'Productivity Score',
          icon: Icons.trending_up,
          value: '$score%',
          isPremium: true,
        ),
      ],
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        _buildTextField('Full Name', _nameController, Icons.person),
        const SizedBox(height: 16),
        _buildTextField('Username', _usernameController, Icons.alternate_email),
        const SizedBox(height: 16),
        _buildTextField('Bio', _bioController, Icons.info_outline, maxLines: 3),
      ],
    );
  }

  Widget _buildSettingsMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Security',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        ProfileMenuItem(
          title: 'App Lock',
          subtitle: 'Require password on launch',
          icon: Icons.security,
          trailing: Switch(
            value: _user.isAppLockEnabled,
            onChanged: _toggleAppLock,
            activeColor: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(height: 12),
        ProfileMenuItem(
          title: 'Change Password',
          icon: Icons.lock_reset,
          onTap: _changePasswordFlow,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF1A1A2E), // Input bg
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildActionButton(
    String label, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : const Color(0xFF6C63FF),
              width: 1.5,
            ),
          ),
          backgroundColor: isDestructive
              ? Colors.transparent
              : const Color(0xFF6C63FF).withOpacity(0.1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : const Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
