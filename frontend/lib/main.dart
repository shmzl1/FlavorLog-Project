import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const FlavorLogApp());
}

class FlavorLogApp extends StatelessWidget {
  const FlavorLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '知味志 FlavorLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.authGate,
      getPages: AppRoutes.pages,
    );
  }
}
