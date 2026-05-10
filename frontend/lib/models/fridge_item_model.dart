class FridgeItemModel {
  final int id;
  final int userId;
  final String name;
  final String? category;
  final double quantity;
  final String? unit;
  final double? weightG;
  final String? expireDate;
  final String? storageLocation;
  final String? remark;
  final String createdAt;

  FridgeItemModel({
    required this.id,
    required this.userId,
    required this.name,
    this.category,
    required this.quantity,
    this.unit,
    this.weightG,
    this.expireDate,
    this.storageLocation,
    this.remark,
    required this.createdAt,
  });

  factory FridgeItemModel.fromJson(Map<String, dynamic> json) {
    return FridgeItemModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String?,
      weightG: (json['weight_g'] as num?)?.toDouble(),
      expireDate: json['expire_date'] as String?,
      storageLocation: json['storage_location'] as String?,
      remark: json['remark'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (category != null) 'category': category,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (weightG != null) 'weight_g': weightG,
      if (expireDate != null) 'expire_date': expireDate,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (remark != null) 'remark': remark,
    };
  }

  /// 是否即将过期（7天内）
  bool get isExpiringSoon {
    if (expireDate == null) return false;
    final expire = DateTime.tryParse(expireDate!);
    if (expire == null) return false;
    return expire.difference(DateTime.now()).inDays <= 7;
  }
}