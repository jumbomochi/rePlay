import 'package:flutter/material.dart';

import 'features/inventory/screens/inventory_screen.dart';
import 'shared/theme/app_theme.dart';

class RePlayApp extends StatelessWidget {
  const RePlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rePlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const InventoryScreen(),
    );
  }
}
