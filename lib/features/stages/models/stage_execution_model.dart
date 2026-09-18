class StageExecutionModel {
  final String title;
  final String description;
  final int? order;
  final int? xp;
  final String duration;
  final int? estimatedMinutes;
  final String difficulty;
  final List<String> topics;
  final List<StageLinkModel> resources;
  final List<StageLinkModel> courses;
  final List<StageLinkModel> platforms;
  final List<StageLinkModel> additionalLinks;

  StageExecutionModel({
    required this.title,
    required this.description,
    this.order,
    this.xp,
    required this.duration,
    this.estimatedMinutes,
    required this.difficulty,
    required this.topics,
    required this.resources,
    required this.courses,
    required this.platforms,
    required this.additionalLinks,
  });

  factory StageExecutionModel.fromMap(Map<String, dynamic> data) {
    List<String> parseStringList(dynamic value) {
      if (value is! List) return [];
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    List<StageLinkModel> parseLinks(dynamic value) {
      if (value is! List) return [];
      return value.whereType<Map>().map((e) => StageLinkModel.fromMap(Map<String, dynamic>.from(e))).toList();
    }

    return StageExecutionModel(
      title: data['title']?.toString().trim() ?? 'Untitled Stage',
      description: data['description']?.toString().trim() ?? 'No description available.',
      order: data['order'] is num ? (data['order'] as num).toInt() : null,
      xp: data['xp'] is num ? (data['xp'] as num).toInt() : null,
      duration: data['duration']?.toString().trim() ?? '',
      estimatedMinutes: data['estimatedMinutes'] is num ? (data['estimatedMinutes'] as num).toInt() : null,
      difficulty: data['difficulty']?.toString().trim() ?? '',
      topics: parseStringList(data['topics']),
      resources: parseLinks(data['resources']),
      courses: parseLinks(data['courses']),
      platforms: parseLinks(data['platforms']),
      additionalLinks: parseLinks(data['additionalLinks']),
    );
  }
}

class StageLinkModel {
  final String title;
  final String url;
  final String platform;
  final String description;

  StageLinkModel({
    required this.title,
    required this.url,
    required this.platform,
    required this.description,
  });

  factory StageLinkModel.fromMap(Map<String, dynamic> data) {
    return StageLinkModel(
      title: data['title']?.toString().trim() ?? 'Untitled Resource',
      url: data['url']?.toString().trim() ?? '',
      platform: data['platform']?.toString().trim() ?? '',
      description: data['description']?.toString().trim() ?? '',
    );
  }
}