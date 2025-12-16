import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime dateTime;
  final String repeat; // e.g., "Daily", "Weekly", "None"
  final TimeOfDay time;

  const Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.repeat,
    required this.time,
  });
}
