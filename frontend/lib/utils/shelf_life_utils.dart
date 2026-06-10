/// 根据食材名称 / 分类估算大致的保质期（单位：天）。
/// 用于冰箱录入时给出一个比 99 天更贴近实际的默认值。
class ShelfLifeUtils {
  /// 关键词 -> 大致可冷藏 / 常温保存天数
  static const List<MapEntry<String, int>> _nameRules = [
    // 蔬菜：叶菜短，根茎稍长
    MapEntry('生菜', 3),
    MapEntry('菠菜', 3),
    MapEntry('芹菜', 5),
    MapEntry('白菜', 7),
    MapEntry('包菜', 7),
    MapEntry('青菜', 3),
    MapEntry('西红柿', 5),
    MapEntry('番茄', 5),
    MapEntry('黄瓜', 5),
    MapEntry('辣椒', 7),
    MapEntry('青椒', 7),
    MapEntry('茄子', 5),
    MapEntry('豆角', 4),
    MapEntry('豆芽', 2),
    MapEntry('蘑菇', 3),
    MapEntry('金针菇', 3),
    MapEntry('胡萝卜', 14),
    MapEntry('萝卜', 10),
    MapEntry('土豆', 21),
    MapEntry('洋葱', 30),
    MapEntry('大蒜', 60),
    MapEntry('姜', 21),

    // 水果
    MapEntry('草莓', 3),
    MapEntry('蓝莓', 5),
    MapEntry('葡萄', 7),
    MapEntry('香蕉', 5),
    MapEntry('苹果', 14),
    MapEntry('梨', 10),
    MapEntry('橙', 14),
    MapEntry('柠檬', 21),
    MapEntry('西瓜', 5),

    // 肉、蛋、海鲜（冷藏天数）
    MapEntry('鱼', 2),
    MapEntry('虾', 2),
    MapEntry('蟹', 2),
    MapEntry('海鲜', 2),
    MapEntry('牛肉', 4),
    MapEntry('猪肉', 3),
    MapEntry('鸡肉', 3),
    MapEntry('鸡胸', 3),
    MapEntry('鸡腿', 3),
    MapEntry('羊肉', 3),
    MapEntry('鸭', 3),
    MapEntry('培根', 14),
    MapEntry('火腿', 14),
    MapEntry('香肠', 21),
    MapEntry('鸡蛋', 21),
    MapEntry('蛋', 21),

    // 乳制品
    MapEntry('牛奶', 7),
    MapEntry('酸奶', 14),
    MapEntry('奶酪', 21),
    MapEntry('黄油', 30),

    // 主食 / 谷物
    MapEntry('米饭', 2),
    MapEntry('面包', 5),
    MapEntry('面条', 30),
    MapEntry('馒头', 3),
    MapEntry('饺子', 30),
    MapEntry('包子', 3),

    // 调味品
    MapEntry('酱油', 180),
    MapEntry('醋', 180),
    MapEntry('盐', 365),
    MapEntry('糖', 365),

    // 饮料
    MapEntry('饮料', 90),
    MapEntry('果汁', 14),
    MapEntry('啤酒', 90),
  ];

  /// 分类层面的兜底估算
  static const Map<String, int> _categoryDefaults = {
    '蔬菜': 5,
    'vegetable': 5,
    '水果': 7,
    'fruit': 7,
    '肉类': 3,
    'meat': 3,
    '海鲜': 2,
    'seafood': 2,
    '蛋类': 21,
    'egg': 21,
    '乳制品': 7,
    'dairy': 7,
    '谷物': 30,
    'grain': 30,
    '调味品': 180,
    'condiment': 180,
    '饮品': 30,
    '饮料': 30,
    '其他': 14,
    'other': 14,
  };

  /// 估算给定名称 / 分类下的大致保质天数。
  static int estimateDays({String? name, String? category}) {
    if (name != null && name.trim().isNotEmpty) {
      for (final entry in _nameRules) {
        if (name.contains(entry.key)) return entry.value;
      }
    }
    if (category != null && category.trim().isNotEmpty) {
      final hit = _categoryDefaults[category];
      if (hit != null) return hit;
      for (final e in _categoryDefaults.entries) {
        if (category.contains(e.key)) return e.value;
      }
    }
    return 14;
  }

  /// 估算后给出对应到期日期（仅日期，零点）。
  static DateTime estimateExpireDate({String? name, String? category, DateTime? from}) {
    final base = from ?? DateTime.now();
    final days = estimateDays(name: name, category: category);
    return DateTime(base.year, base.month, base.day).add(Duration(days: days));
  }
}
