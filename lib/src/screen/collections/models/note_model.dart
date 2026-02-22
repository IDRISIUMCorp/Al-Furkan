import "dart:convert";

class NoteModel {
  String id;
  List<String> ayahKey;
  String text;
  String? category;
  DateTime createdAt;
  DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.ayahKey,
    required this.text,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json["id"] as String,
      ayahKey: List<String>.from(json["ayahKey"] ?? []),
      text: json["text"] as String,
      category: json["category"] as String?,
      createdAt: DateTime.parse(json["createdAt"] as String),
      updatedAt: DateTime.parse(json["updatedAt"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "ayahKey": ayahKey,
      "text": text,
      "category": category,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => json.encode(toJson());

  factory NoteModel.fromJsonString(String jsonString) =>
      NoteModel.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  NoteModel copyWith({
    String? id,
    List<String>? ayahKey,
    String? text,
    String? category,
    List<String>? collectionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      ayahKey: ayahKey ?? this.ayahKey,
      text: text ?? this.text,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
