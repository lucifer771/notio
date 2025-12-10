import 'package:flutter/material.dart';

enum NoteType { text, handwritten, image, audio }

@immutable
class Note {
  final String id;
  final String title;
  final String
  content; // Could be plain text, rich text JSON, or file path for handwritten/media
  final NoteType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? folderId; // Optional: for organizing notes into folders
  final Color? backgroundColor; // Optional: for note customization

  const Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.type = NoteType.text,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.folderId,
    this.backgroundColor,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? folderId,
    Color? backgroundColor,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  // Convert Note to JSON for storage (e.g., Hive, Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last, // Store enum as string
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'folderId': folderId,
      'backgroundColor': backgroundColor?.value, // Store color as int
    };
  }

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: NoteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NoteType.text,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: List<String>.from(json['tags'] as List),
      folderId: json['folderId'] as String?,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
    );
  }
}
