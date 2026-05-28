import 'package:flutter/material.dart';

import '../screens/toy_detail_screen.dart';

Route<void> toyDetailRoute(int toyId) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ToyDetailScreen(toyId: toyId),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
