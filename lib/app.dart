import 'package:flutter/material.dart';

import 'features/inventory/screens/inventory_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'shared/theme/app_theme.dart';

class RePlayApp extends StatefulWidget {
  const RePlayApp({super.key});

  @override
  State<RePlayApp> createState() => _RePlayAppState();
}

class _RePlayAppState extends State<RePlayApp> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    InventoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rePlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.toys_outlined),
              selectedIcon: Icon(Icons.toys),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}
