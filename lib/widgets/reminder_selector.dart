import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notio/models/reminder.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReminderSelector extends StatefulWidget {
  final Function(Reminder) onReminderCreated;

  const ReminderSelector({super.key, required this.onReminderCreated});

  @override
  State<ReminderSelector> createState() => _ReminderSelectorState();
}

class _ReminderSelectorState extends State<ReminderSelector> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeat = 'None';
  final List<String> _repeatOptions = ['None', 'Daily', 'Weekly'];

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a reminder title'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
          ),
        ),
      );
      return;
    }

    final reminder = Reminder(
      id: const Uuid().v4(),
      title: _titleController.text,
      dateTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      repeat: _repeat,
      time: _selectedTime,
    );

    widget.onReminderCreated(reminder);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'New Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: const Color(0xFF6C63FF),
                  decoration: InputDecoration(
                    hintText: 'What is to be done?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.task_alt,
                        color: Colors.white.withOpacity(0.3)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: _buildPickerButton(
                      icon: Icons.calendar_today,
                      label:
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerButton(
                      icon: Icons.access_time,
                      label: _selectedTime.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Repeat Options
              const Text(
                'Repeat',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _repeatOptions.map((option) {
                  final isSelected = _repeat == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _repeat = option);
                    },
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: const Color(0xFF6C63FF).withOpacity(0.3),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? const Color(0xFF6C63FF) : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
                  ),
                  child: const Text(
                    'Set Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
