class CampaignModel {
  final String id;
  final String businessId;
  final String title;
  final String shortDescription;
  final String? headerImage;
  final String content;
  final String rewardType;
  final int rewardValue;
  final int rewardValidityDays;
  final String icon;
  final bool isPromoted;
  final int displayOrder;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  CampaignModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.shortDescription,
    this.headerImage,
    required this.content,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardValidityDays,
    required this.icon,
    required this.isPromoted,
    required this.displayOrder,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['_id'] ?? '',
      businessId: json['businessId'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      headerImage: json['headerImage'],
      content: json['content'] ?? '',
      rewardType: json['rewardType'] ?? '',
      rewardValue: json['rewardValue'] ?? 0,
      rewardValidityDays: json['rewardValidityDays'] ?? 0,
      icon: json['icon'] ?? 'star_rounded',
      isPromoted: json['isPromoted'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessId': businessId,
      'title': title,
      'shortDescription': shortDescription,
      'headerImage': headerImage,
      'content': content,
      'rewardType': rewardType,
      'rewardValue': rewardValue,
      'rewardValidityDays': rewardValidityDays,
      'icon': icon,
      'isPromoted': isPromoted,
      'displayOrder': displayOrder,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
