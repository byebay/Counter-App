import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String username;
  @HiveField(5)
  final String? authorId;
  @HiveField(6)
  final String? teamId;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.username,
    this.authorId,
    this.teamId,
  });

  ObjectId? get objectId => id != null ? ObjectId.parse(id!) : null;

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.parse(id!) : ObjectId(),
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'username': username,
      'authorId': authorId,
      'teamId': teamId,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] is ObjectId
          ? (map['_id'] as ObjectId).oid 
          : map['_id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null
          ? (map['date'] is String
              ? DateTime.parse(map['date'])
              : map['date'] as DateTime)
          : DateTime.now(),
      username: map['username'] ?? '',
      authorId: map['authorId'],
      teamId: map['teamId'],
    );
  }

  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? username,
    String? authorId,
    String? teamId,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      username: username ?? this.username,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
    );
  }
}