import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env').catchError((_) {});
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      child: onboardingComplete
          ? const RePlayApp()
          : _OnboardingWrapper(),
    ),
  );
}

class _OnboardingWrapper extends StatefulWidget {
  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  bool _showApp = false;

  @override
  Widget build(BuildContext context) {
    if (_showApp) return const RePlayApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(
        onComplete: () => setState(() => _showApp = true),
      ),
    );
  }
}
