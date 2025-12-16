import 'package:flutter/material.dart';

class VerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const VerificationDialog({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  int _step = 0; // 0: Send Code, 1: Enter Code
  final TextEditingController _codeController = TextEditingController();
  bool _isSending = false;

  void _sendCode() async {
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API
    setState(() {
      _isSending = false;
      _step = 1;
    });
  }

  void _verifyCode() {
    if (_codeController.text == '1234') {
      // Mock Code
      Navigator.pop(context);
      widget.onVerified();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Code (Try 1234)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, color: Color(0xFF6C63FF), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Security Check',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? 'We need to verify it\'s you. Send a code to ${widget.email}'
                  : 'Enter the 4-digit code sent to your email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            if (_step == 1)
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0000',
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _step == 0 ? _sendCode : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _step == 0 ? 'Send Code' : 'Verify',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
