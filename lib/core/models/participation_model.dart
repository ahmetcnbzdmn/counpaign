class ParticipationModel {
  final String id;
  final String customerId;
  final String campaignId;
  final String status;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  ParticipationModel({
    required this.id,
    required this.customerId,
    required this.campaignId,
    required this.status,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  factory ParticipationModel.fromJson(Map<String, dynamic> json) {
    return ParticipationModel(
      id: json['_id'] ?? '',
      customerId: json['customer'] is Map ? json['customer']['_id'] : (json['customer'] ?? ''),
      campaignId: json['campaign'] is Map ? json['campaign']['_id'] : (json['campaign'] ?? ''),
      status: json['status'] ?? 'JOINED',
      currentProgress: json['currentProgress'] ?? 0,
      targetProgress: json['targetProgress'] ?? 1, // Default to 1 to avoid div by zero
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
