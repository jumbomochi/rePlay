import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(icon: Icons.toys, title: 'Welcome to rePlay', subtitle: 'Organize your family\'s toy collection'),
    _OnboardingPage(icon: Icons.camera_alt, title: 'Capture', subtitle: 'Take a photo and let AI identify your toys'),
    _OnboardingPage(icon: Icons.filter_list, title: 'Organize', subtitle: 'Track status, condition, and location.\nExport lists when it\'s time to donate or sell.'),
  ];

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _pages.length - 1)
              Align(alignment: Alignment.topRight, child: TextButton(onPressed: _completeOnboarding, child: const Text('Skip')))
            else const SizedBox(height: 48),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(page.icon, size: 100, color: theme.colorScheme.primary),
                    const SizedBox(height: 32),
                    Text(page.title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(page.subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  ]));
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: _currentPage == i ? 24 : 8, height: 8, decoration: BoxDecoration(color: _currentPage == i ? theme.colorScheme.primary : theme.colorScheme.outline, borderRadius: BorderRadius.circular(4))))),
            const SizedBox(height: 24),
            if (_currentPage == _pages.length - 1)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: FilledButton(onPressed: _completeOnboarding, style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)), child: const Text('Get Started')))
            else const SizedBox(height: 48),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }
}

class _OnboardingPage {
  final IconData icon; final String title; final String subtitle;
  const _OnboardingPage({required this.icon, required this.title, required this.subtitle});
}
