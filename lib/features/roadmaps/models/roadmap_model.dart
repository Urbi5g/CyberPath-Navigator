import 'package:cloud_firestore/cloud_firestore.dart';

class RoadmapModel {
  final String id;
  final String title;
  final String description;
  final String level;
  final String interest;

  RoadmapModel({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.interest,
  });

  factory RoadmapModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RoadmapModel(
      id: id,
      title: data['title']?.toString().trim() ?? 'Untitled Learning Path',
      description: data['description']?.toString().trim() ?? 'No description available.',
      level: data['level']?.toString().trim() ?? '',
      interest: data['interest']?.toString().trim() ?? '',
    );
  }
}

class StageModel {
  final String id;
  final String title;
  final String description;
  final int? xp;
  final String duration;
  final String difficulty;

  StageModel({
    required this.id,
    required this.title,
    required this.description,
    this.xp,
    required this.duration,
    required this.difficulty,
  });

  factory StageModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return StageModel(
      id: doc.id,
      title: data['title']?.toString().trim() ?? 'Untitled Stage',
      description: data['description']?.toString().trim() ?? 'No description available.',
      xp: data['xp'] is num ? (data['xp'] as num).toInt() : null,
      duration: data['duration']?.toString().trim() ?? '',
      difficulty: data['difficulty']?.toString().trim() ?? '',
    );
  }
}