import 'package:flutter/material.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/screens/home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorText = '';
  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    _user = StorageService().getUserProfile();
  }

  void _unlock() {
    if (_pinController.text == _user.appLockPin) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _errorText = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 32),
              const Text(
                'Notio Locked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to unlock',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _pinController,
                obscureText: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text, // Allow generic for now
                onSubmitted: (_) => _unlock(),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    letterSpacing: 8,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorText.isNotEmpty)
                Text(
                  _errorText,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _unlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
