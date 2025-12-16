import 'package:flutter/material.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/screens/auth_screen.dart'; // Will create next

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _user;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();

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
  }

  void _saveProfile() {
    final updatedUser = _user.copyWith(name: _nameController.text);
    StorageService().saveUserProfile(updatedUser);
    setState(() {
      _user = updatedUser;
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
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

  void _logout() {
    // For now, just clear profile or set to guest
    // In a real app, clear tokens.
    // Here we will simulate logout by setting guest.
    final guest = UserProfile.guest();
    StorageService().saveUserProfile(guest);

    Navigator.pop(context); // Go back to Home
    // Ideally triggering a reload on Home, but Home reloads on explicit events usually.
    // We might need a global state or callback. For now, pop is okay.
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
          onPressed: () =>
              Navigator.pop(context, true), // Return true to signal update
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
            // --- Avatar Section ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Frame Glow
                  if (_user.frameIndex > 0)
                    Container(
                      width: 130,
                      height: 130,
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
                  // Avatar Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      border: Border.all(
                        color:
                            _frameColors[_user.frameIndex] == Colors.transparent
                            ? Colors.grey[800]!
                            : _frameColors[_user.frameIndex],
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _avatars[_user.avatarIndex % _avatars.length],
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Name Section ---
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
            else if (_isEditing)
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Text(
                _user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 40),

            // --- Customization (Avatar/Frame) ---
            if (_isEditing && !_user.isGuest) ...[
              _buildSectionTitle('Choose Avatar'),
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
              const SizedBox(height: 24),
              _buildSectionTitle('Choose Frame'),
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
              const SizedBox(height: 40),
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
            else
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
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.bold,
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
}
