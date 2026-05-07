class FridgeItemModel {
  final int id;
  final String name;
  final String? category;
  final double quantity;
  final String? unit;
  final String? expireDate;

  FridgeItemModel({
    required this.id,
    required this.name,
    this.category,
    required this.quantity,
    this.unit,
    this.expireDate,
  });

  factory FridgeItemModel.fromJson(Map<String, dynamic> json) {
    return FridgeItemModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String?,
      expireDate: json['expire_date'] as String?,
    );
  }
}