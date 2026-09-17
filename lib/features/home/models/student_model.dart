import 'package:flutter/material.dart';

class StudentModel {
  final String name;
  final String level;
  final String interest;
  final int? points;
  final int? badges;
  final int? certificates;
  final int completedStages;
  final List<ActivePathway> activePathways;
  final List<ActivityItem> recentActivities;

  StudentModel({
    required this.name,
    required this.level,
    required this.interest,
    required this.points,
    required this.badges,
    required this.certificates,
    required this.completedStages,
    required this.activePathways,
    required this.recentActivities,
  });
}

class ActivePathway {
  final String title;
  final String currentStage;
  final double progressPercent;

  ActivePathway({
    required this.title,
    required this.currentStage,
    required this.progressPercent,
  });
}

class ActivityItem {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}