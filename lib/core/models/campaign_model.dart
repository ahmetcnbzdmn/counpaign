class CampaignMenuItem {
  final String productId;
  final String productName;
  final double price;

  CampaignMenuItem({
    required this.productId,
    required this.productName,
    required this.price,
  });

  factory CampaignMenuItem.fromJson(Map<String, dynamic> json) {
    return CampaignMenuItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
    };
  }
}

class CampaignModel {
  final String id;
  final String businessId;
  final String title;
  final String shortDescription;
  final String? headerImage;
  final String content;
  final String icon;
  final bool isPromoted;
  final int displayOrder;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final List<CampaignMenuItem> menuItems;
  final double discountAmount;
  final bool reflectToMenu;
  final String bundleName;

  CampaignModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.shortDescription,
    this.headerImage,
    required this.content,
    required this.icon,
    required this.isPromoted,
    required this.displayOrder,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.menuItems = const [],
    this.discountAmount = 0,
    this.reflectToMenu = false,
    this.bundleName = '',
  });

  double get totalPrice => menuItems.fold(0, (sum, item) => sum + item.price);
  double get discountedPrice => (totalPrice - discountAmount).clamp(0, double.infinity);

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['_id'] ?? '',
      businessId: json['businessId'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      headerImage: json['headerImage'],
      content: json['content'] ?? '',
      icon: json['icon'] ?? 'star_rounded',
      isPromoted: json['isPromoted'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      createdAt: DateTime.parse(json['createdAt']),
      menuItems: json['menuItems'] != null
          ? (json['menuItems'] as List).map((e) => CampaignMenuItem.fromJson(e)).toList()
          : [],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      reflectToMenu: json['reflectToMenu'] ?? false,
      bundleName: json['bundleName'] ?? '',
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
      'icon': icon,
      'isPromoted': isPromoted,
      'displayOrder': displayOrder,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'menuItems': menuItems.map((e) => e.toJson()).toList(),
      'discountAmount': discountAmount,
      'reflectToMenu': reflectToMenu,
      'bundleName': bundleName,
    };
  }
}
