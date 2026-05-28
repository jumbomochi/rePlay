import 'package:flutter/material.dart';

import '../screens/toy_detail_screen.dart';

Route<void> toyDetailRoute(int toyId) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => ToyDetailScreen(toyId: toyId),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
