import 'package:flutter/material.dart';
import 'package:notio/services/api_service.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showOtpInput = false;
  bool _isPasswordVisible = false;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  final _apiService = ApiService();

  // Password Strength State
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacters = false;
  bool _hasMinLength = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacters = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );
      _hasMinLength = password.length >= 8;
    });
  }

  bool get _isPasswordValid =>
      _hasUpperCase &&
      _hasLowerCase &&
      _hasDigits &&
      _hasSpecialCharacters &&
      _hasMinLength;

  Future<void> _handleAuth() async {
    if (!_isLogin) {
      if (!_isPasswordValid) {
        _showError('Password does not meet security requirements.');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match.');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // LOGIN FLOW
        final response = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );
        await _finalizeAuth(response);
      } else {
        // REGISTER FLOW
        if (_showOtpInput) {
          // VERIFY OTP
          final response = await _apiService.verifyOtp(
            _emailController.text,
            _otpController.text,
          );
          await _finalizeAuth(response);
        } else {
          // SEND OTP
          final response = await _apiService.register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
          if (mounted) {
            setState(() {
              _showOtpInput = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ OTP sent to ${response['email']}'),
                backgroundColor: const Color(0xFF6C63FF),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _finalizeAuth(Map<String, dynamic> response) async {
    final token = response['token'];
    final userData = response['user'];

    _apiService.setToken(token);
    final user = UserProfile.fromJson(userData);
    await StorageService().saveUserProfile(user);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (_showOtpInput) {
              setState(() => _showOtpInput = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                _isLogin
                    ? 'Welcome Back!'
                    : (_showOtpInput ? 'Verfication' : 'Create Account'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Sign in to sync your notes'
                    : (_showOtpInput
                          ? 'Enter the 6-digit code sent to ${_emailController.text}'
                          : 'Sign up to get started'),
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Fields
              if (!_isLogin && !_showOtpInput) ...[
                _buildTextField('Full Name', _nameController, Icons.person),
                const SizedBox(height: 16),
              ],

              if (!_showOtpInput) ...[
                _buildTextField(
                  'Email',
                  _emailController,
                  Icons.email,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Password',
                  _passwordController,
                  Icons.lock_outline,
                  isPassword: true,
                ),
              ],

              if (!_isLogin && !_showOtpInput) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  'Confirm Password',
                  _confirmPasswordController,
                  Icons.lock_reset,
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                _buildPasswordStrength(),
              ],

              if (_showOtpInput) ...[
                _buildTextField(
                  'OTP Code',
                  _otpController,
                  Icons.lock_clock,
                  inputType: TextInputType.number,
                  isCentered: true,
                ),
              ],

              const SizedBox(height: 32),

              // Action Button
              _buildActionButton(),

              const SizedBox(height: 30),

              // Toggle Auth Mode
              if (!_showOtpInput)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _showOtpInput = false;
                        });
                        // Clear fields when switching
                        if (!_isLogin) {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        }
                      },
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
    bool isCentered = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: inputType,
        textAlign: isCentered ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: isCentered
              ? null
              : Icon(icon, color: const Color(0xFF6C63FF)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStrengthIndicator("Min 8 Chars", _hasMinLength),
            _buildStrengthIndicator("Large Letter", _hasUpperCase),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStrengthIndicator("Number", _hasDigits),
            _buildStrengthIndicator("Symbol", _hasSpecialCharacters),
          ],
        ),
      ],
    );
  }

  Widget _buildStrengthIndicator(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.greenAccent : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.greenAccent : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isLogin
                    ? 'Sign In to Notio'
                    : (_showOtpInput ? 'Verify Code' : 'Create Account'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
