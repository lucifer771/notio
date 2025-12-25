import 'package:flutter/material.dart';

class ProfileStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final bool isPremium;

  const ProfileStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.6), // Sheer Glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
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
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
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
