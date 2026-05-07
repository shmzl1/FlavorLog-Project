import 'package:flutter/material.dart';

import '../../components/placeholder_page.dart';

class FoodRecordPage extends StatelessWidget {
  const FoodRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '饮食记录',
      description: '这里由刘子恒负责：饮食记录新增、查询、图片/视频/音频上传、识别结果确认。',
    );
  }
}