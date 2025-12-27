import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime dateTime;
  final String repeat; // e.g., "Daily", "Weekly", "None"
  final TimeOfDay time;
  final bool isActive;
  final String? userId; // For backend sync

  const Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    this.repeat = 'None',
    required this.time,
    this.isActive = true,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'repeat': repeat,
      'hour': time.hour,
      'minute': time.minute,
      'isActive': isActive,
      'userId': userId,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      dateTime: DateTime.parse(json['dateTime']),
      repeat: json['repeat'] ?? 'None',
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isActive: json['isActive'] ?? true,
      userId: json['userId'],
    );
  }
}
