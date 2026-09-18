class StageProgressModel {
  final String stageId;
  final String stageTitle;
  final String pathId;
  final String pathTitle;
  final bool isCompleted;
  final int xp;

  StageProgressModel({
    required this.stageId,
    required this.stageTitle,
    required this.pathId,
    required this.pathTitle,
    required this.isCompleted,
    required this.xp,
  });
}