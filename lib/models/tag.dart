class Tag {
  final String id;
  final String name;
  final int noteCount;

  final int color; // Store color as int (ARGB) for easy serialization

  const Tag({
    required this.id,
    required this.name,
    required this.noteCount,
    this.color = 0xFF6C63FF, // Default Indigo
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'noteCount': noteCount, 'color': color};
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      noteCount: json['noteCount'] ?? 0,
      color: json['color'] ?? 0xFF6C63FF,
    );
  }
}
