import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/screens/auth_screen.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/widgets/verification_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Mock Data for Customs
  final List<Color> _frameColors = [
    Colors.transparent, // None
    const Color(0xFF00E5FF), // Neon Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF00FF), // Cyberpunk
    const Color(0xFF6C63FF), // Purple
  ];

  final List<IconData> _avatars = [
    Icons.person,
    Icons.face,
    Icons.face_3,
    Icons.face_6,
    Icons.sentiment_satisfied_alt,
    Icons.smart_toy,
    Icons.rocket_launch,
    Icons.pets,
    Icons.music_note,
    Icons.sports_esports,
    Icons.code,
    Icons.diamond,
  ];

  @override
  void initState() {
    super.initState();
    _user = StorageService().getUserProfile();
    _nameController.text = _user.name;
    _usernameController.text = _user.username;
    _bioController.text = _user.bio;
  }

  void _saveProfile() {
    final updatedUser = _user.copyWith(
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
    );
    StorageService().saveUserProfile(updatedUser);
    setState(() {
      _user = updatedUser;
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final updatedUser = _user.copyWith(profileImagePath: image.path);
      StorageService().saveUserProfile(updatedUser);
      setState(() => _user = updatedUser);
    }
  }

  void _updateAvatar(int index) {
    if (!_isEditing) return;
    setState(() {
      _user = _user.copyWith(avatarIndex: index);
    });
  }

  void _updateFrame(int index) {
    if (!_isEditing) return;
    setState(() {
      _user = _user.copyWith(frameIndex: index);
    });
  }

  void _toggleAppLock(bool value) {
    if (value && (_user.password == null || _user.password!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set a password first by logging out/signup'),
        ),
      );
      return;
    }

    final updatedUser = _user.copyWith(isAppLockEnabled: value);
    StorageService().saveUserProfile(updatedUser);
    setState(() => _user = updatedUser);
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (_) => VerificationDialog(
        email: _user.email,
        onVerified: () {
          // Open Change Password Dialog (Simplified: Just asking for new pass)
          _showNewPasswordDialog();
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
        title: const Text(
          'New Password',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new password',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passController.text.length < 6) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Too short')));
                return;
              }
              final updatedUser = _user.copyWith(password: passController.text);
              StorageService().saveUserProfile(updatedUser);
              setState(() => _user = updatedUser);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password Changed!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    final guest = UserProfile.guest();
    StorageService().saveUserProfile(guest);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          if (!_user.isGuest)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
              ),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // --- Avatar Section (With Image Picker) ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_user.frameIndex > 0)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _frameColors[_user.frameIndex].withOpacity(
                              0.6,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A2E),
                        border: Border.all(
                          color:
                              _frameColors[_user.frameIndex] ==
                                  Colors.transparent
                              ? Colors.grey[800]!
                              : _frameColors[_user.frameIndex],
                          width: 3,
                        ),
                        image: _user.profileImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_user.profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _user.profileImagePath == null
                          ? Icon(
                              _avatars[_user.avatarIndex % _avatars.length],
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Info Section ---
            if (_user.isGuest)
              Column(
                children: [
                  const Text(
                    'Guest User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to sync your notes',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              )
            else ...[
              if (_isEditing) ...[
                _buildTextField('Full Name', _nameController, Icons.person),
                const SizedBox(height: 12),
                _buildTextField(
                  'Username',
                  _usernameController,
                  Icons.alternate_email,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Bio',
                  _bioController,
                  Icons.info_outline,
                  maxLines: 3,
                ),
              ] else ...[
                Text(
                  _user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_user.username.isNotEmpty)
                  Text(
                    '@${_user.username}',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 16,
                    ),
                  ),
                if (_user.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _user.bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
              ],
            ],

            const SizedBox(height: 32),

            // --- Privacy Settings ---
            if (!_user.isGuest && !_isEditing) ...[
              _buildSectionTitle('Privacy & Security'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'App Lock',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Require password on launch',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      value: _user.isAppLockEnabled,
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: _toggleAppLock,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    ListTile(
                      title: const Text(
                        'Change Password',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            if (!_user.isGuest && _isEditing) ...[
              _buildSectionTitle('Avatar & Frame'),
              const SizedBox(height: 16),

              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final isSelected = _user.avatarIndex == index;
                    return GestureDetector(
                      onTap: () => _updateAvatar(index),
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF).withOpacity(0.2)
                              : const Color(0xFF1A1A2E),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF6C63FF),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(_avatars[index], color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _frameColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final color = _frameColors[index];
                    final isSelected = _user.frameIndex == index;
                    return GestureDetector(
                      onTap: () => _updateFrame(index),
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
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
              const SizedBox(height: 32),
            ],

            // --- Stats Dashboard ---
            if (!_user.isGuest && !_isEditing) ...[
              _buildStatCard(
                'Total Notes',
                Icons.note,
                '12',
              ), // Mock data for now
              const SizedBox(height: 16),
              _buildStatCard('Tags Created', Icons.tag, '5'),
              const SizedBox(height: 16),
              _buildStatCard(
                'Productivity Score',
                Icons.trending_up,
                '85%',
                isPremium: true,
              ),
            ],

            const SizedBox(height: 40),

            // --- Auth Buttons ---
            if (_user.isGuest)
              _buildModernButton(
                'Sign In / Sign Up',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              )
            else if (!_isEditing)
              _buildModernButton('Log Out', isOutlined: true, onTap: _logout),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton(
    String text, {
    bool isOutlined = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? null : const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: Colors.redAccent) : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isOutlined ? Colors.redAccent : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    IconData icon,
    String value, {
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: isPremium
            ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.5))
            : null,
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPremium
                  ? const Color(0xFFFFD700).withOpacity(0.1)
                  : const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: isPremium
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
